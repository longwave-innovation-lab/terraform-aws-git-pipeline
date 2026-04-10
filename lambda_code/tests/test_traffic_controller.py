"""
Unit tests for lambda_code/traffic_controller.py

No external dependencies required to run tests.
Run from the repo root:
    python -m unittest discover -s lambda_code/tests -p "test_*.py" -v
"""
from __future__ import annotations

import os
import sys
import unittest
from unittest.mock import MagicMock, patch

# ---------------------------------------------------------------------------
# Stub out boto3/botocore so the test file is importable even when those
# packages are not installed in the active Python environment.
# We define a real exception class for ClientError so it can be raised /
# caught correctly throughout the tests.
# ---------------------------------------------------------------------------

class ClientError(Exception):
    """Stand-in for botocore.exceptions.ClientError."""
    def __init__(self, error_response: dict, operation_name: str) -> None:
        super().__init__(str(error_response))
        self.response = error_response
        self.operation_name = operation_name


_botocore_exceptions_stub = MagicMock()
_botocore_exceptions_stub.ClientError = ClientError

sys.modules.setdefault("boto3", MagicMock())
sys.modules.setdefault("botocore", MagicMock())
sys.modules.setdefault("botocore.exceptions", _botocore_exceptions_stub)

# Now import the module under test (boto3/botocore stubs are already in place).
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import traffic_controller  # noqa: E402

# ---------------------------------------------------------------------------
# Shared test fixtures
# ---------------------------------------------------------------------------
ZERO_SHA = "0" * 40
BEFORE_SHA = "a" * 40
AFTER_SHA = "b" * 40
REPO = "my-test-repo"
PIPELINE = "my-test-pipeline"


def _diff(*, after: str | None = None, before: str | None = None) -> dict:
    """Build a minimal CodeCommit difference entry."""
    entry: dict = {}
    if after:
        entry["afterBlob"] = {"path": after, "blobId": "111"}
    if before:
        entry["beforeBlob"] = {"path": before, "blobId": "222"}
    return entry


# ---------------------------------------------------------------------------
# _get_changed_paths
# ---------------------------------------------------------------------------
class TestGetChangedPaths(unittest.TestCase):
    def setUp(self) -> None:
        self.mock_cc = MagicMock()
        patch.object(traffic_controller, "_codecommit", self.mock_cc).start()
        self.addCleanup(patch.stopall)

    def test_normal_commit_returns_paths(self) -> None:
        self.mock_cc.get_differences.return_value = {
            "differences": [_diff(after="services/api/main.py")]
        }
        result = traffic_controller._get_changed_paths(REPO, BEFORE_SHA, AFTER_SHA)
        self.assertEqual(result, ["services/api/main.py"])
        self.mock_cc.get_differences.assert_called_once_with(
            repositoryName=REPO,
            afterCommitSpecifier=AFTER_SHA,
            beforeCommitSpecifier=BEFORE_SHA,
        )

    def test_initial_commit_omits_before_specifier(self) -> None:
        self.mock_cc.get_differences.return_value = {"differences": []}
        traffic_controller._get_changed_paths(REPO, ZERO_SHA, AFTER_SHA)
        call_kwargs = self.mock_cc.get_differences.call_args.kwargs
        self.assertNotIn("beforeCommitSpecifier", call_kwargs)

    def test_empty_before_ref_omits_before_specifier(self) -> None:
        self.mock_cc.get_differences.return_value = {"differences": []}
        traffic_controller._get_changed_paths(REPO, "", AFTER_SHA)
        call_kwargs = self.mock_cc.get_differences.call_args.kwargs
        self.assertNotIn("beforeCommitSpecifier", call_kwargs)

    def test_pagination_collects_all_paths(self) -> None:
        self.mock_cc.get_differences.side_effect = [
            {"differences": [_diff(after="a.py")], "NextToken": "tok1"},
            {"differences": [_diff(after="b.py")]},
        ]
        result = traffic_controller._get_changed_paths(REPO, BEFORE_SHA, AFTER_SHA)
        self.assertEqual(result, ["a.py", "b.py"])
        self.assertEqual(self.mock_cc.get_differences.call_count, 2)
        # Second call must forward the NextToken
        second_kwargs = self.mock_cc.get_differences.call_args_list[1].kwargs
        self.assertEqual(second_kwargs["NextToken"], "tok1")

    def test_deduplicates_paths_appearing_in_both_blobs(self) -> None:
        # A modified file appears in both afterBlob and beforeBlob.
        self.mock_cc.get_differences.return_value = {
            "differences": [_diff(after="app.py", before="app.py")]
        }
        result = traffic_controller._get_changed_paths(REPO, BEFORE_SHA, AFTER_SHA)
        self.assertEqual(result, ["app.py"])

    def test_collects_deleted_file_from_before_blob(self) -> None:
        # Deleted file only has beforeBlob.
        self.mock_cc.get_differences.return_value = {
            "differences": [_diff(before="deleted.py")]
        }
        result = traffic_controller._get_changed_paths(REPO, BEFORE_SHA, AFTER_SHA)
        self.assertEqual(result, ["deleted.py"])

    def test_client_error_propagates(self) -> None:
        self.mock_cc.get_differences.side_effect = ClientError(
            {"Error": {"Code": "RepositoryDoesNotExistException", "Message": "Nope"}},
            "GetDifferences",
        )
        with self.assertRaises(ClientError):
            traffic_controller._get_changed_paths(REPO, BEFORE_SHA, AFTER_SHA)


# ---------------------------------------------------------------------------
# _matches_any_filter
# ---------------------------------------------------------------------------
class TestMatchesAnyFilter(unittest.TestCase):
    def _check(self, filters: list[str], path: str) -> bool:
        with patch.object(traffic_controller, "_FILE_PATH_FILTERS", filters):
            return traffic_controller._matches_any_filter(path)

    # --- single-segment wildcard (*) ---
    def test_dir_wildcard_matches_direct_child(self) -> None:
        self.assertTrue(self._check(["services/api/*"], "services/api/main.py"))

    def test_dir_wildcard_does_not_cross_segments(self) -> None:
        # '*' must not match a '/' – so a file nested deeper should NOT match.
        self.assertFalse(self._check(["services/api/*"], "services/api/sub/main.py"))

    def test_dir_wildcard_does_not_match_wrong_dir(self) -> None:
        self.assertFalse(self._check(["services/api/*"], "services/other/main.py"))

    # --- globstar (**) ---
    def test_globstar_extension_matches_any_depth(self) -> None:
        self.assertTrue(self._check(["**/*.js"], "src/components/Button/index.js"))

    def test_globstar_extension_matches_root_level(self) -> None:
        self.assertTrue(self._check(["**/*.js"], "index.js"))

    def test_globstar_extension_does_not_match_wrong_ext(self) -> None:
        self.assertFalse(self._check(["**/*.js"], "src/index.ts"))

    def test_globstar_dir_matches_nested_file(self) -> None:
        self.assertTrue(self._check(["infra/**"], "infra/modules/vpc/main.tf"))

    def test_globstar_dir_does_not_match_sibling_dir(self) -> None:
        self.assertFalse(self._check(["infra/**"], "src/main.tf"))

    # --- question mark (?) ---
    def test_question_mark_matches_single_char(self) -> None:
        self.assertTrue(self._check(["src/v?/main.py"], "src/v2/main.py"))

    def test_question_mark_does_not_match_multiple_chars(self) -> None:
        self.assertFalse(self._check(["src/v?/main.py"], "src/v10/main.py"))

    # --- multiple filters ---
    def test_first_filter_matches(self) -> None:
        self.assertTrue(self._check(["**/*.tf", "services/api/*"], "modules/vpc/main.tf"))

    def test_second_filter_matches(self) -> None:
        self.assertTrue(self._check(["**/*.tf", "services/api/*"], "services/api/handler.py"))

    def test_no_filter_matches(self) -> None:
        self.assertFalse(self._check(["**/*.tf", "services/api/*"], "README.md"))


# ---------------------------------------------------------------------------
# _should_trigger
# ---------------------------------------------------------------------------
class TestShouldTrigger(unittest.TestCase):
    def setUp(self) -> None:
        self.addCleanup(patch.stopall)

    def test_wildcard_only_triggers_on_empty_paths(self) -> None:
        with patch.object(traffic_controller, "_WILDCARD_ONLY", True):
            self.assertTrue(traffic_controller._should_trigger([]))

    def test_wildcard_only_triggers_regardless_of_paths(self) -> None:
        with patch.object(traffic_controller, "_WILDCARD_ONLY", True):
            self.assertTrue(traffic_controller._should_trigger(["anything/at/all"]))

    def test_matching_path_triggers(self) -> None:
        with (
            patch.object(traffic_controller, "_WILDCARD_ONLY", False),
            patch.object(traffic_controller, "_FILE_PATH_FILTERS", ["services/api/*"]),
        ):
            self.assertTrue(traffic_controller._should_trigger(["services/api/main.py"]))

    def test_non_matching_path_does_not_trigger(self) -> None:
        with (
            patch.object(traffic_controller, "_WILDCARD_ONLY", False),
            patch.object(traffic_controller, "_FILE_PATH_FILTERS", ["services/api/*"]),
        ):
            self.assertFalse(traffic_controller._should_trigger(["services/other/main.py"]))

    def test_empty_changed_paths_does_not_trigger(self) -> None:
        with (
            patch.object(traffic_controller, "_WILDCARD_ONLY", False),
            patch.object(traffic_controller, "_FILE_PATH_FILTERS", ["services/api/*"]),
        ):
            self.assertFalse(traffic_controller._should_trigger([]))

    def test_one_matching_path_among_many_triggers(self) -> None:
        with (
            patch.object(traffic_controller, "_WILDCARD_ONLY", False),
            patch.object(traffic_controller, "_FILE_PATH_FILTERS", ["services/api/*"]),
        ):
            self.assertTrue(traffic_controller._should_trigger([
                "services/other/utils.py",
                "services/api/handler.py",   # ← this one matches
                "README.md",
            ]))


# ---------------------------------------------------------------------------
# _start_pipeline
# ---------------------------------------------------------------------------
class TestStartPipeline(unittest.TestCase):
    def setUp(self) -> None:
        self.mock_cp = MagicMock()
        patch.object(traffic_controller, "_codepipeline", self.mock_cp).start()
        patch.object(traffic_controller, "_DEFAULT_PIPELINE", PIPELINE).start()
        self.addCleanup(patch.stopall)

    def test_success_returns_execution_id(self) -> None:
        self.mock_cp.start_pipeline_execution.return_value = {
            "pipelineExecutionId": "exec-123"
        }
        result = traffic_controller._start_pipeline()
        self.assertEqual(result, "exec-123")
        self.mock_cp.start_pipeline_execution.assert_called_once_with(name=PIPELINE)

    def test_client_error_reraises(self) -> None:
        self.mock_cp.start_pipeline_execution.side_effect = ClientError(
            {"Error": {"Code": "PipelineNotFoundException", "Message": "Nope"}},
            "StartPipelineExecution",
        )
        with self.assertRaises(ClientError):
            traffic_controller._start_pipeline()


# ---------------------------------------------------------------------------
# lambda_handler  (integration)
# ---------------------------------------------------------------------------
class TestLambdaHandler(unittest.TestCase):
    def _event(
        self,
        repo: str = REPO,
        commit: str = AFTER_SHA,
        old_commit: str = BEFORE_SHA,
    ) -> dict:
        return {
            "detail": {
                "repositoryName": repo,
                "commitId": commit,
                "oldCommitId": old_commit,
            }
        }

    def setUp(self) -> None:
        self.mock_cc = MagicMock()
        self.mock_cp = MagicMock()
        patch.object(traffic_controller, "_codecommit", self.mock_cc).start()
        patch.object(traffic_controller, "_codepipeline", self.mock_cp).start()
        patch.object(traffic_controller, "_DEFAULT_PIPELINE", PIPELINE).start()
        patch.object(traffic_controller, "_FILE_PATH_FILTERS", ["services/api/*"]).start()
        patch.object(traffic_controller, "_WILDCARD_ONLY", False).start()
        self.addCleanup(patch.stopall)

    # --- input validation ---
    def test_missing_repo_name_returns_400(self) -> None:
        result = traffic_controller.lambda_handler(self._event(repo=""), None)
        self.assertEqual(result["statusCode"], 400)
        self.assertFalse(result["triggered"])
        self.mock_cc.get_differences.assert_not_called()

    def test_missing_commit_id_returns_400(self) -> None:
        result = traffic_controller.lambda_handler(self._event(commit=""), None)
        self.assertEqual(result["statusCode"], 400)
        self.assertFalse(result["triggered"])
        self.mock_cc.get_differences.assert_not_called()

    # --- no match ---
    def test_no_filter_match_does_not_trigger(self) -> None:
        self.mock_cc.get_differences.return_value = {
            "differences": [_diff(after="README.md")]
        }
        result = traffic_controller.lambda_handler(self._event(), None)
        self.assertEqual(result["statusCode"], 200)
        self.assertFalse(result["triggered"])
        self.mock_cp.start_pipeline_execution.assert_not_called()

    # --- match ---
    def test_filter_match_triggers_pipeline_and_returns_execution_id(self) -> None:
        self.mock_cc.get_differences.return_value = {
            "differences": [_diff(after="services/api/handler.py")]
        }
        self.mock_cp.start_pipeline_execution.return_value = {
            "pipelineExecutionId": "exec-456"
        }
        result = traffic_controller.lambda_handler(self._event(), None)
        self.assertEqual(result["statusCode"], 200)
        self.assertTrue(result["triggered"])
        self.assertEqual(result["executionId"], "exec-456")
        self.mock_cp.start_pipeline_execution.assert_called_once_with(name=PIPELINE)

    # --- wildcard sentinel ---
    def test_wildcard_only_triggers_without_inspecting_paths(self) -> None:
        with patch.object(traffic_controller, "_WILDCARD_ONLY", True):
            self.mock_cc.get_differences.return_value = {"differences": []}
            self.mock_cp.start_pipeline_execution.return_value = {
                "pipelineExecutionId": "exec-789"
            }
            result = traffic_controller.lambda_handler(self._event(), None)
        self.assertTrue(result["triggered"])
        self.mock_cp.start_pipeline_execution.assert_called_once_with(name=PIPELINE)

    # --- initial commit (no oldCommitId in event) ---
    def test_initial_commit_missing_old_commit_id(self) -> None:
        event = {"detail": {"repositoryName": REPO, "commitId": AFTER_SHA}}
        self.mock_cc.get_differences.return_value = {
            "differences": [_diff(after="services/api/index.py")]
        }
        self.mock_cp.start_pipeline_execution.return_value = {
            "pipelineExecutionId": "exec-101"
        }
        result = traffic_controller.lambda_handler(event, None)
        self.assertEqual(result["statusCode"], 200)
        self.assertTrue(result["triggered"])
        # Empty string before_commit → no beforeCommitSpecifier sent
        cc_kwargs = self.mock_cc.get_differences.call_args.kwargs
        self.assertNotIn("beforeCommitSpecifier", cc_kwargs)

    # --- error propagation ---
    def test_get_differences_error_propagates(self) -> None:
        self.mock_cc.get_differences.side_effect = ClientError(
            {"Error": {"Code": "RepositoryDoesNotExistException", "Message": "Nope"}},
            "GetDifferences",
        )
        with self.assertRaises(ClientError):
            traffic_controller.lambda_handler(self._event(), None)

    def test_start_pipeline_error_propagates(self) -> None:
        self.mock_cc.get_differences.return_value = {
            "differences": [_diff(after="services/api/handler.py")]
        }
        self.mock_cp.start_pipeline_execution.side_effect = ClientError(
            {"Error": {"Code": "PipelineNotFoundException", "Message": "Nope"}},
            "StartPipelineExecution",
        )
        with self.assertRaises(ClientError):
            traffic_controller.lambda_handler(self._event(), None)


if __name__ == "__main__":
    unittest.main(verbosity=2)

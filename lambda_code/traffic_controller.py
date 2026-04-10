"""
Monorepo Lambda Traffic Controller
===================================
Triggered by EventBridge on every CodeCommit push to the watched branch.

Compares file paths changed in the commit against FILE_PATH_FILTERS.
If any changed file matches a filter prefix, triggers DEFAULT_PIPELINE_NAME.
If FILE_PATH_FILTERS == ["*"] it triggers on every push (should not happen
because the Terraform toggle avoids creating this Lambda in that case).

Environment variables
---------------------
FILE_PATH_FILTERS     JSON array   [ "services/api/", ... ]
DEFAULT_PIPELINE_NAME string       name of the pipeline owned by this module
LOG_LEVEL             string       Python log-level (default INFO)
"""

from __future__ import annotations

import json
import logging
import os
from typing import Any

import boto3
from botocore.exceptions import ClientError

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

# ---------------------------------------------------------------------------
# AWS clients – initialised at module level for connection reuse across
# invocations in the same execution environment.
# ---------------------------------------------------------------------------
_codecommit = boto3.client("codecommit")
_codepipeline = boto3.client("codepipeline")

# ---------------------------------------------------------------------------
# Configuration (parsed once per cold start)
# ---------------------------------------------------------------------------
_FILE_PATH_FILTERS: list[str] = json.loads(os.getenv("FILE_PATH_FILTERS", '["*"]'))
_DEFAULT_PIPELINE: str = os.getenv("DEFAULT_PIPELINE_NAME", "")

# Sentinel: treat ["*"] as "match everything"
_WILDCARD_ONLY = _FILE_PATH_FILTERS == ["*"]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _get_changed_paths(repo: str, before_ref: str, after_ref: str) -> list[str]:
    """
    Return the list of all file paths touched by the commit.

    Handles:
    - Initial commits where beforeCommitSpecifier is the zero SHA.
    - Paginated responses from get_differences.
    """
    ZERO_SHA = "0" * 40
    kwargs: dict[str, Any] = {
        "repositoryName": repo,
        "afterCommitSpecifier": after_ref,
    }
    if before_ref and before_ref != ZERO_SHA:
        kwargs["beforeCommitSpecifier"] = before_ref

    paths: list[str] = []
    try:
        while True:
            response = _codecommit.get_differences(**kwargs)
            for diff in response.get("differences", []):
                # A file may appear in 'before', 'after', or both.
                for blob_key in ("afterBlob", "beforeBlob"):
                    blob = diff.get(blob_key)
                    if blob and blob.get("path"):
                        paths.append(blob["path"])
            next_token = response.get("NextToken")
            if not next_token:
                break
            kwargs["NextToken"] = next_token
    except ClientError as exc:
        logger.error(f"codecommit.get_differences failed: {exc}")
        raise

    # Deduplicate (a path can appear in both before/after on rename/edit)
    return list(dict.fromkeys(paths))


def _matches_any_filter(path: str) -> bool:
    """Return True when *path* starts with any configured filter prefix."""
    for f in _FILE_PATH_FILTERS:
        if f == "*" or path.startswith(f):
            return True
    return False


def _should_trigger(changed_paths: list[str]) -> bool:
    """Decide whether the pipeline should be started."""
    if _WILDCARD_ONLY:
        return True
    return any(_matches_any_filter(p) for p in changed_paths)


def _start_pipeline() -> str | None:
    """Trigger the pipeline and return the execution ID, or None on error."""
    try:
        resp = _codepipeline.start_pipeline_execution(name=_DEFAULT_PIPELINE)
        execution_id = resp.get("pipelineExecutionId")
        logger.info(f"Started pipeline '{_DEFAULT_PIPELINE}' – executionId={execution_id}")
        return execution_id
    except ClientError as exc:
        logger.error(f"Failed to start pipeline '{_DEFAULT_PIPELINE}': {exc}")
        raise


# ---------------------------------------------------------------------------
# Handler
# ---------------------------------------------------------------------------


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:  # noqa: ANN401
    """
    Entry point invoked by EventBridge on CodeCommit Repository State Change.

    Expected event shape (subset):
    {
      "detail": {
        "repositoryName": "my-repo",
        "commitId": "<after-sha>",
        "oldCommitId": "<before-sha>"   # absent on initial push
      }
    }
    """
    logger.debug(f"Received event: {json.dumps(event)}")

    detail = event.get("detail", {})
    repo_name: str = detail.get("repositoryName", "")
    after_commit: str = detail.get("commitId", "")
    before_commit: str = detail.get("oldCommitId", "")

    if not repo_name or not after_commit:
        logger.error(f"Missing required event fields. repositoryName={repo_name!r}, commitId={after_commit!r}")
        return {"statusCode": 400, "triggered": False}

    logger.info(f"Processing commit '{after_commit}' (before='{before_commit}') on repo '{repo_name}'")

    changed_paths = _get_changed_paths(repo_name, before_commit, after_commit)
    logger.info(f"Changed paths ({len(changed_paths)}): {changed_paths}")

    if not _should_trigger(changed_paths):
        logger.info(f"No filter matched for {changed_paths} – skipping pipeline trigger.")
        return {"statusCode": 200, "triggered": False}

    execution_id = _start_pipeline()
    return {"statusCode": 200, "triggered": True, "executionId": execution_id}

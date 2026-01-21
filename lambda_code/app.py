import json
import logging
import os
from typing import Dict, List, Optional, Any
import boto3
from botocore.exceptions import ClientError, BotoCoreError

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.getenv('LOG_LEVEL', 'INFO'))

# Initialize AWS clients outside handler for connection reuse
sns_client = boto3.client('sns')
codebuild_client = boto3.client('codebuild')

# Constants
class EnvVars:
    REPO_NAME = "REPO_NAME"
    IMAGE_TAG = "IMAGE_TAG"
    BRANCH_NAME = "BRANCH_NAME"
    CUSTOM_REGISTRY_NAME = "CUSTOM_REGISTRY_NAME"
    SNS_TOPIC_ARN = "SNS_TOPIC_ARN"
    EXPORTED_ENV_VARS = "exportedEnvironmentVariables"

class EventKeys:
    DETAIL = "detail"
    BUILD_ID = "build-id"
    BUILD_STATUS = "build-status"
    ADDITIONAL_INFO = "additional-information"
    PROJECT_NAME = "project-name"
    BUILD_START_TIME = "build-start-time"
    ENVIRONMENT = "environment"
    ENV_VARIABLES = "environment-variables"
    LOGS = "logs"
    LOGS_LINK = "logs-link"
    DEEP_LINK = "deep-link"
    PHASES = "phases"
    PHASE_TYPE = "phase-type"
    PHASE_CONTEXT = "phase-context"
    PHASE_STATUS = "phase-status"
    BUILD_NUMBER = "build-number"

class CustomError(Exception):
    """Custom exception for Lambda-specific errors"""
    pass

def get_nested_value(data: Dict[str, Any], keys: List[str], default: Any = None) -> Any:
    """Safely extract nested dictionary values"""
    for key in keys:
        if isinstance(data, dict):
            data = data.get(key, default)
        else:
            return default
    return data

def extract_env_variables(env_vars: Optional[List[Dict[str, str]]]) -> Dict[str, Optional[str]]:
    """Extract required environment variables from CodeBuild event"""
    if not env_vars:
        return {"repo_name": None, "branch_name": None, "custom_registry_name": None}

    result = {"repo_name": None, "branch_name": None, "custom_registry_name": None}

    for env_var in env_vars:
        name = env_var.get("name", "").upper()
        value = env_var.get("value")

        if name == EnvVars.REPO_NAME:
            result["repo_name"] = value
        elif name == EnvVars.BRANCH_NAME:
            result["branch_name"] = value
        elif name == EnvVars.CUSTOM_REGISTRY_NAME:
            result["custom_registry_name"] = value

    return result

def get_build_details(build_id: str) -> Dict[str, Any]:
    """Fetch detailed build information from CodeBuild"""
    try:
        response = codebuild_client.batch_get_builds(ids=[build_id])
        builds = response.get("builds", [])

        if not builds:
            raise CustomError(f"No build found for ID: {build_id}")

        logger.debug(f"Build details retrieved for {build_id}")
        return builds[0]

    except (ClientError, BotoCoreError) as e:
        logger.error(f"Failed to get build details for {build_id}: {e}")
        raise CustomError(f"Failed to retrieve build details: {e}")

def extract_failed_phases(phases: Optional[List[Dict[str, Any]]]) -> List[Dict[str, Any]]:
    """Extract failed phases from build phases"""
    if not phases:
        return []

    failed_phases = []
    for phase in phases:
        if phase.get(EventKeys.PHASE_STATUS) == "FAILED":
            failed_phases.append(phase)

    return failed_phases

def build_message_content(event_data: Dict[str, Any], build_details: Dict[str, Any]) -> Dict[str, Any]:
    """Build the notification message content"""
    # Extract basic information
    build_status = get_nested_value(event_data, [EventKeys.DETAIL, EventKeys.BUILD_STATUS])
    project_name = get_nested_value(event_data, [EventKeys.DETAIL, EventKeys.PROJECT_NAME])
    build_start_time = get_nested_value(event_data, [EventKeys.DETAIL, EventKeys.ADDITIONAL_INFO, EventKeys.BUILD_START_TIME])
    logs_link = get_nested_value(event_data, [EventKeys.DETAIL, EventKeys.ADDITIONAL_INFO, EventKeys.LOGS, EventKeys.DEEP_LINK])
    build_number = get_nested_value(event_data, [EventKeys.DETAIL, EventKeys.ADDITIONAL_INFO, EventKeys.BUILD_NUMBER])

    # Extract environment variables
    env_vars = get_nested_value(event_data, [EventKeys.DETAIL, EventKeys.ADDITIONAL_INFO, EventKeys.ENVIRONMENT, EventKeys.ENV_VARIABLES])
    env_data = extract_env_variables(env_vars)

    if not env_data["repo_name"]:
        raise CustomError("Repository name not found in CodeBuild environment variables")

    # Build subject line
    repo_identifier = f"{env_data['repo_name']}:{env_data['branch_name']}"
    if env_data["custom_registry_name"]:
        repo_identifier = f"{env_data['repo_name']}:{env_data['branch_name']} - {env_data['custom_registry_name']}"

    # Check for image tag in exported variables
    exported_vars = build_details.get(EnvVars.EXPORTED_ENV_VARS, [])
    image_tag = None
    for var in exported_vars:
        if var.get("name") == EnvVars.IMAGE_TAG and var.get("value"):
            image_tag = var["value"]
            repo_identifier = f"{env_data['repo_name']}:{image_tag}"
            break

    subject = f"Status of <{repo_identifier}> {project_name.split('-')[-1]} (build #{build_number}) is <{build_status}>"

    # Build message body
    message_body = (
        f"PROJECT: {project_name}\n"
        f"STATUS: {build_status}\n"
        f"TIME: {build_start_time}\n"
        f"COMPLETE_LOGS:\n{logs_link}"
    )

    if exported_vars:
        message_body += f"\nBUILD_OUTPUT: {exported_vars}"

    # Handle failed builds
    json_data = {
        EventKeys.BUILD_STATUS: build_status,
        EventKeys.BUILD_START_TIME: build_start_time,
        EventKeys.LOGS_LINK: logs_link,
        EventKeys.BUILD_NUMBER: build_number
    }

    if build_status == "FAILED":
        phases = get_nested_value(event_data, [EventKeys.DETAIL, EventKeys.ADDITIONAL_INFO, EventKeys.PHASES])
        failed_phases = extract_failed_phases(phases)

        if failed_phases:
            message_body += "\nFAILED_COMMANDS:\n\n"
            for phase in failed_phases:
                phase_type = phase.get(EventKeys.PHASE_TYPE, "Unknown")
                phase_context = phase.get(EventKeys.PHASE_CONTEXT, [])

                error_details = "\n".join(phase_context) if phase_context else "No error details available"
                message_body += f"PHASE: <{phase_type}>\nERRORS:\n{error_details}\n\n"

            json_data["failed-phases"] = failed_phases

    return {
        "subject": subject,
        "body": message_body,
        "json_data": json_data
    }

def publish_to_sns(topic_arn: str, message_content: Dict[str, Any]) -> Dict[str, Any]:
    """Publish message to SNS topic"""
    sns_message = {
        "default": message_content["body"],
        "email-json": message_content["json_data"],
        "email": message_content["body"]
    }

    try:
        response = sns_client.publish(
            TopicArn=topic_arn,
            Message=json.dumps(sns_message),
            MessageStructure='json',
            Subject=message_content["subject"]
        )

        logger.info(f"SNS message published successfully to {topic_arn}")
        return response

    except (ClientError, BotoCoreError) as e:
        logger.error(f"Failed to publish to SNS topic {topic_arn}: {e}")
        raise CustomError(f"SNS publish failed: {e}")

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Main Lambda handler function"""
    try:
        logger.info(f"Processing CodeBuild event: {event}")

        # Get SNS topic ARN
        sns_topic_arn = os.getenv(EnvVars.SNS_TOPIC_ARN)
        if not sns_topic_arn:
            raise CustomError("SNS_TOPIC_ARN environment variable not set")

        # Extract build ID and get detailed information
        build_id = get_nested_value(event, [EventKeys.DETAIL, EventKeys.BUILD_ID])
        if not build_id:
            raise CustomError("Build ID not found in event")

        build_details = get_build_details(build_id)

        logger.info(f"Build Details: {build_details}")

        # Build notification message
        message_content = build_message_content(event, build_details)

        logger.info(f"Message Content: {message_content}")

        # Log repository information
        env_vars = get_nested_value(event, [EventKeys.DETAIL, EventKeys.ADDITIONAL_INFO, EventKeys.ENVIRONMENT, EventKeys.ENV_VARIABLES])
        env_data = extract_env_variables(env_vars)

        if env_data["custom_registry_name"]:
            logger.info(f"Processing build for {env_data['repo_name']}:{env_data['branch_name']} - {env_data['custom_registry_name']}")
        else:
            logger.info(f"Processing build for {env_data['repo_name']}:{env_data['branch_name']}")

        # Publish to SNS
        publish_to_sns(sns_topic_arn, message_content)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Event processed successfully and published to SNS topic {sns_topic_arn}',
                'build_id': build_id
            })
        }

    except CustomError as e:
        logger.error(f"Custom error: {e}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error': str(e)})
        }

    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }

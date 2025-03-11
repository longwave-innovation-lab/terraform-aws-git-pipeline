
import boto3
import traceback
import json
import logging
import os

logger: logging.Logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns_client = boto3.client('sns')
codebuild_client = boto3.client('codebuild')

# some names used to access dict attributes
detail: str = "detail"
build_id: str = "build-id"
build_status: str = "build-status"
additional_information: str = "additional-information"

build_start_time: str = "build-start-time"
environment: str = "environment"
environment_variables: str = "environment-variables"
logs: str = "logs"
deep_link: str = "deep-link"
phases_attr: str = "phases"
phase_type_attr: str = "phase-type"
phase_context: str = "phase-context"
phase_status: str = "phase-status"
start_time: str = "start-time"
end_time: str = "end-time"

monitor_logs: str = "logs-link"
failed_phases_attr: str = "failed-phases"
build_number: str = "build-number"

REPO_NAME_ATTR_KEY: str = "REPO_NAME"
IMAGE_TAG_ATTR_KEY: str = "IMAGE_TAG"
BRANCH_NAME_ATTR_KEY: str = "BRANCH_NAME"
CUSTOM_REGISTRY_NAME_ATTR_KEY: str = "CUSTOM_REGISTRY_NAME"
TOPIC_ARN_ENV_VAR: str = "SNS_TOPIC_ARN"
EXPORTED_ENV_VAR_ATTR_KEY: str = "exportedEnvironmentVariables"

def get_nested(dictionary, keys, default=None):
    for key in keys:
        if isinstance(dictionary, dict):
            dictionary = dictionary.get(key, default)
        else:
            return default
    return dictionary

def get_build_details(build_id: str) -> dict:
    build_details: dict = None
    
    return_value: dict = codebuild_client.batch_get_builds(
        ids=[build_id]
    )
    
    logger.info(f"Complete Build Details: {return_value}")
    build_details: dict = return_value["builds"][0]
    
    return build_details

def lambda_handler(event, context):

    try:
        logger.info(f"Complete Event: {event}")
        
        # Getting environmental variables of codebuild to find the repo_name
        env_vars: list[dict] = get_nested(event, [detail,additional_information,environment,environment_variables], None)
        repo_name: str = None
        branch_name: str = None
        custom_registry_name: str = None

        for env_var in env_vars:
            if env_var["name"].upper() == REPO_NAME_ATTR_KEY:
                repo_name = env_var["value"]
            elif env_var["name"].upper() == BRANCH_NAME_ATTR_KEY:
                branch_name = env_var["value"]
            elif env_var["name"].upper() == CUSTOM_REGISTRY_NAME_ATTR_KEY:
                custom_registry_name = env_var["value"]

        if repo_name is None:
            raise Exception(
                "No repo_name found in the codebuild environment variables")

        
        if custom_registry_name:
            logger.info(f"Reacting build event on repository:branch - image <{repo_name}:{branch_name} - {custom_registry_name}>")
        else:
            logger.info(f"Reacting build event on repository:branch <{repo_name}:{branch_name}>")

        sns_topic_arn: str = os.getenv(TOPIC_ARN_ENV_VAR)

        logger.info(f"sns_topic_arn is <{sns_topic_arn}>")

        string_message: str = ""
        json_message: dict = {}

        logger.info(f"Building notification message...")
        
        build_id_value: str = get_nested(event, [detail, build_id])
        message_build_status = get_nested(event, [detail, build_status])
        message_build_start_time = get_nested(event, [detail, additional_information, build_start_time])
        message_monitor_logs = get_nested(event, [detail, additional_information, logs, deep_link])
        message_build_number = get_nested(event, [detail, additional_information, build_number])

        message_subject: str = f"Status of <{repo_name}:{branch_name}> pipeline (build N <{message_build_number}>) is <{message_build_status}>"
        if custom_registry_name:
            message_subject = f"Status of <{repo_name}:{branch_name} - {custom_registry_name}> pipeline (build N <{message_build_number}>) is <{message_build_status}>"
        
        build_details: dict = get_build_details(build_id_value)
        expo_env_vars: dict = get_nested(build_details, [EXPORTED_ENV_VAR_ATTR_KEY])
        
        # Beginning to build the string message
        string_message = (string_message + f"STATUS: {message_build_status}\n" + 
        f"TIME: {message_build_start_time}\n" +
        f"COMPLETE_LOGS:\n{message_monitor_logs}")
        if expo_env_vars:
            string_message = string_message + f"\nBUILD_OUTPUT: {expo_env_vars}"
            for var in expo_env_vars:
                if var["name"] == IMAGE_TAG_ATTR_KEY and var["value"]:
                    message_subject = f"Status of <{repo_name}:{var['value']}> pipeline (build N <{message_build_number}>) is <{message_build_status}>"
                    break
        
        # Beginning to build the json message
        json_message[build_status] = message_build_status
        json_message[build_start_time] = message_build_start_time
        json_message[monitor_logs] = message_monitor_logs
        json_message[build_number] = message_build_number
        
        if message_build_status == "FAILED":
            failed_phases: list[dict] = []
            
            phases: list[dict] = get_nested(event, [detail, additional_information, phases_attr])
            
            failed_phase_found: bool = False
            for phase in phases:
                status: str = get_nested(phase, [phase_status])
                if status == "FAILED":
                    
                    phase_type_value: str = get_nested(phase, [phase_type_attr])
                    phase_context_value: list[str] = get_nested(phase, [phase_context])
                    
                    # Print in the message the first line
                    if not failed_phase_found:
                        failed_phase_found = not failed_phase_found
                        string_message = string_message + "\nFAILED_COMMANDS:\n\n"
                        
                    Well_printed_errors: str = "\n".join(phase_context_value)
                    string_message = (string_message + 
                        f"PHASE: <{phase_type_value}>\n" +
                        f"ERRORS:\n" + 
                        f"{Well_printed_errors}\n\n")
                    failed_phases.append(phase)

            json_message[failed_phases_attr] = failed_phases

        sns_compatible_json_message: dict = {
            "default": string_message,
            "email-json": json_message,
            "email": string_message
        }
        
        logging.info(f"Notification message built: <{sns_compatible_json_message}>")
        
        response: dict = sns_client.publish(
            TopicArn=sns_topic_arn,
            Message=json.dumps(sns_compatible_json_message),
            MessageStructure='json',
            Subject=message_subject
        )
        if response is None:
            
            logging.error(f"There was an error sending the message to SNS Topic <{sns_topic_arn}>.")
            
            return {
                'statusCode': 500,
                'body': f"There was an error sending the message to SNS Topic <{sns_topic_arn}>."
            }

        logging.info(f"SNS message published to topic <{sns_topic_arn}>")
        # Return a success message
        return {
            'statusCode': 200,
            'body': f"Event pushed successfully to SNS topic <{sns_topic_arn}>"
        }

    except Exception as exc:
        logger.error(exc)
        logger.error(traceback.format_exc())
        return {
            'statusCode': 500,
            'body': "There was an error processing this request."
        }


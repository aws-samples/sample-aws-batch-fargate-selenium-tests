"""
Lambda handler for triggering AWS Batch jobs via EventBridge.
Receives a runId and publishes an event to the default EventBridge bus.
"""

import os
import json
import logging

import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

# Initialize AWS clients outside handler for connection reuse
eventbridge_client = boto3.client("events")

# Configuration from environment
EVENT_BUS_NAME = os.environ.get("EVENT_BUS_NAME", "default")
EVENT_SOURCE = "workflowDispatch"
EVENT_DETAIL_TYPE = "eventDrivenTest"
RUN_ID_PREFIX = "runId-"


class ValidationError(Exception):
    """Custom exception for input validation errors."""
    pass


def validate_input(event: dict) -> str:
    """
    Validate and extract runId from the event payload.
    
    Args:
        event: Lambda event payload
        
    Returns:
        Validated runId string with proper prefix
        
    Raises:
        ValidationError: If input is invalid
    """
    body = event.get("body")
    if body is None:
        raise ValidationError("Missing 'body' in event payload")
    
    # Handle string body (from API Gateway)
    if isinstance(body, str):
        try:
            body = json.loads(body)
        except json.JSONDecodeError as e:
            raise ValidationError(f"Invalid JSON in body: {e}")
    
    run_id = body.get("runId")
    if not run_id:
        raise ValidationError("Missing 'runId' in body")
    
    if not isinstance(run_id, str):
        raise ValidationError("'runId' must be a string")
    
    # Sanitize: only allow alphanumeric, hyphens, underscores
    sanitized = "".join(c for c in run_id if c.isalnum() or c in "-_")
    if sanitized != run_id:
        raise ValidationError("'runId' contains invalid characters")
    
    if len(run_id) > 128:
        raise ValidationError("'runId' exceeds maximum length of 128 characters")
    
    # Ensure proper prefix
    if not run_id.startswith(RUN_ID_PREFIX):
        run_id = f"{RUN_ID_PREFIX}{run_id}"
    
    return run_id


def lambda_handler(event: dict, context) -> dict:
    """
    Lambda handler that publishes batch job trigger events to EventBridge.
    
    Args:
        event: Lambda event containing body.runId
        context: Lambda context object
        
    Returns:
        Response dict with statusCode and body
    """
    try:
        # Validate input
        run_id = validate_input(event)
        
        # Build EventBridge entry
        entry = {
            "Source": EVENT_SOURCE,
            "DetailType": EVENT_DETAIL_TYPE,
            "Detail": json.dumps({"runId": run_id}),
            "EventBusName": EVENT_BUS_NAME,
        }
        
        logger.info("Publishing event to EventBridge", extra={"run_id": run_id})
        
        # Send event to EventBridge
        response = eventbridge_client.put_events(Entries=[entry])
        
        # Check for failed entries
        if response.get("FailedEntryCount", 0) > 0:
            failed = response.get("Entries", [{}])[0]
            error_msg = failed.get("ErrorMessage", "Unknown error")
            logger.error("EventBridge put_events failed", extra={"error": error_msg})
            return {
                "statusCode": 500,
                "body": json.dumps({"error": f"Failed to publish event: {error_msg}"})
            }
        
        logger.info("Event published successfully", extra={"run_id": run_id})
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Event published successfully",
                "runId": run_id
            })
        }
        
    except ValidationError as e:
        logger.warning("Validation error", extra={"error": str(e)})
        return {
            "statusCode": 400,
            "body": json.dumps({"error": str(e)})
        }
        
    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        logger.error("AWS API error", extra={"error_code": error_code, "error": str(e)})
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Internal service error"})
        }
        
    except Exception as e:
        # Log full error but return generic message (security best practice)
        logger.exception("Unexpected error")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Internal service error"})
        }

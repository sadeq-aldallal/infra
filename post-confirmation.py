import json
import os
import logging
import boto3
from botocore.exceptions import ClientError
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB resource and table
dynamodb = boto3.resource('dynamodb')
table_name = os.getenv('TABLE_NAME', 'dev-fead')
table = dynamodb.Table(table_name)

def store_user_data(user_id: str, phone_number: str, name: str) -> None:
    """
    Stores user data in the DynamoDB table with metadata.

    :param user_id: The user's unique identifier (UUID).
    :param phone_number: The user's phone number.
    """
    try:
        logger.info(f"Storing user data for id: {user_id}, phone_number: {phone_number}")
        table.put_item(
            Item={
                'PK': f'USERNAME#{name}',
                'SK': f'ID#{user_id}',
                'Metadata': {
                    'phone_number': phone_number
                }
            }
        )
    except ClientError as e:
        error_message = e.response['Error']['Message']
        logger.error(f"Failed to store user data: {error_message}")
        raise e

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler function to process Cognito post-confirmation events.

    :param event: The event data passed by Cognito.
    :param context: The runtime context provided by AWS Lambda.
    :return: The original event data.
    """
    print(event)
    user_id = event['userName']
    phone_number = event['request']['userAttributes'].get('phone_number')
    name = event['request']['userAttributes'].get('name')
    
    logger.info(f"Received post-confirmation event for user_id: {user_id}, phone_number: {phone_number}")
    
    # Store user data in DynamoDB
    store_user_data(user_id, phone_numbe, name)
    
    logger.info("User data successfully stored.")
    
    return event

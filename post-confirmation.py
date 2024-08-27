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
table_name = os.getenv('TABLE_NAME', 'dev-fead-users')  # Use environment variable for table name
table = dynamodb.Table(table_name)

def store_user_data(user_id: str, email: str, username: str) -> None:
    """
    Stores user data in the DynamoDB table.

    :param user_id: The user's unique identifier (UUID).
    :param email: The user's email address.
    :param username: The user's username.
    """
    try:
        logger.info(f"Storing user data for id: {user_id}, email: {email}, username: {username}")
        table.put_item(
            Item={
                'id': user_id,     # Hash key as per the table definition
                'email': email,    # Email attribute
                'username': username  # Username attribute
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
    user_id = event['request']['userAttributes']['sub']
    email = event['request']['userAttributes']['email']
    username = event['userName']  # Get the username from the event
    
    logger.info(f"Received post-confirmation event for user_id: {user_id}, email: {email}, username: {username}")
    
    # Store user data in DynamoDB
    store_user_data(user_id, email, username)
    
    logger.info("User data successfully stored.")
    
    return event

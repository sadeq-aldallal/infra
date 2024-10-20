resource "aws_cognito_user_pool" "user_pool" {
    name = "${var.env}-${var.product}-user-pool"

    # Sign-in options
    alias_attributes = ["email", "phone_number","preferred_username"]

    # Username case sensitivity
    username_configuration {
      case_sensitive = false
    }

    # Add the SMS configuration for phone number verification
    sms_configuration {
      external_id = "CognitoSMSRole"
      sns_caller_arn = aws_iam_role.cognito_sms_role.arn
    }
    lambda_config {
        post_confirmation = aws_lambda_function.post_confirmation_lambda.arn
      }
    # Password policy
    password_policy {
      minimum_length    = 8
      require_lowercase = true
      require_numbers   = true
      require_symbols   = true
      require_uppercase = true
      temporary_password_validity_days = 7

    }
  

    # MFA configuration
    mfa_configuration = "OFF"

    # Account recovery settings (prefer phone number recovery)
    account_recovery_setting {
      recovery_mechanism {
        name     = "verified_phone_number"  # Use phone for account recovery
        priority = 1
      }
      recovery_mechanism {
        name     = "verified_email"
        priority = 2
      }
    }

    # Verification message settings (for phone number verification)
    verification_message_template {
      default_email_option     = "CONFIRM_WITH_CODE"
      email_message            = "كود التحقق الخاص بك هو {####}."
      email_subject            = "كود التحقق الخاص بك"
      email_message_by_link    = "اضغط على الرابط التالي للتحقق من بريدك الإلكتروني: {##Verify Email##}"
      email_subject_by_link    = "تحقق من بريدك الإلكتروني"
      sms_message              = "كود التحقق الخاص بك هو {####}."
    }

    # Verification configuration
    auto_verified_attributes = ["phone_number"]

    # Required attributes
    # Schema for email and phone_number (phone_number is required)
    schema {
      attribute_data_type = "String"
      name                = "phone_number"
      required            = true
      mutable             = true
    }
    # Optional email attribute
    schema {
      attribute_data_type = "String"
      name                = "email"
      required            = false  # Email is optional
      mutable             = true
    }

    # Self-registration settings
    admin_create_user_config {
      allow_admin_create_user_only = false
    }

    # Tags
    tags = {
      env = "${var.env}"
    }

    # Deletion protection
    deletion_protection = "ACTIVE"
    lifecycle {
      ignore_changes = [
        schema,  # This prevents Terraform from trying to update the schema
      ]
    }
  
}
# IAM Role for Cognito to send SMS using SNS
resource "aws_iam_role" "cognito_sms_role" {
  name = "${var.env}-${var.product}-cognito-sms-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cognito-idp.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy that allows Cognito to use SNS for sending SMS
resource "aws_iam_role_policy" "cognito_sms_policy" {
  name = "${var.env}-${var.product}-cognito-sms-policy"
  role = aws_iam_role.cognito_sms_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sns:Publish",
        Resource = "*"
      }
    ]
  })
}
resource "aws_cognito_user_pool_client" "mobile_app_client" {
  name                          = "${var.env}-${var.product}-mobile"
  user_pool_id                  = aws_cognito_user_pool.user_pool.id
  prevent_user_existence_errors = "ENABLED"

  # Client settings
  allowed_oauth_flows = ["code"]  # Authorization code grant
  allowed_oauth_scopes = ["email", "openid", "phone"]  # Allow email and phone
  allowed_oauth_flows_user_pool_client = true
  callback_urls        = ["http://localhost"]
  logout_urls          = []
  default_redirect_uri = "http://localhost"
  supported_identity_providers = ["COGNITO"]

  # Token expiration settings
  refresh_token_validity      = 565   # in days
  access_token_validity       = 24  # in hours (1 day)
  id_token_validity           = 24  # in hours (1 day)
  auth_session_validity       = 15    # Authentication session duration in minutes

  # Authentication flows
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  # Advanced security settings
  enable_token_revocation = true

  # Hosted UI settings
  generate_secret = false  # Set to true if a client secret is required
}


data "archive_file" "post_confirmation_lambda_zip" {
  type        = "zip"
  source_file = "post-confirmation.py"
  output_path = "post-confirmation.zip"
}


resource "aws_lambda_function" "post_confirmation_lambda" {
  filename         = data.archive_file.post_confirmation_lambda_zip.output_path
  function_name    = "${var.env}-${var.product}-post-confirmation"
  role             = aws_iam_role.lambda_role.arn
  handler          = "post-confirmation.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.fead_table.name
    }
  }

  source_code_hash = data.archive_file.post_confirmation_lambda_zip.output_base64sha256
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.env}-${var.product}-post-confirmation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "${var.env}-${var.product}-post-confirmation-policy"
  description = "IAM policy for Lambda to access DynamoDB"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem"
        ],
        Effect = "Allow",
        Resource = aws_dynamodb_table.fead_table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.lambda_dynamodb_policy.arn
}

resource "aws_cloudwatch_log_group" "post_confirmation_log_group" {
  name              = "/aws/lambda/${var.env}-${var.product}-post-confirmation"
  retention_in_days = 7  # Optional: Set log retention period
}

resource "aws_iam_policy" "lambda_cloudwatch_policy" {
  name        = "${var.env}-${var.product}-lambda-cloudwatch-policy"
  description = "IAM policy for Lambda to access CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_policy.arn
}

resource "aws_iam_role" "cognito_lambda_invoke_role" {
  name = "${var.env}-${var.product}-cognito-lambda-invoke-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cognito-idp.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}



# Allow Cognito to Invoke Lambda Function
resource "aws_lambda_permission" "allow_cognito_invoke" {
  statement_id  = "lambda-allow-cognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_confirmation_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.user_pool.arn
  source_account = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}
# ============================================
# IAM ROLE FOR INGESTION LAMBDA
# Think of this as a "job title" for the Lambda
# It defines what AWS services it's allowed to touch
# ============================================
resource "aws_iam_role" "ingestion_lambda_role" {
  name = "${var.project_name}-ingestion-role"

  # This says: "Lambda functions are allowed to use this role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = { Project = var.project_name }
}

# ============================================
# INGESTION LAMBDA PERMISSIONS (Least Privilege)
# It can ONLY write to OUR specific DynamoDB table
# It cannot read, delete, or touch anything else
# ============================================
resource "aws_iam_role_policy" "ingestion_dynamodb_policy" {
  name = "${var.project_name}-ingestion-dynamodb-policy"
  role = aws_iam_role.ingestion_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permission to write stock data to DynamoDB
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"   # write only — nothing else!
        ]
        Resource = aws_dynamodb_table.stock_movers.arn
      },
      {
        # Permission to write logs to CloudWatch
        # This is how we debug if something goes wrong
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ============================================
# IAM ROLE FOR API LAMBDA
# Separate role from ingestion — different job,
# different permissions
# ============================================
resource "aws_iam_role" "api_lambda_role" {
  name = "${var.project_name}-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = { Project = var.project_name }
}

# ============================================
# API LAMBDA PERMISSIONS (Least Privilege)
# It can ONLY read from OUR specific DynamoDB table
# It cannot write, delete, or touch anything else
# ============================================
resource "aws_iam_role_policy" "api_dynamodb_policy" {
  name = "${var.project_name}-api-dynamodb-policy"
  role = aws_iam_role.api_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permission to read stock data from DynamoDB
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",  # read one item by date
          "dynamodb:Scan"      # read multiple items
        ]
        Resource = aws_dynamodb_table.stock_movers.arn
      },
      {
        # CloudWatch logs for debugging
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ============================================
# ZIP THE LAMBDA CODE
# Terraform packages your Python files into
# .zip files to upload to AWS
# ============================================
data "archive_file" "ingestion_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/ingestion"
  output_path = "${path.module}/../lambdas/ingestion/ingestion.zip"
}

data "archive_file" "api_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambdas/api/handler.py"
  output_path = "${path.module}/../lambdas/api/handler.zip"
}

# ============================================
# INGESTION LAMBDA FUNCTION
# This runs daily to fetch stock data
# ============================================
resource "aws_lambda_function" "ingestion" {
  filename         = "${path.module}/../lambdas/ingestion/ingestion.zip"
  function_name    = "${var.project_name}-ingestion"
  role             = aws_iam_role.ingestion_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30  # seconds before it gives up

  # Source code hash — Terraform detects when
  # your Python code changes and redeploys automatically
  source_code_hash = data.archive_file.ingestion_zip.output_base64sha256

  # Environment variables — secrets injected at runtime
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.stock_movers.name
      STOCK_API_KEY  = var.stock_api_key
    }
  }

  tags = { Project = var.project_name }
}

# ============================================
# API LAMBDA FUNCTION
# This runs when someone calls GET /movers
# ============================================
resource "aws_lambda_function" "api" {
  filename         = data.archive_file.api_zip.output_path
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.api_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 10

  source_code_hash = data.archive_file.api_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.stock_movers.name
    }
  }

  tags = { Project = var.project_name }
}
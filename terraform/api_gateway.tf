# ============================================
# HTTP API GATEWAY
# Creates the REST API with a single endpoint:
# GET /movers → triggers API Lambda
# ============================================
resource "aws_apigatewayv2_api" "stocks_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "API for retrieving top stock movers"

  # CORS — allows your S3 website to call this API
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }

  tags = { Project = var.project_name }
}

# ============================================
# CONNECT API GATEWAY TO LAMBDA
# "When GET /movers is called → run api Lambda"
# ============================================
resource "aws_apigatewayv2_integration" "api_lambda_integration" {
  api_id             = aws_apigatewayv2_api.stocks_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.api.invoke_arn
  integration_method = "POST"
}

# ============================================
# DEFINE THE ROUTE
# This is your GET /movers endpoint
# ============================================
resource "aws_apigatewayv2_route" "get_movers" {
  api_id    = aws_apigatewayv2_api.stocks_api.id
  route_key = "GET /movers"
  target    = "integrations/${aws_apigatewayv2_integration.api_lambda_integration.id}"
}

# ============================================
# DEPLOY THE API
# Without this stage, the API exists but
# isn't publicly accessible yet
# ============================================
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.stocks_api.id
  name        = "prod"
  auto_deploy = true

  tags = { Project = var.project_name }
}

# ============================================
# GIVE API GATEWAY PERMISSION TO INVOKE LAMBDA
# Same as EventBridge — must explicitly allow it
# ============================================
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.stocks_api.execution_arn}/*/*"
}
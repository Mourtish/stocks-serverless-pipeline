output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.stock_movers.name
}

output "api_endpoint" {
  description = "Your GET /movers API URL — paste this in your frontend"
  value       = "${aws_apigatewayv2_stage.prod.invoke_url}/movers"
}

output "frontend_url" {
  description = "Your live website URL"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "ingestion_lambda_name" {
  description = "Ingestion Lambda name — use this to test manually"
  value       = aws_lambda_function.ingestion.function_name
}
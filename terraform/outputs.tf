# ============================================
# These values get printed after terraform apply
# You'll need them in later steps
# ============================================

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.stock_movers.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.stock_movers.arn
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}
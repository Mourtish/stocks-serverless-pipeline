# ============================================
# AWS Region — where all resources are created
# ============================================
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# ============================================
# Project name — used to name all resources
# consistently so you can find them in AWS
# ============================================
variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "stocks-pipeline"
}

# ============================================
# Stock watchlist — the 6 stocks we track
# ============================================
variable "watchlist" {
  description = "List of stock tickers to monitor"
  type        = list(string)
  default     = ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA"]
}

# ============================================
# Stock API Key — pulled from environment
# variable, never hardcoded here
# ============================================
variable "stock_api_key" {
  description = "API key for stock data provider"
  type        = string
  sensitive   = true  # Terraform won't print this in logs
}
# ============================================
# DynamoDB Table: stores the daily top mover
#
# Structure:
#   date        → "2026-03-16"  (Partition Key)
#   ticker      → "NVDA"
#   pct_change  → "3.47"
#   close_price → "891.23"
# ============================================
resource "aws_dynamodb_table" "stock_movers" {
  name         = "${var.project_name}-movers"
  billing_mode = "PAY_PER_REQUEST"  # Only pay per read/write, free tier safe
  hash_key     = "date"             # Partition key = date string

  attribute {
    name = "date"
    type = "S"    # S = String
  }

  tags = {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
# ============================================
# EVENTBRIDGE RULE — The Daily Scheduler
# Runs at 9PM UTC = ~4PM EST (after market close)
# Cron format: minute hour day month weekday year
# "0 21 * * ? *" = every day at 21:00 UTC
# ============================================
resource "aws_cloudwatch_event_rule" "daily_stock_trigger" {
  name                = "${var.project_name}-daily-trigger"
  description         = "Triggers stock ingestion Lambda daily after market close"
  schedule_expression = "cron(0 21 * * ? *)"

  tags = { Project = var.project_name }
}

# ============================================
# CONNECT THE RULE TO THE LAMBDA
# "When the timer fires → run the ingestion Lambda"
# ============================================
resource "aws_cloudwatch_event_target" "trigger_ingestion_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_stock_trigger.name
  target_id = "IngestionLambdaTarget"
  arn       = aws_lambda_function.ingestion.arn
}

# ============================================
# GIVE EVENTBRIDGE PERMISSION TO INVOKE LAMBDA
# Without this, EventBridge can't actually
# trigger the Lambda — permission denied!
# ============================================
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_stock_trigger.arn
}
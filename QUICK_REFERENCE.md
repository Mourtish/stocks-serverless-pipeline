# ⚡ Quick Reference

Technical reference and command lookup for common operations.

---

## 🔗 Live Links (Permanent After Deployment)

```bash
# Run this once to see your links:
cd terraform
terraform output
```

- **Frontend URL:** `http://stocks-pipeline-frontend-<ACCOUNT_ID>.s3-website-us-east-1.amazonaws.com`
- **API Endpoint:** `https://xxx.execute-api.us-east-1.amazonaws.com/movers`
- **DynamoDB Table:** `stock_movers`

---

## Deployment Checklist

```bash
# 1. Load API key from secret
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)

# 2. Deploy infrastructure
cd terraform
terraform init
terraform apply -var="stock_api_key=$STOCK_API_KEY"

# 3. Manually invoke ingestion (optional)
aws lambda invoke \
  --function-name $(terraform output -raw ingestion_lambda_name) \
  /tmp/invoke.json

# 4. Verify API endpoint works
curl $(terraform output -raw api_endpoint) | jq '.movers[0]'
```

---

## Key Architecture Components

| Component | Purpose | Key File |
|-----------|---------|----------|
| Scheduler | Daily trigger (9 PM UTC) | `terraform/eventbridge.tf` |
| Ingestion | Fetch & process stocks | `lambdas/ingestion/handler.py` |
| Database | Historical data store | `terraform/dynamodb.tf` |
| Retrieval | Last 7 days of data | `lambdas/api/handler.py` |
| API | REST endpoint | `terraform/api_gateway.tf` |
| Frontend | Public dashboard | `frontend/index.html` |

---

## Design Rationale

**EventBridge Cron vs Alternatives**
- Serverless scheduling, no EC2 required
- Fixed execution time suitable for daily batch
- Cost: ~$0.10/month

**DynamoDB vs RDS**
- Serverless with automatic scaling
- Pay-per-request model (~$0.25–$1.00/month)
- No complex joins required for this use case

**Two Lambda Functions**
- Separation of concerns: ingestion vs retrieval
- Independent scaling behavior
- Failure isolation (ingestion failure doesn't affect API)

**Scanning vs Querying DynamoDB**
- Current: Scan all rows, sort and limit in application
- Suitable for small datasets (~70 items for 7 days)
- Future optimization: Add GSI for query efficiency at scale

---

## Secret Management

```bash
# Store API key
gh secret set STOCK_API_KEY

# Retrieve and use
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)
```

**Rationale:** Encrypted storage, no exposure to shell history, CI/CD compatible

---

## Common Troubleshooting

**Frontend displays empty data**
```bash
# Frontend API endpoint may be outdated
# Update hardcoded URL in frontend/index.html with current API Gateway URL
API_URL=$(terraform output -raw api_endpoint)

# Redeploy frontend
aws s3 cp frontend/index.html s3://$(terraform output -raw frontend_bucket_name)/

# Clear browser cache (hard refresh: Ctrl+Shift+R)
```

**API returns no records**
```bash
# Manually trigger ingestion Lambda
aws lambda invoke \
  --function-name $(terraform output -raw ingestion_lambda_name) \
  /tmp/response.json

# Wait ~5 seconds, then check DynamoDB
aws dynamodb scan --table-name stock_movers --region us-east-1
```

**Lambda function not found**
```bash
# Verify infrastructure is deployed
cd terraform
terraform output

# If missing, redeploy
terraform apply -var="stock_api_key=$STOCK_API_KEY"
```

---

## 📊 Costs (Real Numbers)

| Service | Free Tier | Our Usage | Cost |
|---------|-----------|-----------|------|
| Lambda | 1M invokes | ~30/month | $0 |
| DynamoDB | 25 WCU/RCU | ~10 writes/day | $0 |
| API Gateway | 1M requests | ~30/month | $0 |
| EventBridge | 14.2M events | 365/year | $0 |
| S3 | 5 GB | <1 MB | $0 |
| CloudWatch | 5 GB logs | <100 MB | $0 |
| **TOTAL** | | | **$0.00** |

---

## Architecture Summary

**Serverless Design**
- No EC2 instances or long-running processes
- Event-driven scheduling via EventBridge
- Auto-scaling compute via Lambda

**Infrastructure as Code**
- Fully defined in Terraform
- Version-controlled and reproducible
- No manual AWS Console operations

**Security**
- Encrypted secret storage (GitHub Codespace Secrets)
- Least-privilege IAM roles per Lambda
- Environment variables for configuration

**Cost Efficiency**
- Pay-per-request billing (Lambda, DynamoDB, API Gateway)
- Fits entirely within AWS Free Tier first year
- Estimated monthly cost: ~$0.25–$1.00

**Separation of Concerns**
- Ingestion pipeline independent from API layer
- Database layer decoupled from compute
- Each component can scale independently

---

## Project Files Reference

| File | Purpose |
|------|---------|
| `README.md` | Project overview and setup instructions |
| `terraform/main.tf` | AWS provider and general configuration |
| `terraform/eventbridge.tf` | Daily scheduler definition |
| `terraform/lambda.tf` | Lambda functions and IAM roles |
| `terraform/dynamodb.tf` | Stock movers table schema |
| `lambdas/ingestion/handler.py` | Stock data fetching logic |
| `lambdas/api/handler.py` | REST API response formatting |
| `frontend/index.html` | Dashboard UI |
| `.gitignore` | Prevents committing secrets |

---

## Command Reference

**Deploy Infrastructure**
```bash
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)
cd terraform
terraform init
terraform apply -var="stock_api_key=$STOCK_API_KEY"
```

**Query DynamoDB**
```bash
aws dynamodb scan \
  --table-name stock_movers \
  --region us-east-1
```

**Invoke Lambda Manually**
```bash
aws lambda invoke \
  --function-name stocks-pipeline-ingestion \
  /tmp/response.json
```

**Test API Endpoint**
```bash
curl $(terraform output -raw api_endpoint) | jq .
```

**View CloudWatch Logs**
```bash
aws logs tail /aws/lambda/stocks-pipeline-ingestion --follow
```

**Destroy Infrastructure**
```bash
cd terraform
terraform destroy -var="stock_api_key=$STOCK_API_KEY"
```

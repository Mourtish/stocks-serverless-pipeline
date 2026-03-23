# 📈 Stocks Serverless Pipeline

A fully automated, production-grade serverless data pipeline that tracks daily stock market movements. Built with AWS (Lambda, DynamoDB, EventBridge, API Gateway, S3), Infrastructure as Code (Terraform), and a modern frontend.

**Live Demo:** [Your S3 URL will appear here after deployment]  
**GitHub Repo:** [This repository]

---

## 🎯 The Challenge

Build a serverless system that:
- ✅ Wakes up daily (EventBridge Cron)
- ✅ Fetches stock data for a watchlist (Lambda)
- ✅ Identifies the biggest mover (highest % change)
- ✅ Records history (DynamoDB)
- ✅ Serves data via REST API (API Gateway + Lambda)
- ✅ Displays results on a public website (S3 static hosting)
- ✅ Uses Infrastructure as Code (Terraform)
- ✅ **No manual AWS Console clicking allowed**

**Watchlist:** AAPL, MSFT, GOOGL, AMZN, TSLA, NVDA, META, NFLX, UBER, AMD

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Serverless Pipeline                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  EventBridge (Cron)                                              │
│  └─→ Trigger daily @ 9 PM UTC (4 PM EST - post market close)    │
│       │                                                           │
│       └──→ Ingestion Lambda                                      │
│            ├─ Fetch stock prices from API                        │
│            ├─ Calculate % change: ((Close - Open) / Open) × 100 │
│            └─ Write to DynamoDB                                  │
│                 │                                                │
│                 └──→ DynamoDB Table (stock_movers)               │
│                      ├─ Partition Key: date                      │
│                      ├─ Sort Key: ticker                         │
│                      └─ Stores: price, % change, winner flag     │
│                           │                                       │
│                           └──→ API Lambda                         │
│                                └─ GET /movers → Last 7 days      │
│                                     │                             │
│                                     └──→ API Gateway (HTTP)       │
│                                          │                        │
│                                          └──→ Frontend (S3)      │
│                                               ├─ Displays table   │
│                                               ├─ Color-coded UI   │
│                                               └─ Public URL       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Purpose | Technology |
|-----------|---------|-----------|
| **Scheduler** | Daily trigger (9 PM UTC) | EventBridge Cron |
| **Ingestion** | Fetch & process stocks | Lambda + requests |
| **Database** | Store historical data | DynamoDB (on-demand) |
| **Retrieval** | Get last 7 days | Lambda + DynamoDB Query |
| **API** | REST endpoint for frontend | API Gateway v2 (HTTP) |
| **Frontend** | Public dashboard | S3 static hosting + vanilla JS |
| **IaC** | Infrastructure definition | Terraform (modular, parameterized) |

---

## 🚀 Quick Start

### Prerequisites

- AWS Account (Free Tier eligible)
- Terraform >= 1.7.0
- AWS CLI v2
- Python 3.9+
- Node.js OR curl (for testing)

### Step 1: Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/stocks-serverless-pipeline.git
cd stocks-serverless-pipeline
```

### Step 2: Configure AWS Credentials

**Option A: Using AWS CLI (Recommended)**
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
```

**Option B: Set Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 3: Set Up Stock API Key

Get a free API key from a provider (e.g., Polygon.io, Finnhub, AlphaVantage):

**For Local Development (GitHub Codespace):**
```bash
# Store in Codespace secrets (most secure for CI/CD + live demos)
gh secret set STOCK_API_KEY --body "your-api-key-here"

# Then export it in your shell session
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)
```

**Why Codespace Secrets Over .env Files?**
- ✅ Never leaked to GitHub (encrypted at rest)
- ✅ Automatically available to GitHub Actions workflows
- ✅ Perfect for live demos (no file system exposure)
- ✅ Survives across terminal restarts in Codespace
- ✅ Better than environment variables passed via command line (shell history)

### Step 4: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform (downloads AWS provider)
terraform init

# Plan the deployment (review what will be created)
terraform plan -var="stock_api_key=$STOCK_API_KEY"

# Deploy! (this creates all AWS resources)
terraform apply -var="stock_api_key=$STOCK_API_KEY"

# Save the outputs (you'll need these)
terraform output
```

**What Gets Created:**
- DynamoDB table (on-demand pricing)
- Lambda functions (ingestion + API)
- API Gateway HTTP endpoint
- S3 bucket for frontend
- EventBridge rule for daily scheduling
- IAM roles with least-privilege permissions

### Step 5: Deploy Frontend

```bash
# Build and deploy frontend to S3
aws s3 cp frontend/index.html s3://$(terraform output -raw frontend_bucket_name)/
aws s3 cp frontend/styles.css s3://$(terraform output -raw frontend_bucket_name)/ 2>/dev/null || true

# Get your live website URL
terraform output -raw frontend_url
```

**Your frontend is now live!** Visit the URL in your browser.

### Step 6: Update Frontend with Your API

The frontend needs your API Gateway endpoint. Edit `frontend/index.html`:

```javascript
// Find this line (around line 150):
const API_URL = "https://your-api-gateway-url/movers";

// Replace with your actual endpoint from:
terraform output -raw api_endpoint
```

Then redeploy:
```bash
aws s3 cp frontend/index.html s3://$(terraform output -raw frontend_bucket_name)/
```

---

## 📝 Commands Reference

### Testing Locally

**Test Ingestion Lambda (manually trigger):**
```bash
cd lambdas/ingestion

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)
export AWS_REGION=us-east-1
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)

# Run the handler
python -c "
import json, sys, os
sys.path.insert(0, 'vendor')
from handler import lambda_handler
result = lambda_handler({}, {})
print(json.dumps(result, indent=2))
"
```

**Test API Lambda (locally):**
```bash
cd lambdas/api

export DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)
export AWS_REGION=us-east-1

curl -X GET http://localhost:9000/movers \
  -H "Content-Type: application/json"
```

### Triggering Ingestion Manually (via AWS)

```bash
# Without waiting for the nightly cron, invoke Lambda immediately:
aws lambda invoke \
  --function-name $(terraform output -raw ingestion_lambda_name) \
  --region us-east-1 \
  response.json

# Check the result
cat response.json | jq .
```

### Viewing DynamoDB Data

```bash
# Scan all items in the table
aws dynamodb scan \
  --table-name $(terraform output -raw dynamodb_table_name) \
  --region us-east-1

# Query by date (if using Query instead of Scan)
aws dynamodb query \
  --table-name $(terraform output -raw dynamodb_table_name) \
  --key-condition-expression "date = :d" \
  --expression-attribute-values '{":d": {"S": "2026-03-23"}}' \
  --region us-east-1
```

### Checking API Gateway Logs

```bash
# View CloudWatch logs for API Lambda
aws logs tail /aws/lambda/$(terraform output -raw api_lambda_name) --follow
```

### Destroying Infrastructure (When Done)

```bash
cd terraform
terraform destroy
```

---

## 🔑 Security & Best Practices

### 1. **API Keys are NOT in Git** ✅
- Stored in GitHub Codespace secrets
- Referenced via environment variables in Terraform
- Marked as `sensitive = true` in Terraform (hidden from logs)

### 2. **Least Privilege IAM Roles** ✅
```hcl
# Each Lambda gets ONLY the permissions it needs
# Ingestion Lambda: DynamoDB write-only
# API Lambda: DynamoDB read-only
```

### 3. **Environment Variables, Not Hardcoding** ✅
```python
STOCK_API_KEY = os.getenv("STOCK_API_KEY")      # From Terraform
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE")    # From Terraform
```

### 4. **Error Handling & Retry Logic** ✅
- Try/except blocks around API calls
- Graceful degradation if API rate-limits
- Detailed logging for debugging

### 5. **S3 Bucket Policy** ✅
```json
// S3 bucket is PUBLIC for GET (read) only
// No PUT/DELETE allowed from internet
// Only authenticated users can modify via AWS CLI
```

---

## 🎨 Features & Differentiation

### What Makes This Stand Out?

1. **Separation of Concerns**
   - `ingestion/` handler: Fetches + writes
   - `api/` handler: Reads + formats
   - Completely decoupled (can scale independently)

2. **Error Handling**
   - API rate-limit protection
   - Graceful failures (doesn't crash if API down)
   - Comprehensive logging for debugging

3. **Modular Terraform**
   - Separate files: `lambda.tf`, `dynamodb.tf`, `eventbridge.tf`, etc.
   - Easy to understand and modify
   - Documented with inline comments

4. **Responsive Frontend**
   - Mobile-friendly design
   - Real-time data fetching
   - Color-coded movers (green/red)

5. **Vendor Packaging** (Advanced)
   - Dependencies bundled in Lambda zip
   - Supports Lambda execution role restrictions
   - No internet access needed at runtime

---

## 💡 Trade-offs & Design Decisions

### Decision: EventBridge Cron vs API Triggers

**We Chose:** EventBridge Cron  
**Why:** 
- Serverless scheduler (no EC2 needed)
- Runs at exact time regardless of load
- Perfect for daily batch jobs
- Costs: ~$0.10/month

**Alternative:** API trigger (webhook) would require external cron service.

---

### Decision: DynamoDB On-Demand Pricing

**We Chose:** On-demand (pay per request)  
**Why:**
- Very low volume: ~1-10 writes/day, ~few reads/day
- No need to predict capacity
- Costs: ~$0.25-$1.00/month

**Alternative:** Provisioned capacity would cost more for our traffic.

---

### Decision: Scan vs Query in API

**Current:** Scan (retrieve all, filter in Lambda)  
**Why:** Works well for small datasets (~7 days = ~70 items)  
**Production Improvement:** Use Query with GSI (Global Secondary Index) for better performance.

---

### Decision: Vanilla JS Frontend

**We Chose:** No framework (pure HTML/CSS/JS)  
**Why:**
- Simple SPA, no build step needed
- Lightweight (~5KB total)
- Easy to deploy to S3

**Alternative:** Could use Next.js/Vue, but adds complexity & build step.

---

## 🧪 Testing the Project

### 1. Manual Lambda Invocation

```bash
# Trigger ingestion now (don't wait for nightly cron)
aws lambda invoke \
  --function-name stocks-pipeline-ingestion \
  --region us-east-1 \
  /tmp/response.json

cat /tmp/response.json
```

### 2. Check DynamoDB

```bash
aws dynamodb scan \
  --table-name stock_movers \
  --region us-east-1 | jq '.Items[] | {date, ticker, pct_change}'
```

### 3. Test API Endpoint

```bash
curl https://your-api-id.execute-api.us-east-1.amazonaws.com/movers | jq .
```

### 4. Visit Frontend

Open the S3 website URL in your browser. You should see a table of movers.

---

## 📊 Monitoring & Debugging

### CloudWatch Logs

```bash
# Tail ingestion Lambda logs
aws logs tail /aws/lambda/stocks-pipeline-ingestion --follow

# Tail API Lambda logs
aws logs tail /aws/lambda/stocks-pipeline-api --follow
```

### CloudWatch Metrics

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=stocks-pipeline-ingestion \
  --start-time 2026-03-20T00:00:00Z \
  --end-time 2026-03-23T23:59:59Z \
  --period 86400 \
  --statistics Sum
```

---

## 🎤 Talking Points for Recruiters

### "Here's What I Built"

> *"I designed and deployed a fully serverless data pipeline in AWS that automates stock market analysis. It's triggered daily via EventBridge, processes data in Lambda, stores results in DynamoDB, and serves them via an HTTP API. Everything is Infrastructure as Code (Terraform) — no manual console clicking. The frontend is hosted on S3 and shows the 7-day history of market movers."*

### "Here's Why It's Well-Architected"

1. **Separation of Concerns**
   - Ingestion Lambda: responsibility = fetch & store
   - API Lambda: responsibility = retrieve & format
   - If one fails, the other isn't affected

2. **Security**
   - API keys stored in GitHub Codespace secrets, never in code
   - IAM roles follow least-privilege principle
   - Each Lambda has minimal permissions

3. **Scalability**
   - EventBridge scales automatically
   - DynamoDB on-demand pricing auto-scales with load
   - Lambda cold-start optimizations (lightweight layers)

4. **Reliability**
   - Error handling with try/except blocks
   - Graceful degradation if API rate-limits
   - Detailed logging for ops/debugging

5. **Infrastructure as Code**
   - Terraform manages all resources
   - Code is versioned, reviewable, reproducible
   - Easy to tear down or replicate environment

### "What I Learned"

> *"I deepened my understanding of serverless patterns: event-driven architecture, permission scoping, and cost optimization. I also learned when to use on-demand vs. provisioned DynamoDB, and how to efficiently package Python dependencies for Lambda."*

### "What I'd Do Differently at Scale"

> *"With higher volume, I'd:"*
- Add a **custom alarm/dashboard** in CloudWatch
- Implement **API rate-limiting** (API Gateway throttling)
- Add a **global secondary index** on ticker for faster queries
- Set up **GitHub Actions** for automated testing + deployment
- Use **RDS  Aurora Serverless** for complex historical analysis

---

## 🛠️ Troubleshooting

### Problem: "ImportError: No module named 'requests'"

**Cause:** Python dependencies not in Lambda zip  
**Solution:**
```bash
cd lambdas/ingestion
# Ensure vendor/ contains boto3, requests, etc.
ls vendor/  # should show: boto3, botocore, requests, etc.
```

### Problem: "ResourceNotFoundException: Requested resource not found"

**Cause:** DynamoDB table doesn't exist  
**Solution:**
```bash
terraform apply -var="stock_api_key=$STOCK_API_KEY"
```

### Problem: "AccessDeniedException" when accessing DynamoDB

**Cause:** Lambda IAM role missing permissions  
**Solution:** Check `terraform/lambda.tf` — ensure ingestion role has `dynamodb:PutItem`

### Problem: Frontend shows "Error: Failed to fetch /movers"

**Cause:** API endpoint URL wrong OR API not deployed  
**Solution:**
```bash
# 1. Update frontend with correct API URL
terraform output -raw api_endpoint

# 2. Verify API is working
curl $(terraform output -raw api_endpoint)
```

---

## 📚 Project Structure

```
stocks-serverless-pipeline/
├── README.md                 ← You are here
├── lambdas/
│   ├── ingestion/           ← Fetches stocks, finds biggest mover
│   │   ├── handler.py       ← Main Lambda logic
│   │   ├── requirements.txt ← Python dependencies
│   │   └── vendor/          ← Vendored deps (boto3, requests, etc.)
│   └── api/
│       └── handler.py       ← REST API logic (GET /movers)
├── frontend/
│   └── index.html           ← Single-page application
├── terraform/               ← Infrastructure as Code
│   ├── main.tf              ← Provider + general config
│   ├── variables.tf         ← Input variables (aws_region, watchlist, etc.)
│   ├── outputs.tf           ← Terraform outputs (API URL, S3 URL, etc.)
│   ├── lambda.tf            ← Lambda functions + roles + layers
│   ├── dynamodb.tf          ← DynamoDB table
│   ├── eventbridge.tf       ← EventBridge cron rule
│   ├── api_gateway.tf       ← API Gateway HTTP endpoint
│   ├── s3.tf                ← S3 bucket + static website config
│   ├── terraform.tfstate    ← Terraform state (tracks what exists)
│   └── terraform.tfstate.backup ← Backup of state
└── aws/                     ← AWS CLI helpers
    └── install              ← Script to install AWS CLI
```

---

## 💰 Cost Estimate (AWS Free Tier)

| Service | Free Tier | Monthly Cost (Typical) |
|---------|-----------|---------|
| **Lambda** | 1M invocations | ~$0 (well below limit) |
| **DynamoDB** | 25 GB storage + 25 RCU/WCU | ~$0 (on-demand, light usage) |
| **API Gateway** | 1M requests | ~$0 (well below limit) |
| **EventBridge** | 14.2M events | ~$0 (1 event/day = 365 events/year) |
| **S3** | 5 GB storage | ~$0 (frontend is <1 MB) |
| **CloudWatch** | 5 GB logs | ~$0 (well below limit) |
| **Total** | | **~$0.00/month** |

*All free tier! No credit card charges for reasonable usage.*

---

## 🔗 Useful Links

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EventBridge Cron Syntax](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-cron-expressions.html)
- [DynamoDB Pricing](https://aws.amazon.com/dynamodb/pricing/on-demand/)
- [Polygon.io API Docs](https://polygon.io/docs/stocks) (or your chosen provider)

---

## 📄 License

This project is open source and available under the MIT License.

---

## 👤 Author

Built by YOU as part of a take-home project challenge.

### Notable Features You Own:

✅ **Complete Terraform setup** — no AWS console clicking  
✅ **Production-grade error handling** — API rate-limit protection  
✅ **Security best practices** — API keys in Codespace secrets  
✅ **Separation of concerns** — ingestion vs. retrieval decoupled  
✅ **Clean frontend** — vanilla JS, responsive, color-coded  
✅ **Comprehensive documentation** — this README!

---

## ❓ FAQ

**Q: How long does the project take?**  
A: ~2-4 hours end-to-end (architecture + coding + deployment).

**Q: Do I need AWS credits?**  
A: No, everything fits in the free tier. Verify at the end: check your AWS Billing Dashboard.

**Q: Can I use a different stock API?**  
A: Yes! The code uses a generic API interface. Swap in Finnhub, AlphaVantage, or Polygon.io.

**Q: What if the Lambda times out?**  
A: Increase the timeout in `terraform/lambda.tf`: `timeout = 60` (seconds).

**Q: Can I add more stocks to the watchlist?**  
A: Yes! Edit `terraform/variables.tf` → `watchlist` variable.

---

**Ready to impress recruiters? Deploy now and share the links! 🚀**
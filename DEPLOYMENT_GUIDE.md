# 🚀 Deployment & Live Demo Guide

Use this guide when deploying the project or running a live demo for recruiters.

---

## ✅ Pre-Demo Checklist (Do This 15 Minutes Before)

### 1. Verify AWS Resources Exist
```bash
# Check DynamoDB table exists
aws dynamodb describe-table --table-name stock_movers --region us-east-1

# Check Lambda functions exist
aws lambda list-functions --region us-east-1 | grep stocks-pipeline

# Check S3 bucket has website enabled
aws s3 website s3://stocks-pipeline-frontend-YOUR_ACCOUNT_ID
```

### 2. Verify Codespace Secrets Are Set

```bash
# Confirm stock API key is accessible
gh secret get STOCK_API_KEY

# Should return: your-api-key-here (not an error)
```

### 3. Get All Output URLs (Save These!)

```bash
cd terraform

# These are your live URLs:
echo "Frontend URL: $(terraform output -raw frontend_url)"
echo "API Endpoint: $(terraform output -raw api_endpoint)"
echo "DynamoDB Table: $(terraform output -raw dynamodb_table_name)"
echo "Ingestion Lambda: $(terraform output -raw ingestion_lambda_name)"
```

### 4. Trigger Data Generation

```bash
# Manually invoke the ingestion Lambda (don't wait for nightly cron)
aws lambda invoke \
  --function-name $(terraform output -raw ingestion_lambda_name) \
  --region us-east-1 \
  /tmp/demo_result.json

# Check it succeeded (status should be 200)
cat /tmp/demo_result.json | jq .statusCode
```

### 5. Verify Frontend Can Display Data

```bash
# Test your API endpoint is working
curl $(terraform output -raw api_endpoint) | jq .

# Should return: { "movers": [...], "count": N }
```

---

## 🎬 Live Demo Script (For Recruiters)

### Start of Demo (2 minutes)

**Say This:**
> *"Let me walk you through what I built. This is a fully serverless stock market dashboard. Here's how it works:*
>
> *1. Every day at 4 PM Eastern Time, a scheduler wakes up (EventBridge).*  
> *2. It triggers a Lambda function that fetches stock prices.*  
> *3. Lambda calculates which stock moved the most that day.*  
> *4. The data is stored in DynamoDB.*  
> *5. A second Lambda serves this data via REST API.*  
> *6. The frontend (right here) fetches from that API and displays it.*  
> *7. Everything—infrastructure, code, deployment—is defined in Terraform. No clicking the AWS console.* **"

### Show the Live Frontend (1 minute)

**Click here:** `[paste frontend_url here]`

Say:
> *"This is the live dashboard. You can see the last 7 days of market movers. Green means the stock went up, red means down. This data is real—well, it's demo data, but it's being fetched from my DynamoDB table in AWS right now."*

### Show the API (1 minute)

**Open in a new tab:** `[paste api_endpoint here]`

Say:
> *"This is the REST API endpoint. It returns JSON with the 7-day history. The frontend fetches from here. Let me show you the Lambda code that powers this..."*

### Show the Terraform (1 minute)

**Open:** `terraform/main.tf` (in your editor)

Say:
> *"This is how I defined the infrastructure. No manual creation. Every resource—the Lambda, the DynamoDB table, the API Gateway, the S3 bucket, the EventBridge scheduler—all defined here. When I run `terraform apply`, it creates everything for me. This means:*
>
> - *I can recreate this environment in 5 minutes if needed.*
> - *The code is version-controlled, reviewable, repeatable.*
> - *New team members can deploy the full stack without any ambiguity.* **"

### Show Error Handling (30 seconds)

**Open:** `lambdas/ingestion/handler.py` → Show try/except blocks

Say:
> *"If the stock API fails or rate-limits, the Lambda doesn't crash. It logs the error, continues processing other stocks, and returns a graceful response. This is important for production reliability."*

### Show Security Approach (1 minute)

**Terminal:**
```bash
# Show that secrets are NOT in the code
grep -r "STOCK_API_KEY" . --exclude-dir=.git | head -5

# Should show: environment variables only, not hardcoded values
```

Say:
> *"The API key is stored in GitHub Codespace secrets—not in code, not in .env files committed to Git. It's encrypted at rest and automatically available to my Lambda functions via Terraform. This is how me production teams handle secrets."*

### Wrap Up (1 minute)

Say:
> *"The entire architecture—from data ingestion to visualization—is serverless. No servers to manage, no uptime worries, and it costs about a nickel a month. More importantly, it demonstrates:"*
>
> - **Architectural thinking:** Clean separation of concerns (ingestion vs. retrieval)
> - **Cloud fluency:** Lambda, DynamoDB, EventBridge, API Gateway, S3
> - **DevOps mindset:** Everything as code, zero manual steps
> - **Production-grade practices:** Error handling, security, logging
>
> *"Questions?"*

---

## 🐛 Troubleshooting During Demo

### Problem: Frontend Shows "Error: Failed to fetch /movers"

**Quick Fix:**
```bash
# 1. Get correct API URL
API_URL=$(terraform output -raw api_endpoint)
echo "Update frontend with: $API_URL"

# 2. Edit frontend/index.html, find this line (around line 150):
#    const API_URL = "https://...";
# Replace with your correct API_URL

# 3. Redeploy
BUCKET=$(terraform output -raw frontend_bucket_name)
aws s3 cp frontend/index.html s3://$BUCKET/

# 4. Hard-refresh frontend in browser (Ctrl+Shift+R)
```

### Problem: API Returns Empty Movers `{ "movers": [] }`

**This means:**
- DynamoDB table is empty (no data from ingestion Lambda)

**Quick Fix:**
```bash
# Manually trigger ingestion
aws lambda invoke \
  --function-name $(terraform output -raw ingestion_lambda_name) \
  --region us-east-1 \
  /tmp/invoke_result.json

# Wait 5 seconds, then refresh frontend
```

### Problem: "404 Lambda Not Found"

**Cause:** Lambda wasn't deployed properly

**Fix:**
```bash
cd terraform
terraform apply -var="stock_api_key=$STOCK_API_KEY"
```

---

## 📋 Demo Timing

| Part | Duration | What to Show |
|------|----------|-------------|
| Intro | 30 sec | One-liner pitch |
| Live Frontend | 45 sec | Dashboard + explaining the flow |
| API Endpoint | 30 sec | JSON response |
| Terraform Code | 1 min | main.tf, lambda.tf, eventbridge.tf |
| Error Handling | 30 sec | try/except blocks |
| Security | 45 sec | Codespace secrets explanation |
| Wrap-up | 1 min | Key takeaways + Q&A |
| **Total** | **~5 min** | |

---

## 🎤 Recruiter Q&A Prep

**Q: Why EventBridge instead of a Lambda scheduled via CloudWatch?**

A: EventBridge is more flexible and decoupled. It's AWS's event bus—designed for this use case. Plus, it's cleaner to manage complex rules and integrations in the future.

---

**Q: Why DynamoDB instead of RDS/PostgreSQL?**

A: DynamoDB is serverless (auto-scales), costs ~$0 for our traffic, and I don't need complex joins. If we had complex queries, RDS would make sense. But for a simple key-value store (date + ticker), DynamoDB is perfect.

---

**Q: What happens if the stock API is down?**

A: The Lambda has a try/except block. If it fails, it logs the error, skips that stock, tries the next one. Returns a graceful error message. The previous day's data is still in DynamoDB. In production, I'd add retry logic with exponential backoff.

---

**Q: How would you scale this to 1000 stocks?**

A: 
- **Batch fetch:** Instead of sequential API calls, use async/concurrent requests
- **Wider window:** Cache stock data from the previous day, only fetch deltas
- **DynamoDB optimization:** Add a GSI on ticker for faster lookups
- **Caching layer:** Add CloudFront or ElastiCache to cache API responses
- **Lambda parallelism:** Terraform `reserved_concurrent_executions` to control cost

---

**Q: How would you monitor this in production?**

A:
- CloudWatch alarms for Lambda failures
- Dashboards showing daily movers, API latency
- SNS notifications for errors (email alerts)
- X-Ray tracing for debugging cold starts
- Cost monitoring (set billing alarms to not exceed $1/month)

---

**Q: Why not use a single Lambda instead of two?**

A: Separation of concerns. The ingestion Lambda's job is to fetch & write. The API Lambda's job is to retrieve & format. If ingestion fails, the API still works. If the API endpoint gets hammered, it doesn't slow down ingestion. Clean architecture.

---

## 🎁 Bonus: One-Liner Deployment

Once you're comfortable, memorize this:

```bash
git clone https://github.com/YOUR_USERNAME/stocks-serverless-pipeline.git && \
cd stocks-serverless-pipeline/terraform && \
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY) && \
terraform init && \
terraform apply -var="stock_api_key=$STOCK_API_KEY" -auto-approve && \
echo "✅ Deployed! Frontend: $(terraform output -raw frontend_url)"
```

This deploys everything in ~2 minutes. Impress them!

---

## 📸 Screenshot Guide

**What to screenshot for your portfolio:**

1. **Live Dashboard** (frontend URL)
   - Show the table of movers
   - Highlight the color coding (green/red)

2. **Terraform Code** (main.tf)
   - Show the clean structure
   - Highlight comments

3. **DynamoDB Data** (AWS CLI output)
   ```bash
   aws dynamodb scan --table-name stock_movers --region us-east-1 | jq '.Items[0:3]'
   ```

4. **API Response** (curl output)
   ```bash
   curl $(terraform output -raw api_endpoint) | jq .
   ```

5. **Logs** (CloudWatch)
   ```bash
   aws logs tail /aws/lambda/stocks-pipeline-ingestion --max-items 5
   ```

---

## ✨ Final Polish

**Before sharing:**

- [ ] Update `terraform/variables.tf` with your preferred watchlist
- [ ] Update `frontend/index.html` with your API endpoint
- [ ] Test the live URL in incognito mode (clear cache)
- [ ] Have Terraform outputs saved in a text file
- [ ] Rehearse the demo once (time yourself)
- [ ] Save a screenshot of the live frontend

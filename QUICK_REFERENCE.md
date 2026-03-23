# ⚡ Quick Reference Card

**Keep this open during your recruiter demo!**

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

## 🚀 Pre-Demo Checklist (5 min before)

```bash
# 1. Get API key
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)

# 2. Deploy fresh infrastructure
cd terraform
terraform init
terraform apply -var="stock_api_key=$STOCK_API_KEY"

# 3. Generate demo data (optional, but nice)
aws lambda invoke \
  --function-name $(terraform output -raw ingestion_lambda_name) \
  /tmp/demo.json

# 4. Test frontend works
curl $(terraform output -raw api_endpoint) | jq '.movers[0]'
```

---

## 📝 Demo Script (5 minutes)

| Time | What to Show | What to Say |
|------|-------------|------------|
| 0:30 | Intro | Serverless pipeline that wakes daily, fetches stocks, finds biggest mover |
| 1:15 | **Frontend URL** | "Here's the live dashboard. Real data from DynamoDB. Green = gain, Red = loss." |
| 1:45 | **API Endpoint** | "This is the REST API. Frontend fetches from here and renders it." |
| 2:45 | **Terraform code** (main.tf) | "No console clicking. Every resource defined in code. Repeatable, reviewable, version-controlled." |
| 3:15 | **Error handling** (handler.py) | "If API fails, Lambda doesn't crash. Try/except. Graceful degradation." |
| 4:00 | **Security** (Codespace Secrets) | "API key in GitHub Secrets, never in code. Encrypted. CI/CD ready." |
| 5:00 | **Wrap-up** | Key takeaways + Questions |

---

## 🎤 Recruiter Q&A (Memorize These!)

**Q: Why EventBridge?**  
A: Serverless scheduler. Runs at exact time. Perfect for daily batch jobs. Costs ~$0.10/month.

---

**Q: Why DynamoDB?**  
A: Serverless, auto-scales, pay-per-request. We don't need complex joins. ~$0/month for our traffic.

---

**Q: What if API is down?**  
A: Try/except block. Lambda logs error, skips that stock, continues. Returns graceful failure. Previous day's data still in DB.

---

**Q: Why two Lambdas?**  
A: Separation of concerns. Ingestion writes, API reads. They can scale independently. Clean architecture.

---

**Q: How scale to 1000 stocks?**  
A: Batch API calls (async), add GSI on ticker, CloudFront caching, Lambda reserved concurrency.

---

## 🔐 Codespace Secrets (One-Liner)

```bash
# First time: set secret
gh secret set STOCK_API_KEY

# Always: use it
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)
```

**Why?** Encrypted, never in shell history, works in CI/CD, perfect for demos.

---

## 🐛 Emergency Fixes (During Demo)

**"Frontend shows error"?**
```bash
# Update API URL in frontend/index.html
FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
aws s3 cp frontend/index.html s3://$FRONTEND_BUCKET/
# Hard refresh (Ctrl+Shift+R) in browser
```

**"API returns empty"?**
```bash
# Trigger ingestion (generate dummy data)
aws lambda invoke \
  --function-name $(terraform output -raw ingestion_lambda_name) \
  /tmp/invoke.json
# Refresh frontend
```

**"Lambda not found"?**
```bash
# Redeploy infrastructure
cd terraform
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

## 🎯 Key Talking Points

- ✅ **Architecture:** Serverless—no VMs, no uptime worries
- ✅ **DevOps:** Every resource as code—fully reproducible
- ✅ **Security:** Secrets encrypted, least-privilege IAM
- ✅ **Cost:** ~$0/month, within AWS free tier
- ✅ **Separation of Concerns:** Ingestion ≠ Retrieval ≠ Frontend
- ✅ **Error Handling:** Graceful failures, detailed logging

---

## 🔍 Files Recruiters Will Look At

1. **README.md** ← Most important (overview + commands)
2. **terraform/main.tf** (provider + general config)
3. **terraform/eventbridge.tf** (the daily trigger!)
4. **terraform/lambda.tf** (IAM roles, error handling)
5. **lambdas/ingestion/handler.py** (the logic)
6. **lambdas/api/handler.py** (REST response)
7. **frontend/index.html** (UI)
8. **.gitignore** (secrets not committed—good practice!)

---

## ⏱️ Timeline

| Phase | Time | Status |
|-------|------|--------|
| **Intro** | 0:00-0:30 | One-liner pitch |
| **Demo** | 0:30-2:00 | Frontend + API |
| **Code** | 2:00-3:15 | Show Terraform + error handling |
| **Discussion** | 3:15-5:00 | Security + Q&A |

---

## 💾 Bookmark These URLs

1. **Terraform Docs:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs
2. **AWS Lambda Docs:** https://docs.aws.amazon.com/lambda/
3. **DynamoDB Pricing:** https://aws.amazon.com/dynamodb/pricing/on-demand/
4. **Your GitHub Repo:** https://github.com/YOUR_USERNAME/stocks-serverless-pipeline

---

## ✨ Final Checklist (Right Before Presenting)

- [ ] API key imported: `echo $STOCK_API_KEY` (should not be empty)
- [ ] Infrastructure deployed: `terraform output` (shows 4+ outputs)
- [ ] Frontend accessible: Open URL in browser (shows table)
- [ ] API working: `curl API_ENDPOINT | jq .` (returns JSON)
- [ ] Code reviewed: You understand every line
- [ ] Practice script: You've rehearsed the 5-min demo
- [ ] Links saved: Have URLs in your notes
- [ ] Terminal ready: Clean, no sensitive data visible

---

**You're ready. Go impress them. 🚀**

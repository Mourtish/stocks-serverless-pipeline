# Stocks Serverless Pipeline

Concise, production-style serverless pipeline that finds the daily biggest stock mover from a watchlist and exposes a 7‑day history via a public API and static dashboard.

Why this repo matters: it demonstrates cloud architecture, Infrastructure-as-Code, and secure, cost-aware engineering practices you can interview on or reuse in real projects.

Highlights
- Event-driven ingestion (AWS EventBridge → Lambda)
- Data storage with DynamoDB (on‑demand)
- Public API (API Gateway → Lambda)
- Static dashboard hosted on S3
- Infrastructure fully defined in Terraform

Quick TL;DR
- Purpose: Run a daily batch that computes the single biggest intraday mover from a watchlist and stores the result.
- Intended audience: engineers, hiring managers, recruiters evaluating architecture and cloud/DevOps skills.

Repository layout (high level)
- `lambdas/ingestion`: daily ingestion Lambda (fetches OHLC, computes % change, writes DynamoDB)
- `lambdas/api`: API Lambda that returns the last 7 days of movers
- `frontend/index.html`: small SPA that visualizes results
- `terraform/`: all infrastructure (Lambda, DynamoDB, EventBridge, API Gateway, S3)

Tech stack
- Compute: AWS Lambda (Python)
- Scheduler: EventBridge cron rule
- Database: DynamoDB (PAY_PER_REQUEST)
- API: API Gateway (HTTP)
- Frontend: S3 static hosting
- IaC: Terraform

Quickstart (deploy to AWS)
Prerequisites: `terraform` (1.0+), AWS account with CLI configured, Python 3.9+ for packaging lambdas.

1. Review and set Terraform variables in `terraform/variables.tf` (region, watchlist, credentials).
2. Initialize and plan:

```bash
cd terraform
terraform init
terraform plan -out plan.tf
```

3. Apply (creates infra):

```bash
terraform apply "plan.tf"
```

4. After deploy, Terraform outputs include the API endpoint and S3 website URL.

Local development notes
- Run a handler locally for quick testing:

```bash
python3 lambdas/ingestion/handler.py    # unit-style invocation (depends on local env vars)
python3 lambdas/api/handler.py          # local invoke for quick checks
```

- Unit / integration: test the core logic in `lambdas/ingestion/handler.py` and `lambdas/api/handler.py`.

Security & operational notes (for reviewers)
- Secrets are not checked into Git — provide API keys via Terraform variables or CI secrets.
- IAM roles follow least‑privilege: ingestion has write-only to DynamoDB; API has read-only access.
- Designed for low cost (AWS Free Tier friendly) and graceful degradation on third‑party API failures.

Known limitations
- The ingestion pipeline currently uses a mock or placeholder data source in some branches; replace with your stock data provider (Polygon, Finnhub, AlphaVantage) and update request handling.
- The API currently scans and sorts small datasets in memory — acceptable for the demo scale. Add a GSI or query pattern for larger datasets.
- `frontend/index.html` contains a hardcoded API URL placeholder — update after deployment or template during CI.

Notes for recruiters / reviewers
- Look in `terraform/` for IaC best practices and modular resource definitions.
- `lambdas/` shows production-aware error handling, logging, and dependency vendoring for cold starts.
- The repo is designed to showcase cloud architecture thinking and secure, repeatable deployments.


License
- MIT






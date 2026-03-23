# 🔐 Secret Management: GitHub Codespace Secrets

This guide describes the secret management strategy and implementation for this project.

---

## S3 Website URL Generation

Once deployed, the S3 website URL remains permanent for the deployment lifetime.

**The S3 URL Format:**
```
http://stocks-pipeline-frontend-<YOUR_AWS_ACCOUNT_ID>.s3-website-us-east-1.amazonaws.com
```

- This URL **never changes** as long as the S3 bucket exists
- You can share it repeatedly
- It doesn't "expire" (unless you delete the bucket)
- It's public (anyone with the URL can view it)

**When You'd Get a NEW Link:**
- If you delete the S3 bucket and recreate it (new account ID)
- If you deploy to a different region
- If you use CloudFront (would get a unique CloudFront domain)

**So:** Deploy once, share the same link forever! ✅

---

## Secret Storage Strategy

### Encrypted Secret Storage

GitHub Codespace Secrets provide encrypted secret management suitable for development environments.

**Security Properties:**
- Encrypted at rest
- Decrypted only on retrieval
- Not transmitted to logs
- No file system exposure

---

## Setup: GitHub Codespace Secrets

### Install GitHub CLI

```bash
gh --version

# If not installed:
curl -fsSL https://cli.github.com/install.sh | bash
```

### Authenticate with GitHub

```bash
gh auth login

# Follow prompts to authorize
```

### Store Stock API Key

```bash
# Retrieve API key from stock data provider
# Then store in Codespace Secrets:

gh secret set STOCK_API_KEY

# Paste key value (input not echoed to terminal)
```

### Verify Storage

```bash
gh secret get STOCK_API_KEY

# Output: Key value or first characters only
```

### Deploy with Secret

```bash
# Load secret into current shell session
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)

# Navigate to infrastructure code
cd terraform

# Deploy with secret passed as Terraform variable
terraform apply -var="stock_api_key=$STOCK_API_KEY"
```

---

## Comparison: Secret Storage Methods

### Method 1: Hardcoded in Source Code

```python
# Not recommended
STOCK_API_KEY = "pk_xxxxxxxxxxxxxx"
```

**Issues:**
- Exposed in version control history
- Accessible to anyone with repository access  
- Difficult to rotate without code changes

---

### Method 2: .env File

```bash
# .env (local only, never committed)
STOCK_API_KEY=pk_xxxxxxxxxxxxxx
```

**Issues:**
- Easy to accidentally commit to version control
- Requires manual file creation on new machines
- Not suitable for CI/CD integration
- Shell commands expose key in plain text: `cat .env` or `export $(cat .env | xargs)`

---

### Method 3: Direct Environment Variable Export

```bash
export STOCK_API_KEY="pk_xxxxxxxxxxxxxx"
```

**Issues:**
- Key visible in shell history (`history | grep STOCK`)
- Exposed in process list inspection (`ps aux`)
- Does not persist across session restarts
- Not suitable for CI/CD integration

---

### Method 4: GitHub Codespace Secrets (Selected)

```bash
gh secret set STOCK_API_KEY
```

**Characteristics:**
- Encrypted storage at rest
- No accidental commits possible
- Works with CI/CD pipelines
- Persists across session restarts
- Easy rotation via same command
- No additional cost
- Built into GitHub platform

---

## Deployment Workflow

### Initial Deployment

```bash
# 1. Load secret into shell session
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)

# 2. Deploy infrastructure
cd terraform
terraform init
terraform apply -var="stock_api_key=$STOCK_API_KEY"

# 3. Capture outputs
terraform output
```

### Cleanup

```bash
# Remove deployed resources
cd terraform
terraform destroy -var="stock_api_key=$STOCK_API_KEY"

# Secret remains stored for future deployments
```

## Secret Rotation

**If API key is compromised:**

```bash
# 1. Obtain new key from provider

# 2. Update secret
gh secret set STOCK_API_KEY

# 3. Redeploy
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)
cd terraform
terraform apply -var="stock_api_key=$STOCK_API_KEY"

# Previous key is now invalid
```

---

## Full Setup Sequence

```bash
# Clone repository
git clone https://github.com/Mourtish/stocks-serverless-pipeline.git
cd stocks-serverless-pipeline

# Create or open Codespace
gh codespace create

# Authenticate (if needed)
gh auth login

# Store secret
gh secret set STOCK_API_KEY

# Verify
gh secret get STOCK_API_KEY

# Deploy
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)
cd terraform
terraform init
terraform apply -var="stock_api_key=$STOCK_API_KEY"

# View outputs
terraform output
```

## Best Practices

### ❌ Never: Hardcode Credentials in Terraform

```hcl
variable "stock_api_key" {
  default = "pk_xxxxx"  # Not recommended
}
```

---

### ❌ Never: Commit Secrets to .env

```bash
echo "STOCK_API_KEY=pk_xxxxx" > .env
git add .env  # Exposes secret permanently
```

---

### ✅ Always: Use Terraform Variables with Sensitive Flag and Environment Variables

```hcl
variable "stock_api_key" {
  description = "API key (passed via environment variable)"
  type        = string
  sensitive   = true  # Prevents logging
}
```

```bash
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)
terraform apply -var="stock_api_key=$STOCK_API_KEY"
```

---

## Troubleshooting

**Issue: `gh secret get STOCK_API_KEY` does not return a value**

Ensure the secret was set first with `gh secret set STOCK_API_KEY`.

---

**Issue: `gh: command not found`**

Install GitHub CLI:

```bash
curl -fsSL https://cli.github.com/install.sh | bash
```

---

**Issue: `Error: variable stock_api_key was not provided`**

Verify the secret is exported:

```bash
echo $STOCK_API_KEY  # Should display key value

# If empty, export it:
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)

# Then retry Terraform:
terraform apply -var="stock_api_key=$STOCK_API_KEY"
```

---

## Summary

| Question | Answer |
|----------|--------|
| Secret storage method | GitHub Codespace Secrets |
| Encryption | Yes, at rest and in transit |
| Cost | Free (included with GitHub) |
| Terraform integration | Yes, via environment variables |
| S3 URL persistence | Permanent once deployed |
| Secret exposure to users | No exposure, users see only frontend |
| Key rotation | `gh secret set STOCK_API_KEY` |
| Deploy time | ~2 minutes after setup

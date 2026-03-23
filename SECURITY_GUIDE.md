# 🔐 GitHub Codespace Secrets & Security Strategy

This guide explains **why** storing API keys in GitHub Codespace Secrets is ideal for development + live demos, and how to use them.

---

## ❓ "Do I Always Need to Generate the Website Link?"

**Short Answer:** No. Once deployed, the S3 website URL is **permanent** for that deployment.

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

## 🚀 Why GitHub Codespace Secrets Are Perfect

### The Problem: Where Do You Store API Keys?

| Method | Security | Ease | CI/CD | Demo | Cost |
|--------|----------|------|-------|------|------|
| **Hardcoded** | ❌ BROKEN | ✅✅ | ❌ | ✅ | $ |
| **.env file** | ⚠️ Easy to leak | ✅ | ❌ | ❌ | $ |
| **Export ENV vars** | ⚠️ Shell history | ✅ | ⚠️ | ⚠️ | $ |
| **AWS Secrets Mgr** | ✅✅ | ❌ | ✅ | ❌ | $$ |
| **GitHub Secrets** | ✅✅ | ✅✅ | ✅✅ | ✅ | $ |

### GitHub Codespace Secrets: The Perfect Sweet Spot

**✅ SECURE:**
- Encrypted at rest
- Only decrypted when you use them
- Never printed to logs
- Can't be extracted by reading files

**✅ CONVENIENT:**
- Access from terminal: `gh secret get STOCK_API_KEY`
- Automatically available to GitHub Actions
- Persists across Codespace restarts
- One place to manage all secrets

**✅ LIVE DEMO FRIENDLY:**
- You have the secret in your Codespace environment
- Deploy to AWS in real-time
- Show recruiters the live website
- They verify it's actually running

**✅ CHEAP:**
- Free (part of GitHub)
- No AWS bill for secret storage

---

## 🔧 How to Set Up Codespace Secrets

### Step 1: Install GitHub CLI (if not already installed)

```bash
gh --version

# If not installed:
curl -fsSL https://cli.github.com/install.sh | bash
```

### Step 2: Authenticate with GitHub

```bash
gh auth login

# Follow prompts:
# - What account? → YOUR_USERNAME
# - Protocol? → HTTPS
# - Authenticate? → yes (opens browser)
# - Approve? → yes (in browser)
```

### Step 3: Store Your Stock API Key

```bash
# Get your API key from your provider (Polygon.io, Finnhub, etc.)
# Then:

gh secret set STOCK_API_KEY

# Prompts for value. Paste your key (won't be visible).
# Press Enter when done.
```

### Step 4: Verify It's Stored

```bash
gh secret get STOCK_API_KEY

# Should print: your-api-key-here (or first few chars)
```

### Step 5: Use in Your Deployment

```bash
# Codespace Secrets are automatically available to your shell
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)

# Deploy with Terraform
cd terraform
terraform apply -var="stock_api_key=$STOCK_API_KEY"
```

---

## 💡 Why This Beats Other Methods

### ❌ Don't Do This: Hardcode in Source

```python
# ❌ BAD
STOCK_API_KEY = "pk_xxxxxxxxxxxxxx"
```

**Problem:** Anyone who clones the repo has your key. You can't push to GitHub.

---

### ❌ Don't Do This: .env File

```bash
# .env (local only, never commit)
STOCK_API_KEY=pk_xxxxxxxxxxxxxx
```

**Problem:** 
- Easy to accidentally commit (oops!)
- Doesn't work in CI/CD
- Have to recreate .env manually on new machine

**Terminal will show:**
```bash
cat .env  # Shows your key in plain text!
export $(cat .env | xargs)  # Key in shell history!
```

---

### ⚠️ Don't Do This: Export via Command Line

```bash
export STOCK_API_KEY="pk_xxxxxxxxxxxxxx"
```

**Problem:**
- Key visible in **shell history** (`history | grep STOCK`)
- Key in **process list** (`ps aux | grep shell`)
- Doesn't persist across terminal restarts

---

### ✅ DO THIS: GitHub Codespace Secrets

```bash
gh secret set STOCK_API_KEY
# Stored securely, encrypted, zero shell history exposure
```

**Advantages:**
- Zero risk of accidental commits
- Works in CI/CD pipelines
- Persists across Codespace restarts
- Easily rotatable
- GitHub manages encryption

---

## 🎬 Workflow: Deploy + Demo for Recruiters

### 1. Before the Demo (5 minutes)

```bash
# Your secret is already in Codespace (auto-available)
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)

# Navigate to project
cd ~/stocks-serverless-pipeline

# Deploy fresh infrastructure
cd terraform
terraform init
terraform apply -var="stock_api_key=$STOCK_API_KEY"

# Save outputs
terraform output > /tmp/demo_outputs.txt
cat /tmp/demo_outputs.txt
```

### 2. During the Demo (Show the Live Link)

```bash
# No secrets exposed to recruiters
terraform output -raw frontend_url

# Copy that URL and share it
# Example: http://stocks-pipeline-frontend-123456789.s3-website-us-east-1.amazonaws.com
```

Recruiters visit the link in their browsers and see:
- ✅ Your live frontend is running
- ✅ Data is being fetched from your API  
- ✅ Everything is real (deployed to actual AWS)
- ❌ They don't see your API key
- ❌ They don't see your AWS credentials

### 3. After the Demo

```bash
# When ready to clean up:
terraform destroy -var="stock_api_key=$STOCK_API_KEY"

# Your secret is still safely stored for next deployment
```

---

## 🔄 Rotation: When Your API Key Gets Compromised

**If your stock API key leaks (shouldn't, but just in case):**

```bash
# 1. Get a new key from your provider

# 2. Update the secret
gh secret set STOCK_API_KEY
# Paste new key

# 3. Redeploy (uses new key automatically)
cd terraform
terraform apply -var="stock_api_key=$(gh secret get STOCK_API_KEY)"

# 4. Old key is now useless (you've rotated it)
```

---

## 📊 Comparison Table: 4 Common Approaches

| Approach | Codespace Secrets | AWS Secrets Mgr | .env File | Hardcode |
|----------|-------------------|-----------------|-----------|----------|
| **Secure?** | ✅ Yes | ✅ Yes | ⚠️ High risk | ❌ No |
| **Free?** | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes |
| **Shell history?** | ✅ Safe | ✅ Safe | ❌ Exposed | ❌ Exposed |
| **Works in CI/CD?** | ✅ Yes | ✅ Yes | ⚠️ Manual | ❌ No |
| **Git-safe?** | ✅ Yes | ✅ Yes | ⚠️ Easy to leak | ❌ No |
| **Survives restart?** | ✅ Yes | ✅ Yes | ❌ No | ✅ Yes |
| **For Live Demos?** | ✅ Perfect | ⚠️ Extra setup | ❌ Manual | ❌ Too risky |

---

## 🎯 Complete Secure Deployment Workflow

### First Time Setup

```bash
# 1. Clone repo
git clone https://github.com/YOUR_USERNAME/stocks-serverless-pipeline.git
cd stocks-serverless-pipeline

# 2. Open in Codespace (or already using one)
gh codespace create

# 3. Authenticate with GitHub (if not already done)
gh auth login

# 4. Store your secret
gh secret set STOCK_API_KEY
# Paste: pk_xxxxxxxxxxxxxx

# 5. Verify it works
gh secret get STOCK_API_KEY
# Output: pk_xxxxxxxxxxxxxx

# 6. Deploy
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)
cd terraform
terraform init
terraform apply -var="stock_api_key=$STOCK_API_KEY"

# 7. Get your links
terraform output

# Copy and share:
# - frontend_url (public S3 link - never changes)
# - api_endpoint (REST API - never changes)
```

### Future Deployments (Same as Above)

```bash
# Secret is already stored! Just:
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)
cd terraform
terraform apply -var="stock_api_key=$STOCK_API_KEY"
```

---

## 🚨 What NOT To Do

### ❌ Never do this:

```bash
# DON'T hardcode in Terraform:
variable "stock_api_key" {
  default = "pk_xxxxx"  # ❌ BAD!
}

# DON'T commit to .gitignore (defeats the purpose):
echo "STOCK_API_KEY=pk_xxxxx" > .env
git add .env  # ❌ NEVER!

# DON'T export hard-coded to shell:
export STOCK_API_KEY="pk_xxxxx"  # ❌ Shell history!
history | grep STOCK_API_KEY  # Oops, it's visible!

# DON'T pass as command-line argument:
terraform apply -var="stock_api_key=pk_xxxxx"  # ❌ Terminal history!
```

### ✅ Always do this:

```bash
# ✅ Use Codespace Secrets
gh secret set STOCK_API_KEY

# ✅ Reference in Terraform
variable "stock_api_key" {
  description = "API key (set via environment variable)"
  type        = string
  sensitive   = true
}

# ✅ Export from secret (zero history exposure)
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)

# ✅ Pass to Terraform
terraform apply -var="stock_api_key=$STOCK_API_KEY"

# ✅ Ship to AWS securely
# Terraform doesn't print the key; it's marked as "sensitive"
```

---

## 🎓 Why Recruiters Appreciate This

When you explain this approach, here's what they hear:

> *"I understand security best practices. I use encryption, environment variables, and encrypted secret storage. I don't hardcode credentials. I understand how CI/CD pipelines work. I've thought about rotation and compromise scenarios."*

This is **exactly** what production teams do.

---

## 🆘 Troubleshooting

**Problem: `gh secret get STOCK_API_KEY` returns nothing**

```bash
# Secret not set. Set it:
gh secret set STOCK_API_KEY
```

---

**Problem: `gh: command not found`**

```bash
# Install GitHub CLI
curl -fsSL https://cli.github.com/install.sh | bash

# Or on macOS:
brew install gh
```

---

**Problem: `Error: variable stock_api_key was not provided`**

```bash
# You didn't export the variable before running terraform
export STOCK_API_KEY=$(gh secret get STOCK_API_KEY)
echo $STOCK_API_KEY  # Verify it's set

# Then retry:
terraform apply -var="stock_api_key=$STOCK_API_KEY"
```

---

## 📝 Summary

| Question | Answer |
|----------|--------|
| Where do I store API keys? | GitHub Codespace Secrets |
| Is it secure? | Yes, encrypted at rest, safe from history |
| Is it free? | Yes |
| Does it work with Terraform? | Yes (`-var="key=$STOCK_API_KEY"`) |
| Can I use it for live demos? | Yes, deploy fresh instance in 2 minutes |
| Will the website link change? | No, S3 URL is permanent |
| Can recruiters see my secret? | No, they only see the public frontend URL |
| What if my key leaks? | Rotate via `gh secret set STOCK_API_KEY` |

---

## 🎉 You're Now Secure!

Go. Deploy. Demo. Impress them. 🚀

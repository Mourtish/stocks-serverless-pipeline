# ============================================
# This tells Terraform we are using AWS
# and specifies the minimum versions needed
# ============================================
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================
# This configures the AWS provider
# It reads your credentials from environment
# variables automatically (AWS_ACCESS_KEY_ID
# and AWS_SECRET_ACCESS_KEY)
# ============================================
provider "aws" {
  region = var.aws_region
}
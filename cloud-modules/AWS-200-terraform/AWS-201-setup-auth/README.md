# AWS-201: AWS Setup & Authentication

**Course**: AWS-200 AWS with Terraform  
**Module**: AWS-201  
**Duration**: 1 hour  
**Prerequisites**: TF-100 series (Terraform Fundamentals)  
**Difficulty**: Intermediate

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [AWS Account Setup](#aws-account-setup)
4. [AWS CLI Installation](#aws-cli-installation)
5. [IAM Configuration for Terraform](#iam-configuration-for-terraform)
6. [Terraform AWS Provider](#terraform-aws-provider)
7. [Authentication Methods](#authentication-methods)
8. [Best Practices](#best-practices)
9. [Hands-On Labs](#hands-on-labs)
10. [Troubleshooting](#troubleshooting)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course teaches you how to set up AWS access for Terraform. You'll learn to configure the AWS CLI, create IAM credentials with least-privilege permissions, and configure the Terraform AWS provider using multiple authentication methods.

### What You'll Build

By the end of this course, you'll be able to:
- Create and configure an AWS account for Terraform use
- Install and configure the AWS CLI
- Create IAM users and roles with appropriate permissions
- Configure the Terraform AWS provider
- Use multiple authentication methods securely

### Course Structure

```
AWS-201-setup-auth/
├── README.md                          # This file
└── example/
    ├── provider.tf                    # AWS provider configuration
    ├── variables.tf                   # Input variables
    └── versions.tf                    # Version constraints
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Set Up AWS Account**
   - Create an AWS account
   - Enable MFA for root account
   - Understand AWS account structure

2. **Configure AWS CLI**
   - Install AWS CLI v2
   - Configure named profiles
   - Use multiple accounts/regions

3. **Create IAM Resources**
   - Create IAM users for Terraform
   - Assign least-privilege permissions
   - Generate and manage access keys

4. **Configure Terraform Provider**
   - Write AWS provider configuration
   - Use environment variables
   - Configure multiple regions

5. **Apply Security Best Practices**
   - Never hardcode credentials
   - Use IAM roles where possible
   - Rotate access keys regularly

---

## 🔑 AWS Account Setup

### Creating an AWS Account

1. Go to [aws.amazon.com](https://aws.amazon.com)
2. Click "Create an AWS Account"
3. Follow the registration process
4. Enable MFA on the root account immediately

### Root Account Security

**CRITICAL**: Secure your root account immediately:

```bash
# Root account best practices:
# 1. Enable MFA (Multi-Factor Authentication)
# 2. Never use root for day-to-day operations
# 3. Create an admin IAM user instead
# 4. Store root credentials securely
```

### AWS Free Tier

AWS offers a free tier for new accounts:
- **12 months free**: EC2 t2.micro, S3 5GB, RDS db.t2.micro
- **Always free**: Lambda 1M requests/month, DynamoDB 25GB
- **Free trials**: Various services for 30-90 days

> ⚠️ **Cost Warning**: Always monitor your AWS costs. Set up billing alerts to avoid unexpected charges.

### Setting Up Billing Alerts

```bash
# Create a billing alarm via AWS CLI
aws cloudwatch put-metric-alarm \
  --alarm-name "BillingAlert" \
  --alarm-description "Alert when monthly charges exceed $10" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT_ID:BillingAlerts
```

---

## 💻 AWS CLI Installation

### Install AWS CLI v2

#### Linux/macOS
```bash
# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# macOS
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

#### Windows
```powershell
# Download and install AWS CLI v2 MSI
# https://awscli.amazonaws.com/AWSCLIV2.msi
# Or use winget:
winget install Amazon.AWSCLI
```

### Verify Installation
```bash
aws --version
# aws-cli/2.x.x Python/3.x.x ...
```

### Configure AWS CLI

```bash
# Basic configuration
aws configure

# You'll be prompted for:
# AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Default region name: us-east-1
# Default output format: json
```

### Named Profiles

Use named profiles for multiple accounts:

```bash
# Configure a named profile
aws configure --profile terraform-dev

# Use a specific profile
aws s3 ls --profile terraform-dev

# Set default profile
export AWS_PROFILE=terraform-dev
```

Configuration files:
```ini
# ~/.aws/credentials
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[terraform-dev]
aws_access_key_id = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY

# ~/.aws/config
[default]
region = us-east-1
output = json

[profile terraform-dev]
region = eu-west-1
output = json
```

---

## 👤 IAM Configuration for Terraform

### Creating an IAM User for Terraform

#### Via AWS Console

1. Go to IAM → Users → Create User
2. Name: `terraform-user`
3. Access type: Programmatic access
4. Attach policies (see below)
5. Download credentials CSV

#### Via AWS CLI

```bash
# Create IAM user
aws iam create-user --user-name terraform-user

# Create access key
aws iam create-access-key --user-name terraform-user

# Attach policy
aws iam attach-user-policy \
  --user-name terraform-user \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

### IAM Policies for Terraform

#### Minimal Policy (Least Privilege)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*",
        "s3:*",
        "iam:GetRole",
        "iam:GetPolicy",
        "iam:ListRoles"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Terraform State Backend Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-terraform-state",
        "arn:aws:s3:::my-terraform-state/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
    }
  ]
}
```

### IAM Roles (Preferred for EC2/CI-CD)

```hcl
# Create IAM role for EC2 instances running Terraform
resource "aws_iam_role" "terraform_role" {
  name = "terraform-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_policy" {
  role       = aws_iam_role.terraform_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}
```

---

## ⚙️ Terraform AWS Provider

### Basic Provider Configuration

```hcl
# versions.tf
terraform {
  required_version = ">= 1.14"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# provider.tf
provider "aws" {
  region = var.aws_region
}
```

### Variables for Provider

```hcl
# variables.tf
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-central-1",
      "ap-southeast-1", "ap-northeast-1"
    ], var.aws_region)
    error_message = "Must be a valid AWS region."
  }
}
```

### Multiple Region Configuration

```hcl
# Primary region
provider "aws" {
  region = "us-east-1"
  alias  = "primary"
}

# Secondary region
provider "aws" {
  region = "eu-west-1"
  alias  = "secondary"
}

# Use specific provider
resource "aws_instance" "primary_server" {
  provider = aws.primary
  # ...
}

resource "aws_instance" "secondary_server" {
  provider = aws.secondary
  # ...
}
```

### Default Tags

```hcl
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Owner       = var.owner
    }
  }
}
```

---

## 🔐 Authentication Methods

### Method 1: Environment Variables (Recommended for CI/CD)

```bash
# Set credentials as environment variables
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"

# Run Terraform
terraform plan
```

### Method 2: AWS CLI Profile

```hcl
# Use a named profile
provider "aws" {
  region  = "us-east-1"
  profile = "terraform-dev"
}
```

### Method 3: IAM Role (Best for EC2/ECS/Lambda)

```hcl
# Assume a role
provider "aws" {
  region = "us-east-1"
  
  assume_role {
    role_arn     = "arn:aws:iam::ACCOUNT_ID:role/TerraformRole"
    session_name = "TerraformSession"
  }
}
```

### Method 4: AWS Vault (Most Secure for Local Dev)

```bash
# Install aws-vault
brew install aws-vault  # macOS

# Add credentials to vault
aws-vault add terraform-dev

# Run Terraform with vault
aws-vault exec terraform-dev -- terraform plan
```

### Authentication Priority

Terraform checks credentials in this order:
1. Static credentials in provider block (❌ Never use)
2. Environment variables (`AWS_ACCESS_KEY_ID`, etc.)
3. Shared credentials file (`~/.aws/credentials`)
4. AWS CLI config file (`~/.aws/config`)
5. Container credentials (ECS task role)
6. Instance profile (EC2 instance role)

---

## ✅ Best Practices

### 1. Never Hardcode Credentials

❌ **NEVER DO THIS**:
```hcl
provider "aws" {
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}
```

✅ **DO THIS INSTEAD**:
```hcl
provider "aws" {
  region = var.aws_region
  # Credentials from environment variables or IAM role
}
```

### 2. Use Least Privilege

Only grant permissions that Terraform actually needs:
```json
{
  "Effect": "Allow",
  "Action": ["ec2:Describe*", "ec2:Create*"],
  "Resource": "*"
}
```

### 3. Use Remote State

```hcl
terraform {
  backend "s3" {
    bucket       = "my-terraform-state"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true  # S3 native locking (Terraform 1.11+) — replaces DynamoDB

    # DEPRECATED: dynamodb_table = "terraform-state-lock"
    # DynamoDB locking is deprecated in Terraform 1.11+. Use use_lockfile = true instead.
  }
}
```

### 4. Tag Everything

```hcl
provider "aws" {
  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
      CostCenter  = "engineering"
    }
  }
}
```

### 5. Use Version Constraints

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"  # Allow 6.x but not 7.x
    }
  }
}
```

---

## 🔬 Hands-On Labs

### Lab 1: AWS CLI Setup (15 minutes)

**Objective**: Install and configure the AWS CLI with a Terraform-specific profile.

**Tasks**:
1. Install AWS CLI v2
2. Create an IAM user named `terraform-lab`
3. Attach `PowerUserAccess` policy
4. Generate access keys
5. Configure a named profile `terraform-lab`
6. Verify with `aws sts get-caller-identity`

**Expected Output**:
```json
{
  "UserId": "AIDAIOSFODNN7EXAMPLE",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/terraform-lab"
}
```

---

### Lab 2: Provider Configuration (15 minutes)

**Objective**: Create a Terraform configuration with proper AWS provider setup.

**Tasks**:
1. Create `versions.tf` with version constraints
2. Create `provider.tf` with AWS provider
3. Create `variables.tf` with region variable
4. Run `terraform init`
5. Run `terraform validate`
6. Test with `terraform plan`

**Expected Output**:
- Successful `terraform init` with AWS provider downloaded
- `terraform validate` passes
- `terraform plan` shows no changes (empty config)

---

### Lab 3: Remote State Setup (20 minutes)

**Objective**: Configure S3 backend for Terraform state.

**Tasks**:
1. Create S3 bucket for state storage
2. Create DynamoDB table for state locking
3. Configure S3 backend in Terraform
4. Migrate local state to S3
5. Verify state is stored in S3

**Expected Output**:
- S3 bucket created with versioning enabled
- DynamoDB table created for locking
- State file visible in S3 console
- `terraform state list` works with remote state

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Credentials Not Found

**Problem**: `NoCredentialProviders: no valid providers in chain`

**Solution**:
```bash
# Check credentials are configured
aws configure list

# Verify credentials work
aws sts get-caller-identity

# Check environment variables
echo $AWS_ACCESS_KEY_ID
```

#### 2. Region Not Set

**Problem**: `MissingRegion: could not find region configuration`

**Solution**:
```bash
# Set region in environment
export AWS_DEFAULT_REGION=us-east-1

# Or in provider
provider "aws" {
  region = "us-east-1"
}
```

#### 3. Permission Denied

**Problem**: `AccessDenied: User is not authorized to perform: ec2:DescribeInstances`

**Solution**:
```bash
# Check current identity
aws sts get-caller-identity

# Check attached policies
aws iam list-attached-user-policies --user-name terraform-user
```

#### 4. Provider Version Conflict

**Problem**: `Error: Failed to query available provider packages`

**Solution**:
```bash
# Clear provider cache
rm -rf .terraform
terraform init -upgrade
```

---

## 📝 Checkpoint Quiz

### Question 1: Authentication Priority
**What is the recommended way to provide AWS credentials to Terraform in a CI/CD pipeline?**

A) Hardcode in provider block  
B) Environment variables  
C) Shared credentials file  
D) Command-line flags

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Environment variables**

Explanation: Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) are the recommended approach for CI/CD pipelines as they can be injected securely by the CI/CD system without being stored in code.
</details>

---

### Question 2: IAM Best Practices
**What principle should guide IAM permissions for Terraform?**

A) Grant administrator access for simplicity  
B) Least privilege - only what Terraform needs  
C) Read-only access is sufficient  
D) Use root account credentials

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Least privilege - only what Terraform needs**

Explanation: The principle of least privilege means granting only the minimum permissions required. For Terraform, this means only the permissions needed to create, read, update, and delete the specific resources in your configuration.
</details>

---

### Question 3: Provider Configuration
**How do you configure the AWS provider to use a specific named profile?**

A) `profile = "name"` in provider block  
B) `aws_profile = "name"` variable  
C) `--profile name` CLI flag  
D) `AWS_PROFILE=name` only

<details>
<summary>Click to reveal answer</summary>

**Answer: A) `profile = "name"` in provider block**

```hcl
provider "aws" {
  region  = "us-east-1"
  profile = "terraform-dev"
}
```
</details>

---

### Question 4: Default Tags
**What is the benefit of using `default_tags` in the AWS provider?**

A) Faster resource creation  
B) Automatic tagging of all resources  
C) Reduced AWS costs  
D) Better performance

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Automatic tagging of all resources**

Explanation: `default_tags` in the AWS provider automatically applies specified tags to all resources created by that provider, ensuring consistent tagging without repeating tags in every resource block.
</details>

---

### Question 5: Remote State
**Why should you use S3 for Terraform state in AWS?**

A) It's required by AWS  
B) Enables team collaboration and state locking  
C) Faster than local state  
D) Reduces costs

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Enables team collaboration and state locking**

Explanation: S3 backend with DynamoDB locking enables multiple team members to work with the same infrastructure safely, preventing concurrent modifications that could corrupt state.
</details>

---

### Question 6: Version Constraints
**What does `version = "~> 6.0"` mean for the AWS provider?**

A) Exactly version 6.0
B) Any version >= 6.0
C) Version 6.x (6.0 and above, but not 7.0)
D) Version 6.0 only

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Version 6.x (6.0 and above, but not 7.0)**

Explanation: The `~>` operator (pessimistic constraint) allows patch and minor version updates but not major version updates. `~> 6.0` allows 6.0, 6.1, 6.99 but not 7.0. The AWS provider is currently on version 6.x — see the [Version 6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade) for breaking changes from 5.x.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

### Tools
- [AWS Vault](https://github.com/99designs/aws-vault) - Secure credential storage
- [aws-sso-util](https://github.com/benkehoe/aws-sso-util) - AWS SSO helper
- [granted](https://docs.commonfate.io/granted/introduction) - Multi-account access

### Next Steps
- **Next Course**: [AWS-202: Compute & Networking](../AWS-202-compute-networking/README.md)
- **Related**: [TF-104: State Management](../../../TF-100-fundamentals/TF-104-state-cli/README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - AWS-200: AWS with Terraform*
---

## 🔄 AWS Provider v6 Changes

> **This module uses `hashicorp/aws ~> 6.0`** (upgraded from 5.x). The following breaking changes from the [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade) are relevant to this module:

### `data.aws_region` — `name` deprecated, use `region`

```hcl
# ❌ v5 and earlier
output "region" {
  value = data.aws_region.current.name  # deprecated in v6
}

# ✅ v6+
output "region" {
  value = data.aws_region.current.region  # use .region attribute
}
```

The example in this module already uses `.region`. See `example/main.tf`.

### S3 Backend — DynamoDB Locking Note

Lab 3 in this module uses DynamoDB for state locking. In Terraform 1.11+, S3 native locking is available and DynamoDB is no longer required:

```hcl
# Modern approach (Terraform 1.11+ / AWS provider v6)
terraform {
  backend "s3" {
    bucket       = "my-terraform-state"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true  # S3 native locking — no DynamoDB needed
  }
}
```

### Removed Services (not used in this module)

The following AWS services were removed in v6 and are **not used** in this module:
- `aws_opsworks_*` — OpsWorks Stacks reached End of Life
- `aws_simpledb_domain` — SimpleDB removed from AWS SDK v2
- `aws_worklink_*` — WorkLink support removed

**Reference**: [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade)
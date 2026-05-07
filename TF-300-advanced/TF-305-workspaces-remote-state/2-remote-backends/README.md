# TF-305 Section 2: Remote Backends

**Course**: TF-305 Workspaces & Remote State  
**Section**: 2 of 4  
**Duration**: 20 minutes  
**Prerequisites**: TF-104 (State Management & CLI), Section 1 (Workspaces)  
**Terraform Version**: 1.11+ (for S3 native locking)

---

## 📋 Overview

By default, Terraform stores state locally in `terraform.tfstate`. This works for solo development but breaks down for teams: two people can't safely run `terraform apply` simultaneously, state isn't backed up, and there's no locking to prevent conflicts. **Remote backends** solve all of these problems.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Explain why remote backends are essential for teams
- ✅ Configure the HCP Terraform (cloud) backend
- ✅ Configure the Azure Storage backend
- ✅ Configure the S3 backend (AWS)
- ✅ Understand state locking and why it matters
- ✅ Migrate local state to a remote backend

---

## 🔑 Why Remote Backends?

| Problem (Local State) | Solution (Remote Backend) |
|----------------------|--------------------------|
| State lost if laptop dies | State stored in durable cloud storage |
| Two people apply simultaneously → corruption | State locking prevents concurrent applies |
| No history of state changes | Versioned state with rollback capability |
| Secrets in local state file | Encrypted state at rest |
| Can't share state between configs | `terraform_remote_state` data source |
| No audit trail | Who changed what and when |

---

## 📚 Backend 1: HCP Terraform (Recommended — HashiCorp Native)

HCP Terraform (formerly Terraform Cloud) is HashiCorp's managed service for Terraform. It provides:
- ✅ Free tier available (up to 500 resources)
- ✅ Encrypted state storage
- ✅ Built-in state locking
- ✅ State history and rollback
- ✅ Remote execution (runs in HCP, not locally)
- ✅ Team access controls

### Configuration

```hcl
terraform {
  required_version = ">= 1.14"

  # HCP Terraform backend (cloud block)
  cloud {
    organization = "my-org"          # Your HCP Terraform organization

    workspaces {
      name = "my-project-prod"       # HCP Terraform workspace name
    }
  }
}
```

### Multiple Workspaces with HCP Terraform

```hcl
terraform {
  cloud {
    organization = "my-org"

    workspaces {
      # Use a tag to select workspaces dynamically
      tags = ["my-project"]
      # This allows: my-project-dev, my-project-staging, my-project-prod
    }
  }
}
```

### Setup Steps

```bash
# 1. Create account at https://app.terraform.io (free)
# 2. Create an organization
# 3. Generate an API token
terraform login  # Opens browser, saves token to ~/.terraform.d/credentials.tfrc.json

# 4. Initialize with cloud backend
terraform init

# 5. Apply (runs remotely in HCP Terraform)
terraform apply
```

---

## 📚 Backend 2: Azure Storage (azurerm)

For Azure-based teams, Azure Blob Storage provides a reliable remote backend with built-in state locking via blob leases.

### Configuration

```hcl
terraform {
  required_version = ">= 1.14"

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
    # State locking: built-in via Azure Blob lease mechanism
  }
}
```

### Setup (Azure CLI)

```bash
# Create resource group
az group create --name tfstate-rg --location westeurope

# Create storage account
az storage account create \
  --name tfstateaccount \
  --resource-group tfstate-rg \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name tfstate \
  --account-name tfstateaccount

# Initialize Terraform
terraform init
```

### Per-Environment State Files

```hcl
# dev environment
backend "azurerm" {
  key = "dev/terraform.tfstate"
}

# staging environment
backend "azurerm" {
  key = "staging/terraform.tfstate"
}

# prod environment
backend "azurerm" {
  key = "prod/terraform.tfstate"
}
```

---

## 📚 Backend 3: S3 (AWS)

For AWS-based teams, S3 provides state storage with locking.

> **Terraform 1.11+**: S3 now supports **native state locking** via a `.tflock` file stored alongside the state file. This eliminates the need for a separate DynamoDB table. The `dynamodb_table` attribute is **deprecated** as of Terraform 1.11.

### Configuration (Terraform 1.11+ — Recommended)

```hcl
terraform {
  required_version = ">= 1.14"

  backend "s3" {
    bucket       = "my-terraform-state"
    key          = "prod/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true          # Encrypt state at rest

    # S3 native state locking (Terraform 1.11+)
    # Creates a .tflock file in S3 — no DynamoDB table needed
    use_lockfile = true

    # DEPRECATED: DynamoDB locking (still works but will be removed in a future version)
    # dynamodb_table = "terraform-state-lock"
  }
}
```

### Configuration (Pre-1.11 — Legacy DynamoDB Locking)

> ⚠️ **Deprecated**: The `dynamodb_table` attribute is deprecated in Terraform 1.11+. Use `use_lockfile = true` instead. DynamoDB locking still works for migration purposes but will be removed in a future version.

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true

    # Legacy: DynamoDB-based locking (deprecated in 1.11)
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Setup (AWS CLI — Native Locking, No DynamoDB)

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket my-terraform-state \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1

# Enable versioning (for state history and lock file durability)
aws s3api put-bucket-versioning \
  --bucket my-terraform-state \
  --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket my-terraform-state \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# No DynamoDB table needed with use_lockfile = true!

# Initialize Terraform
terraform init
```

### Migrating from DynamoDB Locking to Native Locking

If you have an existing S3 backend with DynamoDB locking, migration is straightforward:

```hcl
# Step 1: Add use_lockfile = true alongside the existing dynamodb_table
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    use_lockfile   = true          # Add this
    dynamodb_table = "terraform-state-lock"  # Keep temporarily
  }
}
```

```bash
# Step 2: Run terraform init to reconfigure the backend
terraform init -reconfigure

# Step 3: Verify everything works with a plan
terraform plan

# Step 4: Remove dynamodb_table from the backend config
# (edit main.tf to remove the dynamodb_table line)

# Step 5: Re-initialize
terraform init -reconfigure

# Step 6: (Optional) Delete the DynamoDB table if no longer needed
aws dynamodb delete-table --table-name terraform-state-lock
```

### Authentication via `aws login` (Terraform 1.15+)

Terraform 1.15 adds support for authenticating to S3 backends using **`aws login`**, which provides temporary credentials through AWS IAM Identity Center (formerly AWS SSO).

**Benefits**:
- ✅ No long-lived credentials stored on disk
- ✅ Temporary credentials that expire automatically
- ✅ Centralized access management through IAM Identity Center
- ✅ Multi-account access with role switching
- ✅ Better security posture

#### Configuration

```hcl
terraform {
  required_version = ">= 1.15.0"

  backend "s3" {
    bucket       = "my-terraform-state"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true

    # No access_key or secret_key needed!
    # Terraform will use credentials from aws login
  }
}
```

#### Setup and Usage

```bash
# Step 1: Configure AWS CLI with IAM Identity Center
aws configure sso

# Follow prompts:
# - SSO start URL: https://my-company.awsapps.com/start
# - SSO region: us-east-1
# - Account: Select your AWS account
# - Role: Select your role (e.g., AdministratorAccess)
# - CLI profile name: my-profile

# Step 2: Login to get temporary credentials
aws sso login --profile my-profile

# Step 3: Set the AWS profile for Terraform
export AWS_PROFILE=my-profile

# Step 4: Initialize and use Terraform
terraform init
terraform plan
terraform apply
```

#### Credential Precedence

Terraform checks for AWS credentials in this order:

1. **Environment variables**: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
2. **Shared credentials file**: `~/.aws/credentials` (from `aws login` or `aws configure`)
3. **Shared config file**: `~/.aws/config` (SSO configuration)
4. **EC2 instance metadata**: When running on EC2
5. **ECS task role**: When running in ECS

With `aws login`, credentials are stored in `~/.aws/cli/cache/` and automatically refreshed.

#### Multi-Account Access

```bash
# Configure multiple profiles for different accounts
aws configure sso --profile dev-account
aws configure sso --profile prod-account

# Switch between accounts
export AWS_PROFILE=dev-account
terraform init  # Uses dev account

export AWS_PROFILE=prod-account
terraform init  # Uses prod account
```

#### CI/CD Integration

For CI/CD pipelines, use OIDC (OpenID Connect) instead of `aws login`:

```hcl
# GitHub Actions example
terraform {
  backend "s3" {
    bucket       = "my-terraform-state"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    
    # CI/CD uses OIDC role assumption
    role_arn = "arn:aws:iam::123456789012:role/github-actions-terraform"
  }
}
```

#### Troubleshooting

**Error: "No valid credential sources found"**
```bash
# Check if logged in
aws sts get-caller-identity --profile my-profile

# If expired, login again
aws sso login --profile my-profile
```

**Error: "Token has expired"**
```bash
# Credentials expire after a few hours (default: 12 hours)
# Simply login again
aws sso login --profile my-profile
```

**Check current credentials**
```bash
# Verify which credentials Terraform will use
aws sts get-caller-identity

# Output shows:
# - UserId: Your user ID
# - Account: AWS account number
# - Arn: Your role ARN
```

#### Best Practices

1. **Use `aws login` for local development**: Temporary credentials are more secure than long-lived access keys

2. **Use OIDC for CI/CD**: GitHub Actions, GitLab CI, and other platforms support OIDC for temporary credentials

3. **Set credential expiration**: Configure shorter expiration times for sensitive environments

4. **Rotate regularly**: Even with temporary credentials, rotate your SSO configuration periodically

5. **Audit access**: Use AWS CloudTrail to monitor who accessed state files

#### Comparison: Authentication Methods

| Method | Security | Setup Complexity | Best For |
|--------|----------|------------------|----------|
| **`aws login`** (1.15+) | ✅ High (temporary) | Medium | Local development |
| **OIDC** | ✅ High (temporary) | High | CI/CD pipelines |
| **IAM User Keys** | ⚠️ Low (long-lived) | Low | ❌ Not recommended |
| **EC2 Instance Profile** | ✅ High (temporary) | Low | EC2-based workflows |
| **ECS Task Role** | ✅ High (temporary) | Low | ECS-based workflows |


---

## 🔄 State Locking

State locking prevents two operations from modifying state simultaneously. Without locking:

```
Person A: terraform apply  ─────────────────────────────→ writes state
Person B: terraform apply  ──────────────────────────────→ writes state (CONFLICT!)
                                                           State is now corrupted
```

With locking:

```
Person A: terraform apply  → acquires lock → applies → releases lock
Person B: terraform apply  → waits for lock → acquires lock → applies → releases lock
                                              (sequential, safe)
```

### Locking by Backend

| Backend | Locking Mechanism | Notes |
|---------|------------------|-------|
| HCP Terraform | Built-in (automatic) | Recommended |
| azurerm | Azure Blob lease (automatic) | No extra setup |
| s3 + `use_lockfile` | S3 `.tflock` file (Terraform 1.11+) | ✅ Recommended for AWS |
| s3 + DynamoDB | DynamoDB table | ⚠️ Deprecated in 1.11 |
| local | Local `.terraform.tfstate.lock.info` file | Solo dev only |

---

## 🔄 Migrating Local State to Remote Backend

```bash
# Step 1: Add backend configuration to main.tf
# (add the backend block as shown above)

# Step 2: Initialize — Terraform detects the new backend
terraform init
# Initializing the backend...
# Do you want to copy existing state to the new backend?
# Enter a value: yes

# Step 3: Verify state was migrated
terraform state list

# Step 4: Delete local state file (it's now in the remote backend)
Remove-Item terraform.tfstate
Remove-Item terraform.tfstate.backup
```

---

## ✅ Checkpoint Quiz

**Question 1**: What is the primary benefit of state locking in remote backends?
- A) It makes Terraform run faster
- B) It prevents two operations from corrupting state simultaneously
- C) It encrypts the state file
- D) It backs up the state automatically

<details>
<summary>Answer</summary>
**B) It prevents two operations from corrupting state simultaneously** — Without locking, two concurrent `terraform apply` operations can both read the same state, make changes, and write conflicting state files, corrupting the state.
</details>

---

**Question 2**: Which backend is the HashiCorp-native recommended option?
- A) S3 backend
- B) azurerm backend
- C) HCP Terraform (cloud block)
- D) consul backend

<details>
<summary>Answer</summary>
**C) HCP Terraform (cloud block)** — HCP Terraform is HashiCorp's managed service with a free tier, built-in locking, encrypted state, state history, and team access controls. It's the recommended backend for most teams.
</details>

---

## 📚 Key Takeaways

| Backend | Best For | Locking | Free Tier |
|---------|----------|---------|-----------|
| HCP Terraform | Any team, HashiCorp-native | ✅ Built-in | ✅ Yes (500 resources) |
| azurerm | Azure-based teams | ✅ Blob lease | ❌ Azure costs |
| s3 (1.11+) | AWS-based teams | ✅ Native S3 lockfile | ❌ AWS costs |
| s3 (legacy) | AWS-based teams (pre-1.11) | ⚠️ DynamoDB (deprecated) | ❌ AWS costs |
| local | Solo development only | ⚠️ Local file | ✅ Yes |

> **S3 Locking Summary**: Terraform 1.11 introduced `use_lockfile = true` for the S3 backend, storing a `.tflock` file in S3 instead of using DynamoDB. This simplifies setup (one less AWS service to manage) and reduces costs. The `dynamodb_table` attribute is deprecated and will be removed in a future Terraform version.

---

## 🔗 Next Steps

- **Next**: [Section 3: Remote State Sharing](../3-remote-state-sharing/README.md) — share outputs between configurations
- **Previous**: [Section 1: Workspaces](../1-workspaces/README.md)
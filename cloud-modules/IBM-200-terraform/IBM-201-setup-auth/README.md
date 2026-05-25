# IBM-201: IBM Cloud Setup & Authentication

**Course**: IBM-200 IBM Cloud with Terraform  
**Module**: IBM-201  
**Duration**: 1 hour  
**Prerequisites**: TF-100 series (Terraform Fundamentals)  
**Difficulty**: Intermediate

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [IBM Cloud Account Setup](#ibm-cloud-account-setup)
4. [IBM Cloud CLI Installation](#ibm-cloud-cli-installation)
5. [IAM and API Keys for Terraform](#iam-and-api-keys-for-terraform)
6. [Terraform IBM Provider](#terraform-ibm-provider)
7. [Authentication Methods](#authentication-methods)
8. [Best Practices](#best-practices)
9. [Hands-On Labs](#hands-on-labs)
10. [Troubleshooting](#troubleshooting)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course teaches you how to set up IBM Cloud access for Terraform. You'll learn how to install the IBM Cloud CLI, create and manage IBM Cloud API keys, configure the IBM Terraform provider, and verify authentication before building real infrastructure.

### What You'll Build

By the end of this course, you'll be able to:
- Set up an IBM Cloud account for Terraform use
- Install and verify the IBM Cloud CLI
- Create and manage IBM Cloud API keys securely
- Configure the Terraform IBM provider
- Validate the account and region Terraform is using

### Course Structure

```text
IBM-201-setup-auth/
├── README.md                          # This file
└── example/
    ├── main.tf                        # IBM provider configuration
    ├── variables.tf                   # Input variables
    └── tests/
        └── basic.tftest.hcl           # Terraform tests with mocked provider data
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Set Up IBM Cloud Account**
   - Understand IBM Cloud account structure
   - Work with regions and resource groups
   - Prepare an account for Terraform use

2. **Configure IBM Cloud CLI**
   - Install the IBM Cloud CLI
   - Log in interactively
   - Target the correct account, region, and resource group

3. **Create API Credentials**
   - Generate IBM Cloud API keys
   - Understand IAM-based authentication
   - Store credentials securely

4. **Configure Terraform Provider**
   - Write IBM provider configuration
   - Use environment variables
   - Set provider version constraints

5. **Apply Security Best Practices**
   - Avoid hardcoded credentials
   - Prefer scoped access and least privilege
   - Keep state and credentials separate

---

## ☁️ IBM Cloud Account Setup

### IBM Cloud Account Model

IBM Cloud commonly organizes work around:

```text
IBM Cloud Account
├── IAM users / service IDs / API keys
├── Resource Groups
├── Regions
└── Resources (VPC, COS, VSI, etc.)
```

For Terraform training, the key concepts are:

- **Account**: your top-level IBM Cloud tenancy
- **Resource Group**: logical grouping for billable/manageable resources
- **Region**: geographic location such as `us-south`, `eu-de`, or `eu-gb`

### Create or Verify an IBM Cloud Account

1. Sign in to [cloud.ibm.com](https://cloud.ibm.com)
2. Verify you have access to an active IBM Cloud account
3. Create or choose a resource group for training
4. Decide which region you will use for labs

> ⚠️ **Cost Warning**: IBM Cloud resources can incur charges. Use a dedicated training resource group and remove resources promptly after labs.

### Recommended Training Defaults

For consistency in this course, use:
- **Region**: `us-south` by default
- **Resource Group**: `Default` or a dedicated training resource group such as `iac-bootcamp`

---

## 💻 IBM Cloud CLI Installation

### Install IBM Cloud CLI

#### macOS
```bash
brew install ibm-cloud-cli
```

#### Linux
See the official install instructions:
```bash
curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
```

#### Windows
Use the official installer from IBM Cloud:
- https://cloud.ibm.com/docs/cli?topic=cli-getting-started

### Verify Installation

```bash
ibmcloud version
```

Expected output should show the installed CLI version.

### Log In

```bash
ibmcloud login
```

If you need to target a specific region during login:

```bash
ibmcloud login -r us-south
```

### Verify Account Context

```bash
ibmcloud target
```

This shows the current:
- account
- region
- resource group

### Set Region and Resource Group

```bash
ibmcloud target -r us-south
ibmcloud target -g Default
```

---

## 🔐 IAM and API Keys for Terraform

### IBM Cloud API Key

The IBM provider commonly authenticates using an IBM Cloud API key.

From the provider documentation:

```bash
export IC_API_KEY="IBM Cloud API Key"
```

### Create an API Key

You can create an API key in the IBM Cloud console:

1. Go to **Manage** → **Access (IAM)**
2. Open **API keys**
3. Create a new key for your user or service identity
4. Save it securely

You can also create one with the CLI:

```bash
ibmcloud iam api-key-create terraform-training-key
```

### Least-Privilege Guidance

Do not use over-privileged credentials when narrower permissions are possible.

For real-world use, prefer:
- dedicated service IDs
- limited IAM policies
- environment-specific API keys
- separate credentials for dev/test/prod

### Environment Variables Commonly Used

Based on the IBM provider documentation:

```bash
export IC_API_KEY="your-ibm-cloud-api-key"
export IC_REGION="us-south"
```

Additional classic infrastructure variables may exist for some legacy/classic resources:

```bash
export IAAS_CLASSIC_API_KEY="classic-api-key"
export IAAS_CLASSIC_USERNAME="classic-username"
```

For this course starter module, focus on **IAM/API key authentication** with modern IBM Cloud resources.

---

## ⚙️ Terraform IBM Provider

### Provider Source and Version

The IBM provider documentation shows:

```hcl
terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "<provider version>"
    }
  }
}
```

For the course example, we will pin a modern major version:

```hcl
terraform {
  required_version = ">= 1.14"

  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 2.0"
    }
  }
}
```

### Basic Provider Configuration

```hcl
provider "ibm" {
  region = var.ibm_region
}
```

Authentication is expected to come from environment variables such as `IC_API_KEY`.

### What This Module Validates

The example for this lesson is intentionally simple. It verifies:
- Terraform can initialize the IBM provider
- your selected region is valid input
- Terraform can read account-scoped information
- your authentication context is usable before later lessons

---

## 🔑 Authentication Methods

### Method 1: Environment Variables

Recommended for local labs and CI/CD:

```bash
export IC_API_KEY="your-ibm-cloud-api-key"
export IC_REGION="us-south"
terraform init
terraform plan
```

### Method 2: IBM Cloud CLI for Human Verification

The CLI does not replace provider authentication in the same way cloud-native Terraform login flows do for some providers, but it is useful to verify your account context before running Terraform:

```bash
ibmcloud login -r us-south
ibmcloud target -g Default
```

Then provide Terraform credentials through environment variables.

### Method 3: Classic Infrastructure Credentials

Some older/classic IBM resources may require:

```bash
export IAAS_CLASSIC_API_KEY="classic-api-key"
export IAAS_CLASSIC_USERNAME="classic-username"
```

This course starts with IAM/API-key-based IBM Cloud resources and treats classic credentials as legacy/special-case.

### Authentication Priority for This Course

Assume this order in practice for the module examples:

1. Explicit provider arguments if configured
2. Environment variables such as `IC_API_KEY`
3. Supporting classic environment variables when using legacy/classic resources

> Do not hardcode credentials in Terraform files.

---

## ✅ Best Practices

### 1. Never Hardcode Credentials

❌ **Never do this**:

```hcl
provider "ibm" {
  ibmcloud_api_key = "hardcoded-secret"
  region           = "us-south"
}
```

✅ **Do this instead**:

```bash
export IC_API_KEY="your-ibm-cloud-api-key"
export IC_REGION="us-south"
```

```hcl
provider "ibm" {
  region = var.ibm_region
}
```

### 2. Use Dedicated Resource Groups

Create a dedicated training resource group so all Terraform-managed resources are easy to identify and destroy.

### 3. Separate Credentials by Environment

Use different API keys for:
- development
- staging
- production

This reduces blast radius and improves auditability.

### 4. Use Version Constraints

```hcl
terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 2.0"
    }
  }
}
```

This allows provider updates within the same major version while reducing surprise breakage.

### 5. Validate Before Building

Before creating real infrastructure, always verify:
- correct account
- correct region
- correct resource group
- correct API key context

This lesson’s example is designed to do exactly that.

---

## 🔬 Hands-On Labs

### Lab 1: CLI and Account Validation (15 minutes)

**Objective**: Install the IBM Cloud CLI and confirm the target account context.

**Tasks**:
1. Install the IBM Cloud CLI
2. Run `ibmcloud login`
3. Run `ibmcloud target`
4. Set the region to `us-south`
5. Set the resource group to `Default` or your training resource group

**Expected Outcome**:
- IBM Cloud CLI is installed
- You are authenticated successfully
- The correct region and resource group are targeted

---

### Lab 2: API Key Setup (15 minutes)

**Objective**: Create an IBM Cloud API key for Terraform use.

**Tasks**:
1. Create an API key in IAM or with the CLI
2. Export `IC_API_KEY`
3. Export `IC_REGION`
4. Confirm the shell variables are set

**Expected Outcome**:
- API key is created and stored securely
- Terraform environment variables are available for provider authentication

---

### Lab 3: Provider Initialization (20 minutes)

**Objective**: Initialize Terraform with the IBM provider and validate authentication.

**Tasks**:
1. Open the `example/` directory
2. Run `terraform init`
3. Run `terraform validate`
4. Run `terraform plan`
5. Review the outputs that identify account and region context

**Expected Outcome**:
- IBM provider downloads successfully
- Terraform configuration validates
- Plan completes without credential errors

---

## 🐛 Troubleshooting

### 1. API Key Not Found

**Problem**: Terraform fails because no IBM Cloud API key is available.

**Check**:

```bash
echo $IC_API_KEY
```

**Fix**:

```bash
export IC_API_KEY="your-ibm-cloud-api-key"
```

---

### 2. Wrong Region

**Problem**: Terraform targets the wrong region or resources are unavailable.

**Check**:

```bash
echo $IC_REGION
ibmcloud target
```

**Fix**:

```bash
export IC_REGION="us-south"
ibmcloud target -r us-south
```

---

### 3. IBM Cloud CLI Logged Into Wrong Account

**Problem**: CLI verification does not match the account intended for Terraform.

**Check**:

```bash
ibmcloud target
```

**Fix**:

```bash
ibmcloud login
ibmcloud target -g Default -r us-south
```

---

### 4. Provider Init Failure

**Problem**: `terraform init` fails to download or configure the IBM provider.

**Check**:
- internet connectivity
- provider source string
- version constraint syntax

Correct format:

```hcl
terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 2.0"
    }
  }
}
```

---

## 📝 Checkpoint Quiz

### Question 1: Provider Source
**What is the correct provider source address for the IBM Cloud Terraform provider?**

A) `hashicorp/ibm`  
B) `IBM-Cloud/ibm`  
C) `ibm/cloud`  
D) `terraform/ibm`

<details>
<summary>Click to reveal answer</summary>

**Answer: B) `IBM-Cloud/ibm`**

The provider documentation shows the provider source as:

```hcl
source = "IBM-Cloud/ibm"
```
</details>

---

### Question 2: Recommended Authentication
**What is the primary recommended authentication method for this module?**

A) Hardcoded provider credentials  
B) IBM Cloud console session only  
C) Environment variable `IC_API_KEY`  
D) Terraform Cloud variable sets only

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Environment variable `IC_API_KEY`**

This module is built around environment-based authentication using IBM Cloud API keys.
</details>

---

### Question 3: Region Variable
**Which environment variable is commonly used to indicate the IBM Cloud region for tests and provider context?**

A) `IBM_REGION`  
B) `TF_REGION`  
C) `IC_LOCATION`  
D) `IC_REGION`

<details>
<summary>Click to reveal answer</summary>

**Answer: D) `IC_REGION`**

The provider documentation references `IC_REGION` for test resource region selection.
</details>

---

### Question 4: Resource Organization
**What IBM Cloud construct should you use to group training resources for easier cleanup?**

A) Tenant  
B) Resource Group  
C) Workspace only  
D) Availability Zone

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Resource Group**

Resource groups make it easier to isolate and manage Terraform-created resources.
</details>

---

### Question 5: Security Practice
**What is the correct security guidance for IBM Cloud API keys in Terraform examples?**

A) Put them directly in `main.tf`  
B) Commit them to Git with `.gitignore` disabled  
C) Store them in shell environment variables or secret stores  
D) Add them to outputs for debugging

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Store them in shell environment variables or secret stores**

Credentials must not be hardcoded or committed.
</details>

---

### Question 6: Version Constraint
**What does `version = "~> 2.0"` mean?**

A) Only version 2.0.0  
B) Any version 2.x, but not 3.0  
C) Any provider version at all  
D) Any version above 2.0 including 3.x

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Any version 2.x, but not 3.0**

This is the Terraform pessimistic version constraint.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [IBM Cloud Provider for Terraform](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest)
- [IBM Cloud CLI Documentation](https://cloud.ibm.com/docs/cli)
- [IBM Cloud IAM Documentation](https://cloud.ibm.com/docs/account?topic=account-iamoverview)

### Reference Material in This Repository
- `documentation/terraform-provider-ibm/README.md`
- `documentation/terraform-provider-ibm/examples/`

### Next Steps
- **Next Course**: [IBM-202: Compute & Networking](../IBM-202-compute-networking/README.md)
- **Related**: [TF-104: State Management](../../../TF-100-fundamentals/TF-104-state-cli/README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - IBM-200: IBM Cloud with Terraform*
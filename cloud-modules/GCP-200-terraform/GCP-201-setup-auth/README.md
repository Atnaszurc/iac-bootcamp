# GCP-201: GCP Setup & Authentication

**Level**: 201 (Intermediate - Cloud Specific)  
**Duration**: 1 hour  
**Prerequisites**: TF-100 series (Terraform Fundamentals)  
**Status**: 🚧 **PLANNED** - Content in development

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ Set up a Google Cloud Platform account and project
- ✅ Install and configure Google Cloud SDK (gcloud)
- ✅ Create and manage service accounts for Terraform
- ✅ Understand GCP authentication methods
- ✅ Configure the Terraform Google provider
- ✅ Work with multiple GCP projects
- ✅ Follow GCP authentication best practices

---

## 📚 Topics Covered

### 1. GCP Account & Project Setup
- Creating a GCP account
- Understanding the GCP free tier ($300 credit + always free)
- Creating and managing projects
- Understanding project hierarchy (Organization → Folder → Project)
- Enabling billing accounts
- Setting up budget alerts

### 2. Google Cloud SDK Installation
- Installing gcloud CLI on different platforms
- Initializing gcloud configuration
- Understanding gcloud components
- Using Cloud Shell as an alternative
- gcloud authentication methods

### 3. Service Accounts for Terraform
- Understanding service accounts vs user accounts
- Creating service accounts
- Granting IAM roles to service accounts
- Generating and managing service account keys
- Best practices for key management
- Using Application Default Credentials (ADC)

### 4. GCP Authentication Methods
- **Service Account Keys**: JSON key files
- **Application Default Credentials**: Automatic credential discovery
- **Workload Identity**: For GKE workloads
- **gcloud auth application-default**: For local development
- **Impersonation**: Using one service account to act as another

### 5. Terraform Google Provider Configuration
- Basic provider configuration
- Authentication configuration
- Project and region settings
- Provider aliases for multi-project setups
- User project override
- Request timeouts and retries

### 6. API Management
- Understanding GCP APIs
- Enabling required APIs
- Using `google_project_service` resource
- API quotas and limits
- Handling API enablement delays

### 7. Best Practices
- Never commit service account keys to version control
- Use least privilege IAM roles
- Rotate service account keys regularly
- Use Workload Identity for GKE
- Enable audit logging
- Use separate projects for different environments

---

## 🛠️ Hands-On Labs

### Lab 1: GCP Account Setup
**Objective**: Create a GCP account and first project

**Steps**:
1. Sign up for GCP free tier
2. Create a new project
3. Enable billing (with free credit)
4. Set up budget alerts
5. Explore the Cloud Console

**Expected Outcome**: Working GCP account with a project ready for Terraform

---

### Lab 2: Google Cloud SDK Installation
**Objective**: Install and configure gcloud CLI

**Steps**:
1. Install Google Cloud SDK for your OS
2. Run `gcloud init`
3. Authenticate with your Google account
4. Set default project and region
5. Test with `gcloud projects list`

**Expected Outcome**: Functional gcloud CLI configured for your account

---

### Lab 3: Service Account Creation
**Objective**: Create a service account for Terraform with proper permissions

**Steps**:
1. Create a service account named "terraform"
2. Grant "Editor" role (or more specific roles)
3. Generate a JSON key file
4. Store the key securely
5. Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable
6. Test authentication

**Expected Outcome**: Service account with JSON key ready for Terraform

---

### Lab 4: First Terraform Configuration
**Objective**: Write and test your first GCP provider configuration

**Steps**:
1. Create a new directory for Terraform code
2. Write a basic `provider.tf` with Google provider
3. Create a simple resource (e.g., Cloud Storage bucket)
4. Run `terraform init`
5. Run `terraform plan`
6. Run `terraform apply`
7. Verify resource in Cloud Console
8. Run `terraform destroy`

**Expected Outcome**: Successfully deployed and destroyed a GCP resource

---

### Lab 5: Multi-Project Configuration
**Objective**: Configure Terraform to work with multiple GCP projects

**Steps**:
1. Create a second GCP project
2. Configure provider aliases
3. Deploy resources to both projects
4. Use `depends_on` for cross-project dependencies
5. Clean up resources

**Expected Outcome**: Understanding of multi-project Terraform configurations

---

## 📖 Key Concepts

### GCP Project Structure

```
Organization (optional)
└── Folder (optional)
    └── Project (required)
        ├── Resources (VMs, buckets, etc.)
        ├── IAM Policies
        ├── Billing Account
        └── Enabled APIs
```

### Service Account vs User Account

| Aspect | User Account | Service Account |
|--------|--------------|-----------------|
| Purpose | Human users | Applications/automation |
| Authentication | Password/2FA | JSON key or Workload Identity |
| Best for | Manual operations | Terraform, CI/CD |
| Key rotation | N/A | Required (90 days recommended) |

### IAM Roles for Terraform

**Recommended Roles**:
- `roles/editor` - Broad permissions (good for learning)
- `roles/compute.admin` - Compute Engine management
- `roles/storage.admin` - Cloud Storage management
- `roles/iam.serviceAccountUser` - Service account usage

**Production Recommendation**: Use custom roles with least privilege

---

## 💻 Example Code

### Basic Provider Configuration

```hcl
# provider.tf
terraform {
  required_version = ">= 1.14.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.24.0"
    }
  }
}

provider "google" {
  project = "my-project-id"
  region  = "us-central1"
  zone    = "us-central1-a"
}
```

### Using Service Account Key

```hcl
provider "google" {
  credentials = file("~/terraform-key.json")
  project     = "my-project-id"
  region      = "us-central1"
}
```

### Using Application Default Credentials (Recommended)

```hcl
# No credentials block needed
# Set environment variable: GOOGLE_APPLICATION_CREDENTIALS
provider "google" {
  project = "my-project-id"
  region  = "us-central1"
}
```

### Multi-Project Configuration

```hcl
# Default provider for project A
provider "google" {
  project = "project-a"
  region  = "us-central1"
}

# Alias for project B
provider "google" {
  alias   = "project_b"
  project = "project-b"
  region  = "europe-west1"
}

# Resource in project A (uses default provider)
resource "google_storage_bucket" "bucket_a" {
  name     = "bucket-in-project-a"
  location = "US"
}

# Resource in project B (uses alias)
resource "google_storage_bucket" "bucket_b" {
  provider = google.project_b
  name     = "bucket-in-project-b"
  location = "EU"
}
```

### Enabling APIs with Terraform

```hcl
# Enable required APIs
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"
  
  disable_on_destroy = false
}

# Wait for APIs to be enabled before creating resources
resource "google_compute_network" "vpc" {
  depends_on = [
    google_project_service.compute
  ]
  
  name                    = "my-vpc"
  auto_create_subnetworks = false
}
```

---

## 🔐 Security Best Practices

### 1. Service Account Key Management

```bash
# Create key with expiration tracking
gcloud iam service-accounts keys create ~/terraform-key.json \
  --iam-account=terraform@my-project.iam.gserviceaccount.com

# List keys to track age
gcloud iam service-accounts keys list \
  --iam-account=terraform@my-project.iam.gserviceaccount.com

# Delete old keys (rotate every 90 days)
gcloud iam service-accounts keys delete KEY_ID \
  --iam-account=terraform@my-project.iam.gserviceaccount.com
```

### 2. Never Commit Keys to Git

```bash
# Add to .gitignore
echo "*.json" >> .gitignore
echo "terraform-key.json" >> .gitignore
echo ".terraform/" >> .gitignore
```

### 3. Use Environment Variables

```bash
# Linux/macOS
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/terraform-key.json"
export GOOGLE_PROJECT="my-project-id"
export GOOGLE_REGION="us-central1"

# Windows PowerShell
$env:GOOGLE_APPLICATION_CREDENTIALS="$HOME\terraform-key.json"
$env:GOOGLE_PROJECT="my-project-id"
$env:GOOGLE_REGION="us-central1"
```

### 4. Least Privilege IAM

```bash
# Instead of Editor role, use specific roles
gcloud projects add-iam-policy-binding my-project \
  --member="serviceAccount:terraform@my-project.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding my-project \
  --member="serviceAccount:terraform@my-project.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

---

## 🧪 Validation & Testing

### Verify gcloud Installation

```bash
gcloud version
gcloud auth list
gcloud config list
```

### Verify Service Account Authentication

```bash
# Test authentication
gcloud auth application-default print-access-token

# List projects accessible by service account
gcloud projects list
```

### Verify Terraform Provider

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Test provider connectivity
terraform plan
```

---

## 🚨 Common Issues & Solutions

### Issue 1: "API not enabled"

**Error**: `Error 403: Compute Engine API has not been used in project...`

**Solution**:
```bash
gcloud services enable compute.googleapis.com
# Or use google_project_service resource
```

### Issue 2: "Permission denied"

**Error**: `Error 403: The caller does not have permission`

**Solution**: Grant appropriate IAM roles to service account

### Issue 3: "Invalid credentials"

**Error**: `Error: google: could not find default credentials`

**Solution**: Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable

### Issue 4: "Project not found"

**Error**: `Error 404: The resource 'projects/my-project' was not found`

**Solution**: Verify project ID (not project name) and ensure it exists

---

## 📚 Additional Resources

### Official Documentation
- [GCP Free Tier](https://cloud.google.com/free)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs)
- [Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

### Tutorials
- [GCP Quickstart](https://cloud.google.com/docs/get-started)
- [gcloud CLI Quickstart](https://cloud.google.com/sdk/docs/quickstart)
- [Terraform on GCP](https://cloud.google.com/docs/terraform)

---

## ✅ Module Completion Checklist

You've completed GCP-201 when you can:

- [ ] Create a GCP account and project
- [ ] Install and configure gcloud CLI
- [ ] Create a service account for Terraform
- [ ] Generate and secure service account keys
- [ ] Configure Terraform Google provider
- [ ] Enable required GCP APIs
- [ ] Deploy a simple resource with Terraform
- [ ] Work with multiple projects
- [ ] Follow security best practices

---

## 🔄 What's Next?

After completing GCP-201, proceed to:

**→ [GCP-202: Compute & Networking](../GCP-202-compute-networking/README.md)**

Learn to build VPC networks and deploy Compute Engine instances.

---

*Part of [GCP-200: Google Cloud Platform with Terraform](../README.md)*  
*Last Updated: 2026-03-18*
# TF-305: Workspaces & Remote State

**Course Level**: 300 (Advanced)  
**Duration**: 1.5 hours  
**Prerequisites**: TF-200 (Modules & Patterns), TF-104 (State Management & CLI)  
**Terraform Version**: 1.1+ (cloud block), 1.14+ (recommended)

---

## 📋 Course Overview

State management is one of the most critical aspects of production Terraform. This course covers how to manage state across teams and environments using workspaces, remote backends, and HCP Terraform — moving beyond the local state file that works for learning but fails in real-world scenarios.

---

## 🎯 Learning Objectives

By the end of this course, you will be able to:

- ✅ Use Terraform workspaces to manage multiple state files from one configuration
- ✅ Explain when workspaces are appropriate (and when they're not)
- ✅ Configure remote backends (HCP Terraform, azurerm, S3)
- ✅ Share state between configurations using `terraform_remote_state`
- ✅ Design a layered infrastructure architecture
- ✅ Migrate from local state to HCP Terraform
- ✅ Use HCP Terraform's state history and rollback features

---

## 📚 Course Sections

| Section | Topic | Duration |
|---------|-------|----------|
| [1. Workspaces](1-workspaces/README.md) | CLI workspaces, `terraform.workspace`, use cases and anti-patterns | 20 min |
| [2. Remote Backends](2-remote-backends/README.md) | HCP Terraform cloud block, azurerm, S3, state locking | 25 min |
| [3. Remote State Sharing](3-remote-state-sharing/README.md) | `terraform_remote_state`, layered architecture, coupling patterns | 20 min |
| [4. HCP Terraform State](4-hcp-terraform-state/README.md) | HCP Terraform as recommended backend, free tier, state history | 20 min |

---

## 🔑 Key Concepts

### The State Problem

```
Single developer, local state:
  ✅ Works fine — state is on your machine

Team of 5, local state:
  ❌ Who has the latest state?
  ❌ Two people apply at the same time → state corruption
  ❌ State file contains secrets → can't commit to git

Solution: Remote state with locking
```

### Backend Options Comparison

| Backend | Locking | History | UI | Cost |
|---------|---------|---------|-----|------|
| local | ❌ | ❌ | ❌ | Free |
| azurerm | ✅ (lease) | ❌ | Azure Portal | Storage cost |
| s3 + DynamoDB | ✅ | ❌ | ❌ | Minimal |
| HCP Terraform | ✅ | ✅ | ✅ | Free (≤500 resources) |

### Workspace vs Environment

```
❌ WRONG: Use CLI workspaces for dev/staging/prod
  → Same config, different state
  → No variable isolation
  → Easy to accidentally apply to wrong environment

✅ RIGHT: Use separate configurations or HCP Terraform workspaces
  → Proper isolation
  → Different variables per environment
  → Access controls per environment
```

---

## 📂 Directory Structure

```
TF-305-workspaces-remote-state/
├── README.md                          ← You are here
├── 1-workspaces/
│   ├── README.md                      ← Workspace concepts and CLI
│   └── example/
│       └── main.tf                    ← Workspace-driven configuration
├── 2-remote-backends/
│   ├── README.md                      ← Backend types and configuration
│   └── example/
│       └── main.tf                    ← Backend configuration examples
├── 3-remote-state-sharing/
│   ├── README.md                      ← terraform_remote_state data source
│   └── example/
│       ├── networking/                ← Producer: creates network, exposes outputs
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── compute/                   ← Consumer: reads networking outputs
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
└── 4-hcp-terraform-state/
    └── README.md                      ← HCP Terraform cloud block and free tier
```

---

## 🚀 Quick Start

### Option A: Start with Workspaces (no account needed)

```bash
cd 1-workspaces/example
terraform init
terraform workspace new dev
terraform workspace new prod
terraform apply  # Creates dev environment
terraform workspace select prod
terraform apply  # Creates prod environment
```

### Option B: Try Remote State Sharing (no account needed)

```bash
cd 3-remote-state-sharing/example

# Step 1: Apply the networking layer
cd networking
terraform init
terraform apply -auto-approve

# Step 2: Apply the compute layer (reads networking state)
cd ../compute
terraform init
terraform apply -auto-approve
cat vm.conf  # Shows values sourced from networking state
```

### Option C: Configure HCP Terraform (free account required)

```bash
# 1. Create free account at app.terraform.io
# 2. Create organization and workspace (execution mode: Local)
# 3. Authenticate
terraform login

# 4. Add cloud block to your configuration
# 5. Initialize (migrates local state to HCP Terraform)
terraform init
```

---

## ⚠️ Common Mistakes

### 1. Committing state files to git

```bash
# ❌ NEVER do this
git add terraform.tfstate
git commit -m "add state"

# ✅ Add to .gitignore
echo "*.tfstate" >> .gitignore
echo "*.tfstate.*" >> .gitignore
```

### 2. Using workspaces for environment separation

```hcl
# ❌ Anti-pattern: workspace-based environment separation
resource "libvirt_domain" "vm" {
  name = "${terraform.workspace}-vm"
  # dev and prod share the same config — risky
}

# ✅ Better: separate directories or HCP Terraform workspaces
# environments/dev/main.tf
# environments/prod/main.tf
```

### 3. Forgetting to initialize after backend change

```bash
# After changing backend configuration, always run:
terraform init
# Terraform will detect the change and offer to migrate state
```

---

## 📚 Prerequisites Review

Before starting this course, you should be comfortable with:

- `terraform init`, `plan`, `apply`, `destroy`
- Understanding what the state file contains
- Basic variable and output usage
- Module concepts (TF-200)

If you need a refresher: [TF-104: State Management & CLI](../../TF-100-fundamentals/TF-104-state-cli/README.md)

---

## ✅ Course Completion Checklist

- [ ] Understand what workspaces are and when to use them
- [ ] Know the workspace anti-pattern (workspaces ≠ environments)
- [ ] Can configure at least one remote backend
- [ ] Understand state locking and why it matters
- [ ] Can use `terraform_remote_state` to share outputs between configs
- [ ] Have configured HCP Terraform as a state backend (or understand how)
- [ ] Know how to view state history in HCP Terraform

---

## 🔗 Related Courses

- **Previous**: [TF-302: Pre/Post Conditions & Check Blocks](../TF-302-conditions-checks/README.md)
- **Also relevant**: [TF-104: State Management & CLI](../../TF-100-fundamentals/TF-104-state-cli/README.md)
- **Next**: [TF-303: Terraform Test Framework](../TF-303-test-framework/README.md)
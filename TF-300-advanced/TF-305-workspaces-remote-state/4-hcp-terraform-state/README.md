# TF-305 Section 4: HCP Terraform State

**Course**: TF-305 Workspaces & Remote State  
**Section**: 4 of 4  
**Duration**: 20 minutes  
**Prerequisites**: Section 2 (Remote Backends)  
**Terraform Version**: Any (cloud block requires Terraform 1.1+)

---

## 📋 Overview

HCP Terraform (formerly Terraform Cloud) is HashiCorp's managed platform for Terraform. Its **free tier** includes remote state storage with full history, state locking, and a web UI — making it the recommended backend for most teams. This section covers how to configure HCP Terraform as your state backend using the `cloud` block.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Explain what HCP Terraform provides beyond state storage
- ✅ Configure the `cloud` block to use HCP Terraform as a backend
- ✅ Migrate from local state to HCP Terraform
- ✅ Use HCP Terraform workspaces for environment separation
- ✅ Understand the free tier limits

---

## 🔑 Why HCP Terraform for State?

| Feature | Local Backend | azurerm/S3 | HCP Terraform (Free) |
|---------|--------------|------------|----------------------|
| State storage | ✅ | ✅ | ✅ |
| State locking | ❌ | ✅ (with extra setup) | ✅ (built-in) |
| State history | ❌ | ❌ | ✅ (unlimited) |
| State rollback | ❌ | ❌ | ✅ |
| Web UI | ❌ | ❌ | ✅ |
| Run history | ❌ | ❌ | ✅ |
| Cost | Free | Storage costs | Free (up to 500 resources) |
| Setup complexity | None | Medium | Low |

---

## 📚 The `cloud` Block

The `cloud` block (Terraform 1.1+) is the modern way to connect to HCP Terraform. It replaces the older `backend "remote"` syntax.

### Basic Configuration

```hcl
terraform {
  required_version = ">= 1.1.0"

  cloud {
    organization = "my-org-name"

    workspaces {
      name = "my-workspace"
    }
  }
}
```

### Configuration with Tags (Multiple Workspaces)

```hcl
terraform {
  cloud {
    organization = "my-org-name"

    # Match workspaces by tag instead of a single name
    # Useful when you have dev/staging/prod workspaces
    workspaces {
      tags = ["networking", "production"]
    }
  }
}
```

### Authentication

HCP Terraform requires a token. Set it via environment variable (recommended for CI/CD):

```bash
export TF_TOKEN_app_terraform_io="your-token-here"
```

Or use `terraform login` for interactive use:

```bash
terraform login
# Opens browser to generate a token, stores it in ~/.terraform.d/credentials.tfrc.json
```

---

## 📚 HCP Terraform Workspaces vs CLI Workspaces

This is a common source of confusion:

```
CLI Workspaces (terraform workspace)
├── Stored in the same backend
├── Share the same configuration
├── Lightweight — just different state files
└── Anti-pattern for environment separation

HCP Terraform Workspaces
├── Separate entities in the HCP Terraform UI
├── Can have different variables per workspace
├── Can have different access controls
├── Can be linked to different VCS branches
└── ✅ Correct pattern for environment separation
```

When using the `cloud` block, `terraform workspace` commands interact with **HCP Terraform workspaces**, not local CLI workspaces.

---

## 📚 Migrating from Local State to HCP Terraform

### Step 1: Create an HCP Terraform account and organization

1. Go to [app.terraform.io](https://app.terraform.io)
2. Create a free account
3. Create an organization

### Step 2: Add the `cloud` block to your configuration

```hcl
terraform {
  cloud {
    organization = "my-org-name"
    workspaces {
      name = "my-project-dev"
    }
  }
}
```

### Step 3: Run `terraform init`

```bash
terraform init
# Terraform detects the backend change and asks:
# "Do you want to copy existing state to the new backend?"
# Answer: yes
```

Terraform automatically migrates your local state to HCP Terraform.

### Step 4: Verify in the UI

Log in to [app.terraform.io](https://app.terraform.io) and confirm your state appears in the workspace.

---

## 📚 State History and Rollback

One of HCP Terraform's most valuable features is full state history:

```
HCP Terraform UI → Workspace → States tab

State #5  (current)  2026-02-28 10:00  3 resources
State #4             2026-02-27 15:30  3 resources
State #3             2026-02-27 09:00  2 resources  ← can roll back to this
State #2             2026-02-26 14:00  1 resource
State #1             2026-02-25 11:00  0 resources
```

To roll back:
1. Click on the desired state version in the UI
2. Click "Promote to current" (or use the API)

---

## 📚 Free Tier Limits

HCP Terraform's free tier (as of 2026):

| Limit | Free Tier |
|-------|-----------|
| Managed resources | 500 |
| Users | Unlimited |
| Workspaces | Unlimited |
| State history | Unlimited |
| Remote runs | Unlimited |
| Private module registry | ✅ |
| Sentinel policy | ❌ (Plus plan) |
| Audit logging | ❌ (Plus plan) |

For learning and small teams, the free tier is more than sufficient.

---

## 🧪 Hands-On Lab

### Lab: Configure HCP Terraform as State Backend

**Prerequisites**: HCP Terraform account (free at app.terraform.io)

**Step 1**: Create a workspace in HCP Terraform UI
- Organization: your-org-name
- Workspace name: `tf305-lab`
- Execution mode: **Local** (we run Terraform locally, HCP stores state)

**Step 2**: Authenticate

```bash
terraform login
# Follow the browser prompt to generate a token
```

**Step 3**: Create a configuration

```hcl
# main.tf
terraform {
  required_version = ">= 1.1.0"
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }

  cloud {
    organization = "your-org-name"
    workspaces {
      name = "tf305-lab"
    }
  }
}

resource "local_file" "hello" {
  content  = "Hello from HCP Terraform state!"
  filename = "${path.module}/hello.txt"
}

output "message" {
  value = "State is stored in HCP Terraform"
}
```

**Step 4**: Initialize and apply

```bash
terraform init    # Connects to HCP Terraform
terraform apply   # Runs locally, state stored in HCP Terraform
```

**Step 5**: Verify state in UI

Log in to app.terraform.io → your-org-name → tf305-lab → States

You should see State #1 with 1 resource.

**Step 6**: Make a change and apply again

```hcl
resource "local_file" "hello" {
  content  = "Updated content — state version 2"
  filename = "${path.module}/hello.txt"
}
```

```bash
terraform apply
```

Check the States tab again — you now have State #1 and State #2.

---

## ✅ Checkpoint Quiz

**Question 1**: What is the key advantage of HCP Terraform over the `azurerm` backend for state storage?
- A) It's faster
- B) It provides state history, rollback, and a web UI at no cost
- C) It supports more resource types
- D) It doesn't require authentication

<details>
<summary>Answer</summary>
**B) It provides state history, rollback, and a web UI at no cost** — The `azurerm` backend provides state locking but no built-in history or UI. HCP Terraform's free tier includes unlimited state history, rollback capability, and a full web UI.
</details>

---

**Question 2**: What execution mode should you set in HCP Terraform when running Terraform locally?
- A) Remote
- B) Agent
- C) Local
- D) Cloud

<details>
<summary>Answer</summary>
**C) Local** — With "Local" execution mode, Terraform runs on your machine but state is stored in HCP Terraform. "Remote" execution mode runs Terraform on HCP Terraform's infrastructure (useful for CI/CD but requires more setup).
</details>

---

## 📚 Key Takeaways

| Concept | Detail |
|---------|--------|
| `cloud` block | Modern way to connect to HCP Terraform (replaces `backend "remote"`) |
| Free tier | 500 resources, unlimited workspaces and state history |
| State history | Full version history with rollback capability |
| HCP workspaces | Different from CLI workspaces — proper environment separation |
| Execution mode | Use "Local" to run Terraform locally with HCP state storage |
| Migration | `terraform init` handles migration from local state automatically |

---

## 🔗 Next Steps

- **Course Complete**: You've finished TF-305!
- **Return to**: [TF-305 Course Overview](../README.md)
- **Previous**: [Section 3: Remote State Sharing](../3-remote-state-sharing/README.md)
- **Next Course**: [TF-306: Terraform Functions Deep Dive](../../TF-306-functions/README.md) *(planned)*
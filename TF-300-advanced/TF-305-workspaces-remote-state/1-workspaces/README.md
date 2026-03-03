# TF-305 Section 1: Terraform Workspaces

**Course**: TF-305 Workspaces & Remote State  
**Section**: 1 of 4  
**Duration**: 20 minutes  
**Prerequisites**: TF-104 (State Management & CLI)  
**Terraform Version**: Any (workspaces available since early versions)

---

## 📋 Overview

Terraform workspaces allow you to manage **multiple state files** from a single configuration directory. Each workspace has its own isolated state, enabling you to deploy the same configuration to different contexts (e.g., different regions, different feature branches) without duplicating code.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Create, list, select, and delete workspaces
- ✅ Use `terraform.workspace` in configuration
- ✅ Understand when workspaces are appropriate
- ✅ Understand the "workspaces are NOT environments" anti-pattern
- ✅ Choose the right approach for environment separation

---

## 🔑 Workspace Basics

By default, every Terraform configuration uses the **`default`** workspace. You can create additional workspaces to maintain separate state files.

### Workspace CLI Commands

```bash
# List all workspaces (* = current)
terraform workspace list
# * default
#   dev
#   staging
#   prod

# Create a new workspace
terraform workspace new dev

# Switch to an existing workspace
terraform workspace select staging

# Show current workspace
terraform workspace show
# staging

# Delete a workspace (must not be current, must be empty)
terraform workspace delete dev
```

### State File Location per Workspace

```
# Default workspace
terraform.tfstate

# Named workspaces (local backend)
terraform.tfstate.d/
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

---

## 📚 Using `terraform.workspace` in Configuration

The `terraform.workspace` built-in value returns the current workspace name as a string.

### Basic Usage

```hcl
resource "local_file" "env_config" {
  content  = "environment = ${terraform.workspace}"
  filename = "${path.module}/${terraform.workspace}-config.conf"
}
```

### Workspace-Driven Resource Sizing

```hcl
locals {
  # Different sizes per workspace
  memory_mb = {
    default = 512
    dev     = 512
    staging = 1024
    prod    = 4096
  }
}

resource "local_file" "vm_config" {
  content = <<-EOT
    name   = ${terraform.workspace}-web
    memory = ${lookup(local.memory_mb, terraform.workspace, 512)}
    env    = ${terraform.workspace}
  EOT
  filename = "${path.module}/${terraform.workspace}-vm.conf"
}
```

### Workspace-Specific Variable Files

```bash
# Use workspace-specific variable files
terraform workspace select staging
terraform apply -var-file="staging.tfvars"

terraform workspace select prod
terraform apply -var-file="prod.tfvars"
```

---

## ⚠️ Anti-Pattern: Workspaces as Environments

This is one of the most common Terraform mistakes. **Workspaces are NOT a replacement for separate environment configurations.**

### Why Workspaces Are NOT Environments

```
❌ ANTI-PATTERN: Using workspaces for prod/staging/dev environments

Problems:
1. All environments share the same code — a bug affects all environments
2. No isolation — a mistake in workspace selection can destroy prod
3. No separate access control per environment
4. Difficult to have different providers per environment
5. State files are in the same backend — no blast radius isolation
```

### The Right Approach: Separate Directories

```
✅ RECOMMENDED: Separate directories per environment

environments/
├── dev/
│   ├── main.tf          # Dev-specific configuration
│   ├── variables.tf
│   └── terraform.tfvars # Dev values
├── staging/
│   ├── main.tf          # Staging-specific configuration
│   ├── variables.tf
│   └── terraform.tfvars # Staging values
└── prod/
    ├── main.tf          # Prod-specific configuration
    ├── variables.tf
    └── terraform.tfvars # Prod values
```

Benefits:
- Complete isolation between environments
- Separate state files in separate backends
- Different access controls per environment
- Can have different providers/regions per environment
- A mistake in dev cannot affect prod

### When Workspaces ARE Appropriate

```
✅ GOOD use cases for workspaces:
- Feature branch testing (temporary, short-lived)
- Testing infrastructure changes before merging
- Running the same config in multiple regions simultaneously
- CI/CD pipeline isolation (each PR gets its own workspace)
```

---

## 🧪 Hands-On Lab

### Lab: Workspaces in Action

```bash
mkdir tf305-workspaces
cd tf305-workspaces
```

**Step 1**: Create `main.tf`:

```hcl
terraform {
  required_version = ">= 1.14"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

locals {
  sizes = {
    default = "small"
    dev     = "small"
    staging = "medium"
    prod    = "large"
  }
}

resource "local_file" "workspace_config" {
  content = <<-EOT
    # Configuration for workspace: ${terraform.workspace}
    environment = ${terraform.workspace}
    size        = ${lookup(local.sizes, terraform.workspace, "small")}
  EOT
  filename = "${path.module}/${terraform.workspace}.conf"
}
```

**Step 2**: Work with workspaces:

```bash
terraform init

# Default workspace
terraform workspace show   # default
terraform apply -auto-approve
cat default.conf

# Create and use dev workspace
terraform workspace new dev
terraform apply -auto-approve
cat dev.conf

# Create and use staging workspace
terraform workspace new staging
terraform apply -auto-approve
cat staging.conf

# List all workspaces
terraform workspace list
# * staging
#   default
#   dev

# Each workspace has its own state
ls terraform.tfstate.d/

# Switch back to default
terraform workspace select default
terraform destroy -auto-approve

# Clean up other workspaces
terraform workspace select dev
terraform destroy -auto-approve
terraform workspace select default
terraform workspace delete dev

terraform workspace select staging
terraform destroy -auto-approve
terraform workspace select default
terraform workspace delete staging
```

---

## ✅ Checkpoint Quiz

**Question 1**: What does `terraform.workspace` return?
- A) The path to the workspace directory
- B) The name of the current workspace as a string
- C) The workspace ID number
- D) The backend configuration

<details>
<summary>Answer</summary>
**B) The name of the current workspace as a string** — For example, if you're in the `staging` workspace, `terraform.workspace` returns `"staging"`. In the default workspace, it returns `"default"`.
</details>

---

**Question 2**: Why are workspaces NOT recommended for environment separation (dev/staging/prod)?
- A) Workspaces are too slow for production use
- B) All environments share the same code with no blast radius isolation
- C) Workspaces don't support remote backends
- D) Workspaces can only be used with the local backend

<details>
<summary>Answer</summary>
**B) All environments share the same code with no blast radius isolation** — A mistake in workspace selection (e.g., running `terraform destroy` in the wrong workspace) can affect production. Separate directories with separate state backends provide true isolation.
</details>

---

## 📚 Key Takeaways

| Concept | Detail |
|---------|--------|
| Default workspace | Always exists, named `"default"` |
| `terraform.workspace` | Returns current workspace name |
| State isolation | Each workspace has its own state file |
| Good use case | Feature branches, CI/CD isolation, multi-region |
| Bad use case | Production/staging/dev environment separation |
| Better alternative | Separate directories per environment |

---

## 🔗 Next Steps

- **Next**: [Section 2: Remote Backends](../2-remote-backends/README.md) — store state remotely for team collaboration
- **Related**: [TF-104: State Management](../../../TF-100-fundamentals/TF-104-state-cli/README.md) — local state fundamentals
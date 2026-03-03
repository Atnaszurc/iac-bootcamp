# TF-402: Remote Runs & VCS Integration

**Course**: TF-400 — HCP Terraform & Enterprise Features  
**Module**: TF-402  
**Duration**: 1.5 hours  
**Level**: 400 (Expert)  
**Prerequisites**: TF-401 (HCP Terraform Fundamentals)

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- Explain the difference between local and remote Terraform runs
- Configure a VCS-driven workspace connected to GitHub
- Understand speculative plans on pull requests
- Configure run triggers for workspace-to-workspace dependencies
- Use workspace variables and variable sets effectively
- Set up notifications for run events

---

## 📚 Remote Runs Explained

In HCP Terraform, a **run** is the execution of `terraform plan` + `terraform apply`. Remote runs execute in HCP Terraform's managed infrastructure, not on your local machine.

### Run Lifecycle

```
1. Trigger (VCS push / CLI / API)
        │
        ▼
2. Plan Phase
   - HCP Terraform downloads your code
   - Downloads providers
   - Runs `terraform plan`
   - Shows diff to reviewers
        │
        ▼
3. Policy Check (if Sentinel configured)
   - Policies evaluated against plan
   - Advisory / Soft-mandatory / Hard-mandatory
        │
        ▼
4. Apply Phase (manual approval or auto-apply)
   - `terraform apply` executes
   - State updated in HCP Terraform
        │
        ▼
5. Post-Apply
   - Notifications sent (Slack, email, webhook)
   - Run triggers fire (dependent workspaces)
```

### Run Types

| Type | Trigger | Plan | Apply |
|------|---------|------|-------|
| **Speculative** | PR opened/updated | ✅ | ❌ (read-only) |
| **Normal** | Push to main / CLI apply | ✅ | ✅ (with approval) |
| **Destroy** | Manual / API | ✅ | ✅ (destroys all) |
| **Refresh-only** | Manual / API | ✅ (state only) | ✅ |

---

## 📖 Topics Covered

### 1. VCS-Driven Workspaces

A VCS-driven workspace connects directly to a Git repository. This enables the full GitOps workflow:

```
Developer                GitHub                  HCP Terraform
──────────               ──────                  ─────────────
git push ──────────────► PR opened ────────────► Speculative plan
                         PR comment ◄────────── Plan results posted
                         PR merged ─────────────► terraform apply
                         Slack/email ◄─────────── Apply complete
```

**Configuration in HCP Terraform UI**:
1. Create workspace → "Version control workflow"
2. Connect to GitHub (OAuth)
3. Select repository and branch
4. Set working directory (if `.tf` files are in a subdirectory)
5. Configure auto-apply (or require manual approval)

### 2. Speculative Plans

When a pull request is opened against the tracked branch, HCP Terraform automatically runs a **speculative plan** — a read-only plan that shows what would change.

- Results are posted as a PR comment
- Reviewers can see the infrastructure diff before merging
- Speculative plans cannot be applied (they are informational only)
- Requires the HCP Terraform GitHub App to be installed

### 3. Run Triggers

Run triggers allow one workspace to automatically queue a run when another workspace's apply completes successfully.

**Use case**: Networking workspace applies → triggers Application workspace to run

```
networking-workspace ──apply──► triggers ──► application-workspace
                                             (reads networking outputs
                                              via terraform_remote_state)
```

### 4. Workspace Variables vs Variable Sets

**Workspace Variables**: Scoped to a single workspace
```
Workspace: production-app
  Variables:
    - app_version = "2.1.0"
    - instance_count = 3
```

**Variable Sets**: Reusable, applied to multiple workspaces
```
Variable Set: "AWS Credentials"
  Variables:
    - AWS_ACCESS_KEY_ID = (sensitive)
    - AWS_SECRET_ACCESS_KEY = (sensitive)
  Applied to: all workspaces tagged "aws"
```

---

## 🔧 Examples

### Example 1: VCS-Driven Workspace Configuration

See [`examples/01-vcs-workspace/`](examples/01-vcs-workspace/) for the Terraform configuration.

The key is the `cloud` block — HCP Terraform handles the VCS connection in the UI:

```hcl
terraform {
  cloud {
    organization = "my-organization"
    workspaces {
      name = "production-app"
      # VCS connection is configured in HCP Terraform UI, not in code
    }
  }
}
```

### Example 2: Run Triggers Configuration

Run triggers are configured in HCP Terraform using the `tfe` provider (meta-Terraform):

```hcl
# Configure HCP Terraform workspaces and run triggers using the TFE provider
provider "tfe" {
  # Token from TFE_TOKEN environment variable or terraform login
}

resource "tfe_workspace" "networking" {
  name         = "networking"
  organization = "my-organization"
}

resource "tfe_workspace" "application" {
  name         = "application"
  organization = "my-organization"
}

# When networking workspace applies, trigger application workspace
resource "tfe_workspace_run_trigger" "app_depends_on_network" {
  workspace_id  = tfe_workspace.application.id
  sourceable_id = tfe_workspace.networking.id
}
```

### Example 3: Variable Sets

```hcl
# Create a variable set for shared AWS credentials
resource "tfe_variable_set" "aws_credentials" {
  name         = "AWS Credentials"
  description  = "Shared AWS credentials for all AWS workspaces"
  organization = "my-organization"
}

resource "tfe_variable" "aws_access_key" {
  key             = "AWS_ACCESS_KEY_ID"
  value           = var.aws_access_key_id
  category        = "env"
  sensitive       = true
  variable_set_id = tfe_variable_set.aws_credentials.id
}

resource "tfe_variable" "aws_secret_key" {
  key             = "AWS_SECRET_ACCESS_KEY"
  value           = var.aws_secret_access_key
  category        = "env"
  sensitive       = true
  variable_set_id = tfe_variable_set.aws_credentials.id
}

# Apply variable set to all workspaces tagged "aws"
resource "tfe_workspace_variable_set" "aws_app" {
  variable_set_id = tfe_variable_set.aws_credentials.id
  workspace_id    = tfe_workspace.application.id
}
```

---

## 🔑 Key Concepts

### Auto-Apply vs Manual Apply

| Setting | Behavior | Use Case |
|---------|----------|----------|
| **Auto-apply** | Applies immediately after successful plan | Development environments |
| **Manual apply** | Requires human approval in UI | Production environments |

### Workspace Locking

HCP Terraform automatically locks a workspace during a run. If another run is triggered while a run is in progress, it is queued. This prevents concurrent state modifications.

### Terraform Variables vs Environment Variables

In HCP Terraform workspace variables:
- **Terraform variables** (`terraform` category): Passed as `-var` flags. Used in `.tf` files as `var.name`
- **Environment variables** (`env` category): Set as OS environment variables. Used for provider credentials (e.g., `AWS_ACCESS_KEY_ID`)

---

## 🏋️ Hands-On Lab

### Lab: VCS-Driven Workspace

1. Fork the training repository to your GitHub account
2. In HCP Terraform, create a new workspace → "Version control workflow"
3. Connect to your forked repository
4. Set the working directory to `TF-400-hcp-enterprise/TF-402-remote-runs/examples/01-vcs-workspace`
5. Create a branch, make a change to `main.tf`, open a PR
6. Observe the speculative plan comment on the PR
7. Merge the PR and observe the apply

### Lab: Configure Run Triggers

1. Create two workspaces: `networking` and `application`
2. Configure a run trigger: `application` triggers when `networking` applies
3. Apply the `networking` workspace
4. Observe `application` workspace automatically queues a run

---

## 📋 Key Takeaways

| Concept | Key Point |
|---------|-----------|
| VCS-driven | GitOps workflow — PRs trigger plans, merges trigger applies |
| Speculative plan | Read-only plan on PRs — shows diff without applying |
| Run triggers | Workspace dependencies — apply A triggers run in B |
| Variable sets | Reusable variables across multiple workspaces |
| Auto-apply | For dev; manual apply for production |
| Workspace locking | Prevents concurrent state modifications |

---

## 🔗 Next Steps

- **[TF-403](../TF-403-security-access/README.md)**: Security & Access Control
- **[TF-404](../TF-404-sentinel-policies/README.md)**: Sentinel Policy as Code

---

## 📚 References

- [HCP Terraform Run Triggers](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings/run-triggers)
- [VCS-Driven Workspaces](https://developer.hashicorp.com/terraform/cloud-docs/run/ui)
- [Variable Sets](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/variables/managing-variables#variable-sets)
- [TFE Provider](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs)
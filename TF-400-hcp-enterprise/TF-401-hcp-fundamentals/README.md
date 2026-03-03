# TF-401: HCP Terraform Fundamentals

**Course**: TF-400 — HCP Terraform & Enterprise Features  
**Module**: TF-401  
**Duration**: 1.5 hours  
**Level**: 400 (Expert)  
**Prerequisites**: TF-300 (all courses), TF-305 (Workspaces & Remote State)

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- Explain what HCP Terraform is and how it differs from local Terraform
- Describe the difference between HCP Terraform (cloud) and Terraform Enterprise (self-hosted)
- Set up an HCP Terraform organization and workspace
- Connect a VCS repository to trigger automated runs
- Authenticate using `terraform login` and API tokens
- Understand the three workspace types: VCS-driven, CLI-driven, and API-driven
- Migrate existing local state to HCP Terraform

---

## 📚 What is HCP Terraform?

**HCP Terraform** (formerly Terraform Cloud) is HashiCorp's managed platform for collaborative Terraform workflows. It provides:

- **Remote state storage** — no more local `.tfstate` files
- **Remote plan & apply** — runs execute in HCP Terraform's infrastructure, not your laptop
- **Team collaboration** — multiple engineers can work on the same infrastructure safely
- **VCS integration** — pull requests trigger speculative plans automatically
- **Policy enforcement** — Sentinel policies gate deployments (Enterprise/Plus)
- **Audit logging** — full history of who changed what and when

### HCP Terraform vs Terraform Enterprise

| Feature | HCP Terraform (Free) | HCP Terraform (Plus/Business) | Terraform Enterprise |
|---------|---------------------|-------------------------------|---------------------|
| Remote state | ✅ | ✅ | ✅ |
| Remote runs | ✅ (500 runs/month) | ✅ Unlimited | ✅ Unlimited |
| VCS integration | ✅ | ✅ | ✅ |
| Team management | ✅ (5 users) | ✅ Unlimited | ✅ Unlimited |
| Sentinel policies | ❌ | ✅ | ✅ |
| Audit logging | ❌ | ✅ | ✅ |
| Self-hosted | ❌ | ❌ | ✅ |
| Air-gapped | ❌ | ❌ | ✅ |
| SSO/SAML | ❌ | ✅ | ✅ |

**Key distinction**: HCP Terraform is SaaS (HashiCorp manages the infrastructure). Terraform Enterprise is self-hosted (you manage the infrastructure, typically on-premises or in your own cloud account).

---

## 📖 Topics Covered

### 1. HCP Terraform Architecture

```
Developer Laptop          HCP Terraform              Your Infrastructure
─────────────────         ─────────────────          ──────────────────
terraform plan    ──────► Remote Execution   ──────► AWS / Azure / GCP
terraform apply           (HCP manages)              Libvirt / VMware
                          State Storage              Any Provider
                          Policy Checks
                          Audit Logs
```

**What runs where**:
- `terraform init` — runs locally (downloads providers)
- `terraform plan` — runs in HCP Terraform (remote execution)
- `terraform apply` — runs in HCP Terraform (remote execution)
- State file — stored in HCP Terraform (encrypted at rest)

### 2. Workspace Types

HCP Terraform has three workspace types:

#### VCS-Driven (Recommended for teams)
- Connected to a Git repository
- Plans trigger automatically on pull requests
- Applies trigger on merge to main branch
- Full GitOps workflow

#### CLI-Driven (Recommended for migration)
- `terraform plan` and `terraform apply` run from your terminal
- Execution happens remotely in HCP Terraform
- State stored remotely
- Easiest migration path from local Terraform

#### API-Driven (For automation)
- Triggered via HCP Terraform API
- Used in CI/CD pipelines (GitHub Actions, etc.)
- Full programmatic control

### 3. Authentication

```bash
# Authenticate with HCP Terraform
terraform login

# This opens a browser to app.terraform.io
# Creates a token stored in ~/.terraform.d/credentials.tfrc.json
```

The token is used automatically by Terraform when the `cloud` block is configured.

---

## 🔧 Examples

### Example 1: Basic `cloud` Block Configuration

See [`examples/01-cloud-block/`](examples/01-cloud-block/) for a complete working example.

```hcl
# main.tf — CLI-driven workspace
terraform {
  required_version = ">= 1.1"

  cloud {
    organization = "my-organization"

    workspaces {
      name = "my-first-workspace"
    }
  }

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

resource "local_file" "example" {
  content  = "Hello from HCP Terraform!"
  filename = "${path.module}/output/hello.txt"
}
```

### Example 2: Workspace Tags (Multiple Workspaces)

```hcl
# Use tags to target multiple workspaces
terraform {
  cloud {
    organization = "my-organization"

    workspaces {
      tags = ["environment:production", "team:platform"]
    }
  }
}
```

### Example 3: Migrating Local State to HCP Terraform

```hcl
# Step 1: Add cloud block to existing configuration
terraform {
  cloud {
    organization = "my-organization"
    workspaces {
      name = "migrated-workspace"
    }
  }
}

# Step 2: Run terraform init
# Terraform detects existing local state and offers to migrate it
# terraform init
# > Would you like to copy existing state to the new backend? yes
```

### Example 4: VCS-Driven Workspace (GitHub)

When connecting a GitHub repository to HCP Terraform:

1. **In HCP Terraform UI**: Create workspace → Version control workflow → Connect to GitHub
2. **Select repository** and branch (e.g., `main`)
3. **Set working directory** if Terraform files are in a subdirectory
4. **Configure variables** in the workspace (replaces `.tfvars` files)

The workspace then:
- Runs `terraform plan` on every pull request (speculative plan)
- Runs `terraform apply` when PR is merged to `main`

---

## 🔑 Key Concepts

### Organization
The top-level container in HCP Terraform. Contains workspaces, teams, and policies. Maps to a company or team.

### Workspace
The unit of infrastructure in HCP Terraform. Each workspace has:
- Its own state file
- Its own variables
- Its own run history
- Its own permissions

### Run
A single execution of `terraform plan` + `terraform apply`. Runs are queued and executed sequentially per workspace.

### Variable Sets
Reusable collections of variables that can be applied to multiple workspaces. Ideal for shared credentials (e.g., AWS access keys applied to all AWS workspaces).

---

## 🏋️ Hands-On Lab

### Lab: Set Up Your First HCP Terraform Workspace

**Prerequisites**: Free HCP Terraform account at [app.terraform.io](https://app.terraform.io)

1. **Create an organization** in HCP Terraform
2. **Authenticate** with `terraform login`
3. **Configure** the `cloud` block in the example
4. **Run** `terraform init` to connect to HCP Terraform
5. **Run** `terraform plan` — observe it runs remotely
6. **Run** `terraform apply` — state is stored in HCP Terraform
7. **View** the run in the HCP Terraform UI
8. **Explore** the state file in the UI (Workspaces → States)

### Lab: Migrate Local State

1. Start with a local Terraform configuration (no backend)
2. Add the `cloud` block
3. Run `terraform init` and accept the state migration prompt
4. Verify state is now in HCP Terraform
5. Delete the local `.tfstate` file

---

## 📋 Key Takeaways

| Concept | Key Point |
|---------|-----------|
| HCP Terraform | SaaS platform for team Terraform workflows |
| Terraform Enterprise | Self-hosted version for air-gapped/compliance needs |
| `cloud` block | Replaces `backend` block for HCP Terraform |
| CLI-driven | Easiest migration path from local Terraform |
| VCS-driven | Best for team GitOps workflows |
| `terraform login` | Authenticates with HCP Terraform |
| State migration | `terraform init` handles it automatically |

---

## ⚠️ Important Notes

- **Free tier**: 500 free runs/month, 5 users — sufficient for learning
- **No credit card required** for free tier
- **State is encrypted** at rest in HCP Terraform
- **Runs are ephemeral** — HCP Terraform spins up a container, runs Terraform, then destroys it
- **Providers are downloaded** in each run — ensure your provider versions are pinned

---

## 🔗 Next Steps

- **[TF-402](../TF-402-remote-runs/README.md)**: Remote Runs & VCS Integration
- **[TF-403](../TF-403-security-access/README.md)**: Security & Access Control
- **[TF-404](../TF-404-sentinel-policies/README.md)**: Sentinel Policy as Code

---

## 📚 References

- [HCP Terraform Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [Terraform `cloud` Block](https://developer.hashicorp.com/terraform/language/settings/terraform-cloud)
- [HCP Terraform Free Tier](https://app.terraform.io/public/signup/account)
- [Migrating to HCP Terraform](https://developer.hashicorp.com/terraform/tutorials/cloud/cloud-migrate)
# TF-403: HCP Terraform Security & Access Control

**Course**: TF-400 — HCP Terraform & Enterprise Features  
**Module**: TF-403  
**Duration**: 1 hour  
**Level**: 400 (Expert)  
**Prerequisites**: TF-402 (Remote Runs & VCS Integration)

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- Configure teams and permissions in HCP Terraform
- Understand organization-level vs workspace-level permissions
- Manage teams and access using the `tfe` provider (meta-Terraform)
- Configure variable sets for shared secrets without hardcoding credentials
- Implement dynamic provider credentials using OIDC (no long-lived secrets)
- Understand audit logging capabilities (Enterprise feature)

---

## 📚 Security Model in HCP Terraform

HCP Terraform uses a layered security model:

```
Organization Level
├── Organization Owners (full admin)
├── Teams (groups of users)
│   ├── Platform Team → manage workspaces
│   ├── App Team → read/plan/apply specific workspaces
│   └── Read-Only Team → view state and runs
│
└── Workspace Level
    ├── Workspace-specific team permissions
    ├── Variables (workspace-scoped)
    └── Variable Sets (organization-scoped, applied to workspaces)
```

---

## 📖 Topics Covered

### 1. Teams and Permissions

HCP Terraform uses **teams** to manage access. Teams are groups of users with defined permissions.

#### Organization-Level Permissions

| Permission | Description |
|-----------|-------------|
| `manage_policies` | Create/edit/delete Sentinel policies |
| `manage_workspaces` | Create/delete workspaces |
| `manage_vcs_settings` | Configure VCS connections |
| `manage_membership` | Add/remove organization members |
| `read_workspaces` | View all workspaces |
| `read_projects` | View all projects |

#### Workspace-Level Permissions

| Permission | Plan | Apply | State | Variables | Settings |
|-----------|------|-------|-------|-----------|----------|
| `read` | ✅ | ❌ | ✅ | ❌ | ❌ |
| `plan` | ✅ | ❌ | ✅ | ❌ | ❌ |
| `write` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `admin` | ✅ | ✅ | ✅ | ✅ | ✅ |

### 2. Variable Sets for Shared Secrets

Instead of hardcoding credentials in each workspace, use **variable sets**:

```
Without Variable Sets (BAD):
  workspace-1: AWS_ACCESS_KEY_ID = "AKIA..."  ← duplicated
  workspace-2: AWS_ACCESS_KEY_ID = "AKIA..."  ← duplicated
  workspace-3: AWS_ACCESS_KEY_ID = "AKIA..."  ← duplicated

With Variable Sets (GOOD):
  Variable Set "AWS Credentials":
    AWS_ACCESS_KEY_ID = "AKIA..."  ← defined once
    AWS_SECRET_ACCESS_KEY = "..."  ← defined once
  Applied to: workspace-1, workspace-2, workspace-3
```

When credentials rotate, update them in **one place** — the variable set.

### 3. Dynamic Provider Credentials (OIDC)

The most secure approach: **no long-lived credentials at all**.

HCP Terraform supports **OIDC (OpenID Connect)** for dynamic credentials:

1. HCP Terraform acts as an OIDC identity provider
2. Cloud providers (AWS, Azure, GCP) trust HCP Terraform's OIDC tokens
3. When a run starts, HCP Terraform requests a short-lived token from the cloud provider
4. The token expires when the run ends — no persistent credentials

```
HCP Terraform Run
      │
      ├── Requests OIDC token from AWS STS
      │   (proves identity via JWT signed by HCP Terraform)
      │
      ├── AWS validates the JWT and issues temporary credentials
      │   (valid for the duration of the run only)
      │
      └── Terraform uses temporary credentials to manage AWS resources
```

**Benefits**:
- No `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` stored anywhere
- Credentials expire automatically
- Full audit trail in AWS CloudTrail
- Follows principle of least privilege

### 4. Audit Logging (Enterprise/Plus)

HCP Terraform Plus and Enterprise provide audit logs for:
- Who triggered a run
- Who approved an apply
- Who changed workspace variables
- Who modified team permissions
- Policy evaluation results

Audit logs can be streamed to external SIEM systems.

---

## 🔧 Examples

### Example 1: Team Configuration via Terraform

See [`examples/01-team-management/`](examples/01-team-management/) for a complete working example.

```hcl
# Create teams with different permission levels
resource "tfe_team" "platform" {
  name         = "platform-team"
  organization = var.organization

  organization_access {
    manage_workspaces = true
    manage_policies   = true
  }
}

resource "tfe_team" "developers" {
  name         = "developers"
  organization = var.organization
  # No organization-level permissions — workspace-level only
}

# Grant developers write access to the application workspace
resource "tfe_team_access" "dev_app_access" {
  access       = "write"
  team_id      = tfe_team.developers.id
  workspace_id = tfe_workspace.application.id
}
```

### Example 2: Dynamic Credentials (OIDC for AWS)

```hcl
# In HCP Terraform workspace settings, configure:
# Environment Variables (set in workspace or variable set):
#   TFC_AWS_PROVIDER_AUTH = "true"
#   TFC_AWS_RUN_ROLE_ARN  = "arn:aws:iam::123456789:role/hcp-terraform-role"

# Then in your Terraform configuration — NO credentials needed:
provider "aws" {
  region = "us-east-1"
  # HCP Terraform automatically injects temporary credentials via OIDC
  # No access_key or secret_key required
}

# AWS IAM role trust policy (configured in AWS, not Terraform):
# {
#   "Effect": "Allow",
#   "Principal": {
#     "Federated": "arn:aws:iam::123456789:oidc-provider/app.terraform.io"
#   },
#   "Action": "sts:AssumeRoleWithWebIdentity",
#   "Condition": {
#     "StringEquals": {
#       "app.terraform.io:aud": "aws.workload.identity",
#       "app.terraform.io:sub": "organization:my-org:workspace:production:run_phase:apply"
#     }
#   }
# }
```

---

## 🏋️ Hands-On Lab

### Lab: Configure Teams and Permissions

1. In HCP Terraform, create two teams: `platform-team` and `developers`
2. Add yourself to both teams
3. Create a workspace and grant `developers` team `plan` access
4. Verify that `developers` can plan but not apply

### Lab: Variable Sets

1. Create a variable set "Shared Config"
2. Add a Terraform variable `environment = "training"`
3. Apply the variable set to two workspaces
4. Verify both workspaces inherit the variable

---

## 📋 Key Takeaways

| Concept | Key Point |
|---------|-----------|
| Teams | Groups of users with defined permissions |
| Workspace permissions | read / plan / write / admin |
| Variable sets | Reusable variables — define once, apply to many workspaces |
| Dynamic credentials | OIDC — no long-lived secrets stored in HCP Terraform |
| Audit logging | Full history of who changed what (Plus/Enterprise) |

---

## ⚠️ Security Best Practices

1. **Use dynamic credentials (OIDC)** instead of static access keys
2. **Use variable sets** for shared credentials — never duplicate
3. **Mark sensitive variables** as sensitive in HCP Terraform
4. **Use least-privilege teams** — developers get `plan`, not `admin`
5. **Enable audit logging** in production (requires Plus/Enterprise)
6. **Rotate API tokens** regularly

---

## 🔗 Next Steps

- **[TF-404](../TF-404-sentinel-policies/README.md)**: Sentinel Policy as Code

---

## 📚 References

- [HCP Terraform Teams](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/teams)
- [Dynamic Provider Credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials)
- [Variable Sets](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/variables/managing-variables#variable-sets)
- [TFE Provider - Teams](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/team)
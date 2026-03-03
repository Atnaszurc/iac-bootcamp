# TF-400: HCP Terraform & Enterprise Features

**Level**: 400 (Expert)
**Duration**: 6 hours
**Prerequisites**: TF-300 (all courses), TF-305 (Workspaces & Remote State)
**Cost**: Free tier available (Sentinel requires Plus/Enterprise; Stacks requires HCP Terraform)

---

## 🎯 Course Overview

This expert-level course covers **HCP Terraform** (formerly Terraform Cloud) — HashiCorp's managed platform for team-based Terraform workflows. You will learn how to move from solo local Terraform to a collaborative, policy-enforced, enterprise-grade infrastructure workflow.

This is the natural progression after mastering core Terraform. It covers the full HashiCorp-native CI/CD story: remote execution, VCS integration, team access control, dynamic credentials, and Sentinel policy enforcement.

---

## 📚 What You'll Learn

### Core Skills
- ✅ Set up and configure HCP Terraform organizations and workspaces
- ✅ Migrate local state to HCP Terraform
- ✅ Configure VCS-driven GitOps workflows (GitHub → HCP Terraform)
- ✅ Understand speculative plans on pull requests
- ✅ Configure workspace-to-workspace run triggers
- ✅ Manage teams and permissions with RBAC
- ✅ Implement dynamic provider credentials (OIDC — no long-lived secrets)
- ✅ Write and test Sentinel policies
- ✅ Configure policy sets with enforcement levels
- ✅ Manage HCP Terraform itself with Terraform (meta-Terraform)

### Enterprise Concepts
- ✅ HCP Terraform vs Terraform Enterprise (self-hosted)
- ✅ Workspace types: VCS-driven, CLI-driven, API-driven
- ✅ Variable sets for shared credentials
- ✅ Audit logging and compliance
- ✅ Sentinel enforcement levels: advisory, soft-mandatory, hard-mandatory
- ✅ Terraform Stacks — orchestrating multiple configurations as a unit (1.13+)

---

## 📋 Course Modules

```
TF-400: HCP Terraform & Enterprise Features (5 hours)
├── TF-401: HCP Terraform Fundamentals (1.5h)
│   ├── What is HCP Terraform? Free vs paid tiers
│   ├── HCP Terraform vs Terraform Enterprise
│   ├── Workspace types (VCS-driven, CLI-driven, API-driven)
│   ├── terraform login and API token setup
│   └── Migrating local state to HCP Terraform
│
├── TF-402: Remote Runs & VCS Integration (1.5h)
│   ├── Remote plan and apply workflow
│   ├── VCS-driven workspaces (GitHub integration)
│   ├── Speculative plans on pull requests
│   ├── Run triggers (workspace-to-workspace dependencies)
│   └── Workspace variables vs variable sets
│
├── TF-403: Security & Access Control (1h)
│   ├── Teams and RBAC (organization vs workspace permissions)
│   ├── Variable sets for shared secrets
│   ├── Dynamic provider credentials (OIDC — no long-lived secrets)
│   └── Audit logging (Plus/Enterprise)
│
├── TF-404: Sentinel Policy as Code (1h)
│   ├── Sentinel overview and enforcement levels
│   ├── Sentinel vs OPA/Rego — when to use each
│   ├── Writing policies with tfplan/v2 import
│   ├── Testing policies with mock data
│   └── Policy sets and VCS-connected policies
│
└── TF-405: Terraform Stacks (1h) ✨ NEW — Terraform 1.13+
    ├── What are Stacks? Components and Deployments
    ├── .tfstack.hcl and .tfdeploy.hcl file types
    ├── Stacks vs Workspaces vs separate configurations
    ├── Provider configuration in Stacks
    ├── terraform stacks CLI commands
    └── When to use Stacks (and when not to)
```

---

## 🗂️ Directory Structure

```
TF-400-hcp-enterprise/
├── README.md                              # This file
│
├── TF-401-hcp-fundamentals/
│   ├── README.md                          # Module overview
│   └── examples/
│       ├── 01-cloud-block/               # CLI-driven workspace setup
│       │   └── main.tf
│       └── 02-state-migration/           # Migrating local state
│           └── main.tf
│
├── TF-402-remote-runs/
│   ├── README.md                          # Module overview
│   └── examples/
│       ├── 01-vcs-workspace/             # VCS-driven workspace config
│       │   └── main.tf
│       └── 02-run-triggers/              # Workspace dependencies
│           └── main.tf
│
├── TF-403-security-access/
│   ├── README.md                          # Module overview
│   └── examples/
│       └── 01-team-management/           # Teams, permissions, variable sets
│           └── main.tf
│
├── TF-404-sentinel-policies/
│   ├── README.md                          # Module overview
│   └── examples/
│       ├── 01-restrict-memory/           # Sentinel policy + mock tests
│       │   ├── restrict-vm-memory.sentinel
│       │   └── test/restrict-vm-memory/
│       │       ├── pass-small-vm.json
│       │       └── fail-large-vm.json
│       └── 02-policy-set/               # Policy set configuration
│           └── main.tf
│
└── TF-405-stacks/
    └── README.md                          # Stacks overview (conceptual — requires HCP Terraform)
```

---

## 🚀 Getting Started

### Prerequisites

1. **Complete TF-300** — especially TF-305 (Workspaces & Remote State)
2. **Create a free HCP Terraform account** at [app.terraform.io](https://app.terraform.io)
3. **Authenticate** with `terraform login`

### Free Tier Limitations

The HCP Terraform free tier includes:
- ✅ Remote state storage (unlimited)
- ✅ Remote plan & apply (500 runs/month)
- ✅ VCS integration
- ✅ Up to 5 users
- ❌ Sentinel policies (requires Plus/Business)
- ❌ Audit logging (requires Plus/Business)
- ❌ SSO/SAML (requires Plus/Business)

**For TF-401, TF-402, TF-403**: Free tier is sufficient.
**For TF-404 (Sentinel)**: Requires Plus/Business tier or Terraform Enterprise.
**For TF-405 (Stacks)**: Requires HCP Terraform with Stacks enabled — check current [pricing](https://www.hashicorp.com/products/terraform/pricing).

---

## 🔑 Key Concepts Summary

| Concept | Description |
|---------|-------------|
| `cloud` block | Replaces `backend` block for HCP Terraform |
| Workspace | Unit of infrastructure — has its own state, variables, runs |
| VCS-driven | GitOps: PRs trigger plans, merges trigger applies |
| Speculative plan | Read-only plan on PRs — shows diff without applying |
| Run trigger | Workspace A applies → triggers workspace B |
| Variable set | Reusable variables applied to multiple workspaces |
| OIDC | Dynamic credentials — no long-lived secrets stored |
| Sentinel | Policy-as-code gate between plan and apply |
| `soft-mandatory` | Policy blocks apply, but admins can override |
| `hard-mandatory` | Policy always blocks — no override possible |
| TFE provider | Manage HCP Terraform resources with Terraform |
| Stack | Multiple Terraform configs managed as a unit |
| Component | A Terraform config within a Stack |
| Deployment | An instance of a Stack (like a workspace for the whole Stack) |
| `.tfstack.hcl` | Stack definition file (components, providers) |
| `.tfdeploy.hcl` | Deployment configuration file |

---

## 🏋️ Learning Path

### Recommended Order

1. **TF-401** — Set up HCP Terraform, authenticate, create first workspace
2. **TF-402** — Connect to GitHub, configure VCS-driven workflow
3. **TF-403** — Set up teams, configure OIDC dynamic credentials
4. **TF-404** — Write Sentinel policies, configure policy sets
5. **TF-405** — Learn Terraform Stacks for multi-config orchestration (conceptual + design)

### Time Estimates

| Module | Duration | Hands-On |
|--------|----------|----------|
| TF-401 | 1.5 hours | 45 min |
| TF-402 | 1.5 hours | 45 min |
| TF-403 | 1 hour | 30 min |
| TF-404 | 1 hour | 30 min |
| TF-405 | 1 hour | 30 min (conceptual) |
| **Total** | **6 hours** | **3 hours** |

---

## ⚠️ Important Notes

### Testing Limitations
- **TF-401, TF-402, TF-403**: Can be fully tested with a free HCP Terraform account
- **TF-404 (Sentinel)**: Requires HCP Terraform Plus/Business or Terraform Enterprise
- **TF-405 (Stacks)**: Requires HCP Terraform with Stacks enabled; the module is conceptual/awareness-focused
- The `tfe` provider examples (TF-402, TF-403, TF-404) require an organization owner API token

### Meta-Terraform Pattern
Several examples in this course use the `tfe` provider to manage HCP Terraform resources with Terraform itself. This is called "meta-Terraform" — Terraform managing Terraform. This is a powerful pattern for:
- Keeping HCP Terraform configuration in version control
- Applying the same IaC principles to your CI/CD platform
- Automating workspace and team provisioning

---

## 🔗 Navigation

| Module | Topic | Duration |
|--------|-------|----------|
| [TF-401](TF-401-hcp-fundamentals/README.md) | HCP Terraform Fundamentals | 1.5h |
| [TF-402](TF-402-remote-runs/README.md) | Remote Runs & VCS Integration | 1.5h |
| [TF-403](TF-403-security-access/README.md) | Security & Access Control | 1h |
| [TF-404](TF-404-sentinel-policies/README.md) | Sentinel Policy as Code | 1h |
| [TF-405](TF-405-stacks/README.md) | Terraform Stacks (1.13+) | 1h |

---

## 📚 References

- [HCP Terraform Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [Terraform Enterprise Documentation](https://developer.hashicorp.com/terraform/enterprise)
- [TFE Provider Documentation](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs)
- [Sentinel Documentation](https://developer.hashicorp.com/sentinel)
- [Dynamic Provider Credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials)
- [Terraform Stacks Documentation](https://developer.hashicorp.com/terraform/language/stacks)
- [HCP Terraform Stacks](https://developer.hashicorp.com/terraform/cloud-docs/stacks)
- [HCP Terraform Pricing](https://www.hashicorp.com/products/terraform/pricing)

---

**← [Back to Training Root](../README.md)**
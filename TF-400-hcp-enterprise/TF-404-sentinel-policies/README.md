# TF-404: Sentinel Policy as Code (Enterprise)

**Course**: TF-400 — HCP Terraform & Enterprise Features  
**Module**: TF-404  
**Duration**: 1 hour  
**Level**: 400 (Expert)  
**Prerequisites**: TF-403 (Security & Access Control), TF-304 (Policy as Code - OPA/Rego)

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- Explain what Sentinel is and how it integrates with HCP Terraform
- Understand the three enforcement levels: advisory, soft-mandatory, hard-mandatory
- Write basic Sentinel policies using the `tfplan/v2` import
- Test Sentinel policies using mock data
- Configure policy sets in HCP Terraform
- Understand the four Sentinel imports: `tfplan`, `tfconfig`, `tfstate`, `tfrun`
- Compare Sentinel (HashiCorp) vs OPA/Rego (open source) — when to use each

---

## 📚 What is Sentinel?

**Sentinel** is HashiCorp's policy-as-code framework, embedded directly into HCP Terraform (Plus/Business) and Terraform Enterprise. It evaluates policies **between the plan and apply phases** — acting as a gate that can block deployments that violate organizational rules.

```
terraform plan
      │
      ▼
  Sentinel Policy Evaluation  ◄── Policies run here
      │
      ├── PASS → terraform apply proceeds
      └── FAIL → apply blocked (or warned, depending on enforcement level)
```

### Sentinel vs OPA/Rego

| Feature | Sentinel | OPA/Rego |
|---------|----------|----------|
| Integration | Native HCP Terraform | External (CI/CD pipeline) |
| Language | Sentinel (Python-like) | Rego (Datalog-like) |
| Enforcement | Built into run lifecycle | External check |
| Testing | Built-in mock framework | OPA test framework |
| Cost | HCP Terraform Plus/Enterprise | Free/open source |
| Use case | HCP Terraform gate | Any system, any format |

**When to use Sentinel**: You're using HCP Terraform Plus/Enterprise and want policies enforced as part of the run lifecycle — not as a separate CI step.

**When to use OPA/Rego** (TF-304): You need provider-agnostic policies, open-source tooling, or policies that apply outside of HCP Terraform.

---

## 📖 Topics Covered

### 1. Enforcement Levels

Sentinel has three enforcement levels that control what happens when a policy fails:

| Level | Behavior | Use Case |
|-------|----------|----------|
| `advisory` | Policy failure is logged but apply proceeds | Gradual rollout, informational |
| `soft-mandatory` | Policy failure blocks apply, but workspace admins can override | Most policies |
| `hard-mandatory` | Policy failure always blocks apply — no override possible | Compliance, security |

### 2. Sentinel Imports

Sentinel policies access Terraform data through **imports**:

| Import | Data Available |
|--------|---------------|
| `tfplan/v2` | Planned resource changes (what will be created/modified/destroyed) |
| `tfconfig/v2` | Terraform configuration (variables, providers, modules) |
| `tfstate/v2` | Current state (existing resources) |
| `tfrun` | Run metadata (workspace name, organization, triggered by) |

### 3. Policy Structure

```python
# Sentinel policy structure
import "tfplan/v2" as tfplan

# 1. Filter resources of interest
vms = filter tfplan.resource_changes as _, rc {
  rc.type is "libvirt_domain" and
  rc.mode is "managed" and
  rc.change.actions contains "create"
}

# 2. Define rules
rule_memory_limit = rule {
  all vms as _, vm {
    vm.change.after.memory <= 4096
  }
}

# 3. Main rule — the policy passes if main is true
main = rule { rule_memory_limit }
```

### 4. Policy Sets

A **policy set** is a collection of Sentinel policies applied to workspaces. Policy sets can be:
- Applied to specific workspaces
- Applied to all workspaces in an organization
- Connected to a VCS repository (policies-as-code in Git)

---

## 🔧 Examples

### Example 1: Restrict VM Memory

See [`examples/01-restrict-memory/`](examples/01-restrict-memory/) for the complete policy.

```python
# policy: restrict-vm-memory.sentinel
# Prevents VMs from being created with more than 4GB RAM in non-prod workspaces

import "tfplan/v2" as tfplan
import "tfrun"

# Only enforce in non-production workspaces
is_production = tfrun.workspace.name contains "production"

# Get all libvirt_domain resources being created or modified
vms = filter tfplan.resource_changes as _, rc {
  rc.type is "libvirt_domain" and
  rc.mode is "managed" and
  (rc.change.actions contains "create" or rc.change.actions contains "update")
}

# Rule: non-prod VMs cannot exceed 4GB RAM (4096 MB)
max_memory_non_prod = rule when not is_production {
  all vms as _, vm {
    int(vm.change.after.memory) <= 4096
  }
}

main = rule { max_memory_non_prod }
```

### Example 2: Require Resource Tags

```python
# policy: require-tags.sentinel
# All resources must have required tags

import "tfplan/v2" as tfplan

required_tags = ["environment", "team", "cost-center"]

# Get all resources being created
all_resources = filter tfplan.resource_changes as _, rc {
  rc.mode is "managed" and
  rc.change.actions contains "create"
}

# Check each resource has all required tags
has_required_tags = rule {
  all all_resources as _, resource {
    all required_tags as tag {
      resource.change.after.tags[tag] is not null and
      resource.change.after.tags[tag] is not ""
    }
  }
}

main = rule { has_required_tags }
```

### Example 3: Policy Set Configuration (via TFE Provider)

See [`examples/02-policy-set/`](examples/02-policy-set/) for the complete example.

```hcl
# Configure a policy set connected to a VCS repository
resource "tfe_policy_set" "security_policies" {
  name          = "security-policies"
  description   = "Organization-wide security policies"
  organization  = var.organization
  kind          = "sentinel"

  # Connect to VCS repository containing .sentinel files
  vcs_repo {
    identifier         = "my-org/sentinel-policies"
    branch             = "main"
    ingress_submodules = false
    oauth_token_id     = var.oauth_token_id
  }

  # Apply to all workspaces (or specify workspace_ids for targeted application)
  global = true
}

# Individual policy with enforcement level
resource "tfe_sentinel_policy" "restrict_memory" {
  name         = "restrict-vm-memory"
  description  = "Prevents oversized VMs in non-production workspaces"
  organization = var.organization
  policy       = file("${path.module}/policies/restrict-vm-memory.sentinel")
  enforce_mode = "soft-mandatory"
}
```

### Example 4: Mock Data for Testing

Sentinel policies can be tested locally using mock data:

```python
# test/restrict-vm-memory/pass.json (mock data)
{
  "mock": {
    "tfplan/v2": {
      "resource_changes": {
        "libvirt_domain.web": {
          "type": "libvirt_domain",
          "mode": "managed",
          "change": {
            "actions": ["create"],
            "after": {
              "name": "web-server",
              "memory": 2048,
              "vcpu": 2
            }
          }
        }
      }
    }
  },
  "test": {
    "main": true
  }
}
```

```bash
# Test the policy locally
sentinel test restrict-vm-memory.sentinel
# PASS - restrict-vm-memory.sentinel
```

---

## 🏋️ Hands-On Lab

### Lab: Write Your First Sentinel Policy

> **Note**: Requires HCP Terraform Plus or Enterprise tier.

1. Create a Sentinel policy file `restrict-vm-memory.sentinel`
2. Create mock test data for pass and fail cases
3. Test locally with `sentinel test`
4. Upload the policy to HCP Terraform
5. Create a policy set and apply it to a workspace
6. Run `terraform plan` and observe the policy evaluation

### Lab: Policy Enforcement Levels

1. Create a policy with `advisory` enforcement
2. Intentionally violate the policy
3. Observe that the apply proceeds with a warning
4. Change enforcement to `soft-mandatory`
5. Observe that the apply is blocked (but can be overridden by workspace admin)
6. Change enforcement to `hard-mandatory`
7. Observe that the apply is blocked with no override option

---

## 📋 Key Takeaways

| Concept | Key Point |
|---------|-----------|
| Sentinel | HashiCorp's policy-as-code, native to HCP Terraform |
| `advisory` | Warns but doesn't block |
| `soft-mandatory` | Blocks but admins can override |
| `hard-mandatory` | Always blocks — no override |
| `tfplan/v2` | Access planned changes in policies |
| `tfrun` | Access workspace/run metadata |
| Policy sets | Collections of policies applied to workspaces |
| Mock testing | Test policies locally without HCP Terraform |

---

## ⚠️ Important Notes

- **Sentinel requires HCP Terraform Plus or Business tier** (or Terraform Enterprise)
- The free tier of HCP Terraform does **not** include Sentinel
- Sentinel policies run **after** `terraform plan` and **before** `terraform apply`
- Policies are evaluated against the **plan output**, not the actual infrastructure
- Use `advisory` enforcement when rolling out new policies to avoid disruption

---

## 🔗 Course Complete!

You have completed the TF-400 course. You now have expert-level knowledge of:
- HCP Terraform fundamentals and workspace types
- Remote runs and VCS-driven GitOps workflows
- Team management and dynamic credentials (OIDC)
- Sentinel policy enforcement

**[← Back to TF-400 Course Overview](../README.md)**

---

## 📚 References

- [Sentinel Documentation](https://developer.hashicorp.com/sentinel)
- [Sentinel in HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement/sentinel)
- [Sentinel Language Spec](https://developer.hashicorp.com/sentinel/docs/language)
- [tfplan/v2 Import](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement/sentinel/import/tfplan-v2)
- [Sentinel Simulator](https://developer.hashicorp.com/sentinel/docs/commands/apply)
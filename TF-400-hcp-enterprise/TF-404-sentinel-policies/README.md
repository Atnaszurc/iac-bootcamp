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

This module includes **4 complete Sentinel policy examples** with test cases:

### Example 1: Restrict VM Memory

**Location**: [`examples/01-restrict-memory/`](examples/01-restrict-memory/)
**Tests**: 2 (pass-small-vm, fail-large-vm)

Prevents VMs from being created with more than 4GB RAM in non-production workspaces.

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

---

### Example 2: Naming Conventions

**Location**: [`examples/02-naming-conventions/`](examples/02-naming-conventions/)
**Tests**: 4 (pass-compliant, fail-missing-name, fail-invalid-format, fail-invalid-environment)

Enforces standardized resource naming and environment tagging:
- Name tag must follow pattern: `<env>-<type>-<name>` (e.g., "dev-vm-web01")
- Environment tag must be one of: dev, staging, prod

```python
# policy: naming-conventions.sentinel
import "tfplan/v2" as tfplan
import "strings"

# Get all resources being created or updated
all_resources = filter tfplan.resource_changes as _, rc {
  rc.mode is "managed" and
  (rc.change.actions contains "create" or rc.change.actions contains "update")
}

# Rule 1: All resources must have a Name tag
has_name_tag = rule {
  all all_resources as _, resource {
    resource.change.after.tags contains "Name" and
    resource.change.after.tags["Name"] is not null and
    resource.change.after.tags["Name"] is not ""
  }
}

# Rule 2: Name tag must follow pattern: <env>-<type>-<name>
valid_name_format = rule {
  all all_resources as _, resource {
    resource.change.after.tags["Name"] matches "^(dev|staging|prod)-[a-z]+-[a-z0-9-]+$"
  }
}

# Rule 3: Environment tag must be valid
valid_environment = rule {
  all all_resources as _, resource {
    resource.change.after.tags["Environment"] in ["dev", "staging", "prod"]
  }
}

main = rule { has_name_tag and valid_name_format and valid_environment }
```

---

### Example 3: Security Standards

**Location**: [`examples/03-security-standards/`](examples/03-security-standards/)
**Tests**: 4 (pass-compliant, fail-world-writable, fail-missing-managed-by, fail-prod-missing-owner)

Enforces security best practices:
- Prevents world-writable file permissions (0777, 0666, etc.)
- Requires `ManagedBy = "terraform"` tag on all resources
- Requires `Owner` tag on production resources

```python
# policy: security-standards.sentinel
import "tfplan/v2" as tfplan
import "strings"

# Get all resources being created or updated
all_resources = filter tfplan.resource_changes as _, rc {
  rc.mode is "managed" and
  (rc.change.actions contains "create" or rc.change.actions contains "update")
}

# Rule 1: No world-writable permissions
no_world_writable = rule {
  all all_resources as _, resource {
    resource.change.after.mode else null not in ["0777", "0666", "0667", "0676", "0766"]
  }
}

# Rule 2: All resources must have ManagedBy = "terraform" tag
has_managed_by_tag = rule {
  all all_resources as _, resource {
    resource.change.after.tags["ManagedBy"] is "terraform"
  }
}

# Rule 3: Production resources must have Owner tag
production_has_owner = rule {
  all all_resources as _, resource {
    resource.change.after.tags["Environment"] is not "prod" or
    (resource.change.after.tags contains "Owner" and
     resource.change.after.tags["Owner"] is not null and
     resource.change.after.tags["Owner"] is not "")
  }
}

main = rule { no_world_writable and has_managed_by_tag and production_has_owner }
```

---

### Example 4: Policy Set Configuration

**Location**: [`examples/02-policy-set/`](examples/02-policy-set/)

Demonstrates how to configure policy sets using the TFE provider (meta-Terraform):

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

```hcl
# Configure a policy set connected to a VCS repository (meta-Terraform)
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

## 🏋️ Hands-On Labs

### Lab 1: Test Policies Locally

All 4 example policies include complete test suites. You can test them locally:

```bash
# Install Sentinel CLI (requires license for full features)
# Download from: https://releases.hashicorp.com/sentinel/

# Test a policy
cd examples/01-restrict-memory
sentinel test restrict-vm-memory.sentinel

# Test all policies
cd examples/02-naming-conventions
sentinel test naming-conventions.sentinel

cd examples/03-security-standards
sentinel test security-standards.sentinel
```

**Expected Results**:
- Example 1: 2/2 tests passing
- Example 2: 4/4 tests passing
- Example 3: 4/4 tests passing
- **Total**: 10/10 tests passing

### Lab 2: Upload to HCP Terraform

> **Note**: Requires HCP Terraform Plus or Enterprise tier.

1. Choose one of the example policies (e.g., `01-restrict-memory`)
2. In HCP Terraform UI, navigate to Settings → Policy Sets
3. Create a new policy set
4. Upload the `.sentinel` file
5. Configure enforcement level (`advisory`, `soft-mandatory`, or `hard-mandatory`)
6. Apply the policy set to a workspace
7. Run `terraform plan` in that workspace
8. Observe the policy evaluation in the run output

### Lab 3: Policy Enforcement Levels

1. Start with `advisory` enforcement on the naming-conventions policy
2. Create a resource that violates the naming convention
3. Observe that the apply proceeds with a warning
4. Change enforcement to `soft-mandatory`
5. Observe that the apply is blocked (but workspace admins can override)
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
| **4 Examples** | Complete policies with 10 passing tests total |
| OPA Equivalent | See TF-304 for open-source OPA/Rego versions |

---

## ⚠️ Important Notes

- **Sentinel requires HCP Terraform Plus or Business tier** (or Terraform Enterprise)
- The free tier of HCP Terraform does **not** include Sentinel
- Sentinel policies run **after** `terraform plan` and **before** `terraform apply`
- Policies are evaluated against the **plan output**, not the actual infrastructure
- Use `advisory` enforcement when rolling out new policies to avoid disruption

---

## 📊 Example Summary

| Example | Policy | Tests | Status |
|---------|--------|-------|--------|
| 01-restrict-memory | VM memory limits | 2 | ✅ Passing |
| 02-naming-conventions | Name/Environment tags | 4 | ✅ Passing |
| 03-security-standards | Security best practices | 4 | ✅ Passing |
| 02-policy-set | TFE provider config | N/A | ✅ Complete |
| **Total** | **3 policies** | **10 tests** | **100% pass rate** |

---

## 🔗 Next Steps

You have completed TF-404! You now understand:
- ✅ Sentinel policy structure and syntax
- ✅ Three enforcement levels and when to use each
- ✅ Writing policies with `tfplan/v2` import
- ✅ Testing policies with mock data
- ✅ Configuring policy sets in HCP Terraform
- ✅ Difference between Sentinel and OPA/Rego

**Continue to**: [TF-405: Terraform Stacks](../TF-405-stacks/README.md)
**Or return to**: [TF-400 Course Overview](../README.md)

---

## 📚 References

- [Sentinel Documentation](https://developer.hashicorp.com/sentinel)
- [Sentinel in HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement/sentinel)
- [Sentinel Language Spec](https://developer.hashicorp.com/sentinel/docs/language)
- [tfplan/v2 Import](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement/sentinel/import/tfplan-v2)
- [Sentinel Simulator](https://developer.hashicorp.com/sentinel/docs/commands/apply)
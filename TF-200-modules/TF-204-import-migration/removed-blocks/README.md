# TF-204 Supplement: `removed` Blocks (Terraform 1.7+)

**Course**: TF-204 Import & Migration Strategies  
**Section**: Supplement  
**Duration**: 20 minutes  
**Prerequisites**: TF-204 core content (import blocks, moved blocks)  
**Terraform Version**: 1.7+ (required for `removed` blocks)

---

## 📋 Overview

When you need to stop managing a resource with Terraform — without destroying it — the `removed` block (introduced in Terraform 1.7) is the clean, declarative solution. Before 1.7, the only option was `terraform state rm`, a manual CLI command with no audit trail. The `removed` block brings this operation into your configuration files, making it reviewable, repeatable, and safe.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Understand when to use `removed` blocks vs `terraform state rm`
- ✅ Remove resources from state while keeping them running
- ✅ Destroy resources using `removed` blocks with `destroy = true`
- ✅ Remove entire modules from state
- ✅ Combine `removed` blocks with `moved` blocks for safe refactoring
- ✅ Understand the lifecycle of a `removed` block

---

## 🔑 The Problem: Removing Resources from State

### Before Terraform 1.7 — Manual CLI Only

```bash
# ❌ Old way: manual, no audit trail, easy to make mistakes
terraform state rm aws_instance.web

# Problems:
# - Not in version control
# - No peer review
# - Easy to accidentally destroy instead of remove
# - No documentation of why it was removed
```

### After Terraform 1.7 — Declarative `removed` Block

```hcl
# ✅ New way: declarative, reviewable, in version control
removed {
  from = aws_instance.web

  lifecycle {
    destroy = false  # Keep the resource running, just stop managing it
  }
}
```

---

## 📚 `removed` Block Syntax

```hcl
removed {
  from = <resource_address>

  lifecycle {
    destroy = false | true
  }
}
```

| Field | Description |
|-------|-------------|
| `from` | The resource address to remove (same format as `moved` blocks) |
| `destroy = false` | Remove from state only — resource keeps running |
| `destroy = true` | Remove from state AND destroy the resource |

---

## 🔬 Use Case 1: Stop Managing a Resource (Keep It Running)

**Scenario**: You created a VM with Terraform, but now it needs to be managed manually (e.g., handed off to another team).

### Before (resource in config and state)

```hcl
resource "local_file" "handoff_server" {
  content  = "server config"
  filename = "/tmp/handoff-server.conf"
}
```

### After (remove from Terraform management, keep the file)

```hcl
# Step 1: Remove the resource block from your config
# Step 2: Add a removed block

removed {
  from = local_file.handoff_server

  lifecycle {
    destroy = false  # Keep the file, just stop tracking it
  }
}
```

```bash
terraform apply
# Output:
# local_file.handoff_server: Removing from state...
# local_file.handoff_server: Removal complete
#
# Apply complete! Resources: 0 added, 0 changed, 1 removed from state.
```

After `apply`, the file still exists on disk — Terraform just no longer tracks it.

---

## 🔬 Use Case 2: Remove and Destroy

**Scenario**: You want to remove a resource from state AND destroy it in one operation.

```hcl
removed {
  from = local_file.old_config

  lifecycle {
    destroy = true  # Remove from state AND delete the resource
  }
}
```

> **Note**: `destroy = true` is the default behavior when you simply delete a resource block. The `removed` block with `destroy = true` is useful when you want to be explicit and have the operation documented in your config.

---

## 🔬 Use Case 3: Remove an Entire Module

**Scenario**: You're decommissioning a module and want to stop managing all its resources.

```hcl
# Remove all resources in a module from state (keep them running)
removed {
  from = module.legacy_servers

  lifecycle {
    destroy = false
  }
}
```

This removes every resource inside `module.legacy_servers` from state in a single operation.

---

## 🔬 Use Case 4: Combining `removed` and `moved` Blocks

**Scenario**: You're migrating resources between modules. Some resources move to a new module, others are handed off.

```hcl
# Move web servers to new module
moved {
  from = module.old_app.libvirt_domain.web
  to   = module.new_app.libvirt_domain.web
}

# Remove database from Terraform management (handed to DBA team)
removed {
  from = module.old_app.libvirt_domain.database

  lifecycle {
    destroy = false
  }
}
```

---

## ⚠️ `removed` vs `terraform state rm` — Comparison

| Aspect | `removed` block | `terraform state rm` |
|--------|----------------|----------------------|
| **Version control** | ✅ In `.tf` files | ❌ CLI only |
| **Peer review** | ✅ Via PR/MR | ❌ No review |
| **Audit trail** | ✅ Git history | ❌ No history |
| **Terraform version** | 1.7+ required | Any version |
| **Plan preview** | ✅ Shows in `terraform plan` | ❌ Immediate |
| **Module support** | ✅ Entire modules | ✅ Individual resources |
| **Destroy option** | ✅ `destroy = true/false` | ❌ Always keeps resource |

---

## 🔄 Lifecycle of a `removed` Block

```
1. Add removed block to config
   ↓
2. Run terraform plan
   → Shows "will be removed from state"
   ↓
3. Run terraform apply
   → Resource removed from state
   → Resource itself kept (if destroy = false)
   ↓
4. Delete the removed block from config
   → Clean up after apply
   → No effect on state (already removed)
```

> **Important**: After `terraform apply` completes, you should delete the `removed` block from your configuration. It has served its purpose and leaving it in place is unnecessary (though harmless).

---

## 🧪 Hands-On Lab

### Lab: Remove Resources from State

```bash
mkdir tf204-removed-blocks
cd tf204-removed-blocks
```

**Step 1**: Create `main.tf` with initial resources:

```hcl
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Simulate a resource we'll hand off
resource "local_file" "managed_config" {
  content  = "# Managed by Terraform\nenv = dev"
  filename = "${path.module}/managed.conf"
}

# Simulate a resource we'll keep managing
resource "local_file" "permanent_config" {
  content  = "# Always managed by Terraform\nenv = prod"
  filename = "${path.module}/permanent.conf"
}
```

**Step 2**: Apply to create both files:

```bash
terraform init
terraform apply -auto-approve
ls *.conf  # Both files exist
terraform state list  # Both resources in state
```

**Step 3**: Simulate handoff — update `main.tf`:

```hcl
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# This resource is being handed off — remove from state, keep the file
removed {
  from = local_file.managed_config

  lifecycle {
    destroy = false
  }
}

# This resource stays managed
resource "local_file" "permanent_config" {
  content  = "# Always managed by Terraform\nenv = prod"
  filename = "${path.module}/permanent.conf"
}
```

**Step 4**: Plan and apply:

```bash
terraform plan
# Shows: local_file.managed_config will be removed from state

terraform apply -auto-approve
# local_file.managed_config: Removing from state...

terraform state list
# Only permanent_config remains in state

ls *.conf
# Both files still exist on disk!
```

**Step 5**: Clean up the `removed` block:

```hcl
# Remove the 'removed' block — it's done its job
# Only keep permanent_config resource
```

```bash
terraform plan
# No changes — clean state
terraform destroy -auto-approve
```

---

## ✅ Checkpoint Quiz

**Question 1**: What Terraform version introduced `removed` blocks?
- A) 1.5
- B) 1.6
- C) 1.7
- D) 1.9

<details>
<summary>Answer</summary>
**C) 1.7** — The `removed` block was introduced in Terraform 1.7.0. For earlier versions, use `terraform state rm`.
</details>

---

**Question 2**: What does `destroy = false` mean in a `removed` block?
- A) The resource will be destroyed and removed from state
- B) The resource will be removed from state but kept running
- C) The resource will not be removed from state
- D) The `removed` block will be ignored

<details>
<summary>Answer</summary>
**B) The resource will be removed from state but kept running** — `destroy = false` tells Terraform to stop tracking the resource without deleting it. The resource continues to exist outside of Terraform management.
</details>

---

**Question 3**: After `terraform apply` processes a `removed` block, what should you do?
- A) Leave the `removed` block in place permanently
- B) Run `terraform state rm` to complete the removal
- C) Delete the `removed` block from your configuration
- D) Add a `moved` block to replace it

<details>
<summary>Answer</summary>
**C) Delete the `removed` block from your configuration** — Once `apply` has processed the `removed` block, it has served its purpose. Delete it to keep your configuration clean. Leaving it in place is harmless but unnecessary.
</details>

---

## 📚 Key Takeaways

| Scenario | Solution |
|----------|----------|
| Stop managing a resource (keep it) | `removed` block with `destroy = false` |
| Remove and destroy a resource | `removed` block with `destroy = true` (or just delete the resource block) |
| Remove an entire module | `removed` block pointing to `module.name` |
| Rename/move a resource | `moved` block (not `removed`) |
| Legacy Terraform (< 1.7) | `terraform state rm` CLI command |

---

## 🔗 Next Steps

- **Related**: [TF-204 Core: Import & Migration Strategies](../README.md) — import blocks and state management
- **Related**: [TF-201 Supplement: `moved` Blocks](../../TF-201-module-design/moved-blocks/README.md) — the complement to `removed` blocks

---

## 📖 Additional Resources

- [removed block — Terraform Documentation](https://developer.hashicorp.com/terraform/language/resources/syntax#removing-resources)
- [Terraform 1.7 Release Notes](https://github.com/hashicorp/terraform/releases/tag/v1.7.0)
- [State Management — Terraform Documentation](https://developer.hashicorp.com/terraform/language/state)
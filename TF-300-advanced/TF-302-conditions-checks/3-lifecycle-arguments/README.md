# TF-302 Supplement: `lifecycle` Meta-Arguments (Complete Unit)

**Course**: TF-302 Pre/Post Conditions & Check Blocks  
**Section**: Supplement  
**Duration**: 25 minutes  
**Prerequisites**: TF-302 core content (pre/postconditions), TF-103 (Infrastructure Resources)  
**Terraform Version**: 1.0+ (most arguments), 1.2+ (`replace_triggered_by`)

---

## 📋 Overview

The `lifecycle` block controls how Terraform creates, updates, and destroys resources. While TF-302 covers `precondition` and `postcondition` inside `lifecycle`, the full set of lifecycle meta-arguments is equally important for production infrastructure. This section covers all five lifecycle arguments as a complete unit.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Use `create_before_destroy` for zero-downtime replacements
- ✅ Use `prevent_destroy` to protect critical resources
- ✅ Use `ignore_changes` to tolerate external drift
- ✅ Use `replace_triggered_by` to force replacement on dependency changes
- ✅ Combine lifecycle arguments with `precondition`/`postcondition`
- ✅ Identify anti-patterns and when NOT to use lifecycle arguments

---

## 🔑 All `lifecycle` Meta-Arguments at a Glance

```hcl
resource "example" "this" {
  # ... resource configuration ...

  lifecycle {
    create_before_destroy = true          # Replace: new first, then destroy old
    prevent_destroy       = true          # Block: error if destroy attempted
    ignore_changes        = [attribute]   # Drift: ignore external changes
    replace_triggered_by  = [dependency]  # Trigger: force replace on change (1.2+)

    precondition {                        # Validate: before resource is created/updated
      condition     = expression
      error_message = "message"
    }

    postcondition {                       # Validate: after resource is created/updated
      condition     = self.attribute != ""
      error_message = "message"
    }
  }
}
```

---

## 📚 `create_before_destroy`

### The Problem It Solves

By default, when Terraform needs to replace a resource (destroy + recreate), it:
1. Destroys the old resource
2. Creates the new resource

This causes **downtime**. With `create_before_destroy = true`:
1. Creates the new resource
2. Destroys the old resource

### Usage

```hcl
resource "local_file" "config" {
  content  = var.config_content
  filename = "/etc/app/config.conf"

  lifecycle {
    create_before_destroy = true
  }
}
```

### Real-World Example (VM replacement)

```hcl
resource "libvirt_domain" "web" {
  name   = var.vm_name
  memory = var.memory_mb
  vcpu   = var.vcpu_count

  lifecycle {
    # Create new VM before destroying old one
    # Ensures service continuity during VM replacement
    create_before_destroy = true
  }
}
```

### ⚠️ Constraint Propagation

If resource A has `create_before_destroy = true` and depends on resource B, then resource B **also** gets `create_before_destroy = true` automatically. This can cause unexpected behavior — be aware of dependency chains.

---

## 📚 `prevent_destroy`

### The Problem It Solves

Accidentally running `terraform destroy` on a production database is catastrophic. `prevent_destroy = true` causes Terraform to **error** if any plan would destroy the resource.

### Usage

```hcl
resource "local_file" "critical_config" {
  content  = var.critical_config
  filename = "/etc/critical/config.conf"

  lifecycle {
    prevent_destroy = true
  }
}
```

### What Happens When You Try to Destroy

```bash
terraform destroy
# Error: Instance cannot be destroyed
#
# on main.tf line 5, in resource "local_file" "critical_config":
#   5: resource "local_file" "critical_config" {
#
# Resource local_file.critical_config has lifecycle.prevent_destroy set,
# but the plan calls for this resource to be destroyed.
```

### Removing `prevent_destroy`

To destroy a protected resource, you must first remove `prevent_destroy = true` from the configuration, then run `terraform apply` (to update the state), then run `terraform destroy`.

### ⚠️ Limitation

`prevent_destroy` only works when Terraform is managing the resource. It does NOT prevent:
- Manual deletion outside of Terraform
- `terraform state rm` followed by manual deletion
- Deletion by another Terraform workspace

---

## 📚 `ignore_changes`

### The Problem It Solves

Some resources are modified outside of Terraform after creation — auto-scaling groups adjust instance counts, operators manually resize VMs, tags get added by external systems. Without `ignore_changes`, Terraform would revert these changes on the next `apply`.

### Usage

```hcl
resource "local_file" "app_config" {
  content  = var.initial_content
  filename = "/etc/app/config.conf"

  lifecycle {
    # Ignore changes to content — operators may edit this file manually
    ignore_changes = [content]
  }
}
```

### Ignoring Multiple Attributes

```hcl
resource "libvirt_domain" "web" {
  name   = var.vm_name
  memory = var.memory_mb
  vcpu   = var.vcpu_count

  lifecycle {
    # Ignore manual resizing by operators
    ignore_changes = [
      memory,  # Operators may resize memory manually
      vcpu,    # Operators may adjust CPU manually
    ]
  }
}
```

### Ignoring All Changes (`ignore_changes = all`)

```hcl
resource "libvirt_domain" "legacy" {
  name = var.vm_name

  lifecycle {
    # Terraform manages creation only — all subsequent changes ignored
    # Use with extreme caution — this is usually an anti-pattern
    ignore_changes = all
  }
}
```

### ⚠️ Anti-Pattern Warning

`ignore_changes` causes **drift blindness** — Terraform no longer detects or reports changes to ignored attributes. Overusing it defeats the purpose of Infrastructure as Code.

```hcl
# ❌ ANTI-PATTERN: Ignoring too many attributes
lifecycle {
  ignore_changes = [memory, vcpu, disk, network, tags, labels]
  # At this point, why use Terraform at all?
}

# ✅ BETTER: Ignore only what's truly managed externally
lifecycle {
  ignore_changes = [memory]  # Only memory is auto-scaled externally
}
```

---

## 📚 `replace_triggered_by` (Terraform 1.2+)

### The Problem It Solves

Sometimes you need to force a resource to be replaced when another resource changes — even if the resource's own configuration hasn't changed. A classic example: when a base image is updated, all VMs using that image should be replaced.

### Usage

```hcl
resource "local_file" "base_image_version" {
  content  = var.image_version
  filename = "${path.module}/image-version.txt"
}

resource "local_file" "vm_config" {
  content  = "vm using image version ${var.image_version}"
  filename = "${path.module}/vm.conf"

  lifecycle {
    # Force replacement of vm_config whenever base_image_version changes
    replace_triggered_by = [local_file.base_image_version]
  }
}
```

### Triggering on a Specific Attribute

```hcl
resource "libvirt_volume" "base_image" {
  name   = "base-image"
  source = var.image_url
}

resource "libvirt_domain" "web" {
  name = var.vm_name

  lifecycle {
    # Replace VM only when the base image ID changes (not other image attributes)
    replace_triggered_by = [libvirt_volume.base_image.id]
  }
}
```

### Using `terraform_data` as a Trigger

```hcl
resource "terraform_data" "image_version" {
  input = var.image_version
}

resource "local_file" "vm_config" {
  content  = "vm config"
  filename = "${path.module}/vm.conf"

  lifecycle {
    # Replace when image_version variable changes
    replace_triggered_by = [terraform_data.image_version]
  }
}
```

---

## 🔄 Combining All Lifecycle Arguments

```hcl
resource "libvirt_domain" "production_web" {
  name   = "prod-web-${var.environment}"
  memory = var.memory_mb
  vcpu   = var.vcpu_count

  lifecycle {
    # Zero-downtime replacement
    create_before_destroy = true

    # Protect from accidental destruction
    prevent_destroy = true

    # Tolerate manual memory adjustments by ops team
    ignore_changes = [memory]

    # Replace when base image is updated
    replace_triggered_by = [libvirt_volume.base_image.id]

    # Validate before creation
    precondition {
      condition     = var.memory_mb >= 512
      error_message = "Production VMs require at least 512MB RAM."
    }

    # Validate after creation
    postcondition {
      condition     = self.vcpu >= 1
      error_message = "VM must have at least 1 vCPU after creation."
    }
  }
}
```

---

## 🧪 Hands-On Lab

### Lab: Lifecycle Arguments in Practice

```bash
mkdir tf302-lifecycle
cd tf302-lifecycle
```

**Step 1**: Create `variables.tf`:

```hcl
variable "config_version" {
  type        = string
  description = "Configuration version — changing this triggers replacement"
  default     = "v1"
}

variable "app_name" {
  type    = string
  default = "hashi-training"
}
```

**Step 2**: Create `main.tf`:

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

# Version tracker — changing this triggers replacement of app_config
resource "terraform_data" "config_version" {
  input = var.config_version
}

# App config — replaced when config_version changes
resource "local_file" "app_config" {
  content  = "app = ${var.app_name}\nversion = ${var.config_version}"
  filename = "${path.module}/app.conf"

  lifecycle {
    create_before_destroy = true

    replace_triggered_by = [terraform_data.config_version]

    postcondition {
      condition     = fileexists(self.filename)
      error_message = "Config file was not created successfully."
    }
  }
}

# Critical config — protected from accidental destruction
resource "local_file" "critical_config" {
  content  = "critical = true\napp = ${var.app_name}"
  filename = "${path.module}/critical.conf"

  lifecycle {
    prevent_destroy = true
  }
}
```

**Step 3**: Apply and test:

```bash
terraform init
terraform apply -auto-approve
# Both files created

# Change config_version to trigger replacement
terraform apply -var="config_version=v2" -auto-approve
# app_config is replaced (create_before_destroy)
# critical_config is unchanged

# Try to destroy — will fail due to prevent_destroy
terraform destroy
# Error: Instance cannot be destroyed (critical_config)

# To clean up: remove prevent_destroy from critical_config, then destroy
```

---

## ✅ Checkpoint Quiz

**Question 1**: What does `create_before_destroy = true` do?
- A) Creates a backup before destroying
- B) Creates the new resource before destroying the old one during replacement
- C) Prevents the resource from being destroyed
- D) Creates the resource twice for redundancy

<details>
<summary>Answer</summary>
**B) Creates the new resource before destroying the old one during replacement** — This enables zero-downtime replacements. The new resource is fully created before the old one is destroyed.
</details>

---

**Question 2**: What happens when you run `terraform destroy` on a resource with `prevent_destroy = true`?
- A) Terraform skips the resource and destroys everything else
- B) Terraform prompts for confirmation before destroying
- C) Terraform errors and aborts the entire destroy operation
- D) Terraform removes `prevent_destroy` automatically

<details>
<summary>Answer</summary>
**C) Terraform errors and aborts the entire destroy operation** — `prevent_destroy = true` causes Terraform to error with "Instance cannot be destroyed" if any plan would destroy the resource. You must remove `prevent_destroy` from the config first.
</details>

---

**Question 3**: What is the main risk of overusing `ignore_changes`?
- A) It makes Terraform run slower
- B) It causes drift blindness — Terraform no longer detects external changes
- C) It prevents resources from being created
- D) It conflicts with `prevent_destroy`

<details>
<summary>Answer</summary>
**B) It causes drift blindness** — When you ignore too many attributes, Terraform stops detecting and reporting changes to those attributes. This defeats the purpose of IaC, which is to have a single source of truth for your infrastructure.
</details>

---

**Question 4**: What Terraform version introduced `replace_triggered_by`?
- A) 1.0
- B) 1.1
- C) 1.2
- D) 1.5

<details>
<summary>Answer</summary>
**C) 1.2** — `replace_triggered_by` was introduced in Terraform 1.2.0. For earlier versions, use `terraform taint` (deprecated) or `terraform apply -replace=<resource>`.
</details>

---

## 📚 Key Takeaways

| Argument | Purpose | When to Use |
|----------|---------|-------------|
| `create_before_destroy` | Zero-downtime replacement | Production resources that must stay available |
| `prevent_destroy` | Protect critical resources | Databases, state backends, critical configs |
| `ignore_changes` | Tolerate external drift | Auto-scaled resources, manually managed attributes |
| `replace_triggered_by` | Force replacement on dependency change | VMs that must be replaced when base image changes |
| `precondition` | Validate before create/update | Input validation at resource level |
| `postcondition` | Validate after create/update | Verify resource was created correctly |

---

## 🔗 Next Steps

- **Related**: [TF-302 Core: Pre/Post Conditions & Check Blocks](../README.md) — `precondition` and `postcondition` in depth
- **Related**: [TF-101 Supplement: terraform_data](../../../TF-100-fundamentals/TF-101-intro-basics/4-null-resource-terraform-data/README.md) — using `terraform_data` as a trigger

---

## 📖 Additional Resources

- [lifecycle Meta-Argument — Terraform Documentation](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle)
- [create_before_destroy](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#create_before_destroy)
- [prevent_destroy](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#prevent_destroy)
- [ignore_changes](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#ignore_changes)
- [replace_triggered_by](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#replace_triggered_by)
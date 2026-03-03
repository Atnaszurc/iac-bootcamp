# TF-101 Section 4: `null_resource` vs `terraform_data` & Provisioners

**Course**: TF-101 Introduction to IaC & Terraform Basics  
**Section**: 4 of 4  
**Duration**: 20 minutes  
**Prerequisites**: Sections 1-3 of TF-101

---

## 📋 Overview

As you explore existing Terraform codebases, you'll frequently encounter `null_resource`. This section explains what it is, why it exists, and how the modern `terraform_data` resource (introduced in Terraform 1.4) replaces it. You'll also learn about **provisioners** — a powerful but often misused feature.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Explain what `null_resource` is and why it was created
- ✅ Use `terraform_data` as the modern replacement
- ✅ Understand `triggers` vs `triggers_replace`
- ✅ Use `local-exec` provisioner appropriately
- ✅ Recognize when provisioners are an anti-pattern
- ✅ Apply best practices for side effects in Terraform

---

## 🏗️ Background: Why Does `null_resource` Exist?

Terraform manages infrastructure resources — but sometimes you need to run a script, trigger an action, or create a dependency that doesn't correspond to a real infrastructure resource. `null_resource` was created to fill this gap.

```
Problem: "I need to run a script after my VM is created, but there's no
          Terraform resource for 'run a script'."

Solution: null_resource — a resource that does nothing by itself, but
          can run provisioners and participate in the dependency graph.
```

---

## 📦 `null_resource` (Legacy — Terraform < 1.4)

`null_resource` comes from the `hashicorp/null` provider. It has no real infrastructure backing — it exists purely to:
1. Run provisioners (scripts)
2. Create artificial dependencies
3. Trigger re-runs based on changing values

### Basic Example

```hcl
terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# null_resource with triggers
resource "null_resource" "run_script" {
  # Re-runs whenever any trigger value changes
  triggers = {
    always_run    = timestamp()           # Run on every apply
    vm_id         = libvirt_domain.web.id # Run when VM changes
    config_hash   = sha256(file("config.sh"))  # Run when script changes
  }

  provisioner "local-exec" {
    command = "echo 'VM ${self.triggers.vm_id} is ready'"
  }
}
```

### Key Characteristics of `null_resource`
- Requires the `hashicorp/null` provider (extra dependency)
- Uses `triggers` map — resource is replaced when any trigger changes
- `self.triggers` gives access to trigger values inside provisioners
- Still widely used in existing codebases (you will encounter it)

---

## ✨ `terraform_data` (Modern — Terraform 1.4+)

In Terraform 1.4, HashiCorp introduced `terraform_data` as a **built-in replacement** for `null_resource`. It requires no extra provider and has a cleaner API.

### Basic Example

```hcl
# terraform_data — no provider needed, built into Terraform 1.4+
resource "terraform_data" "run_script" {
  # triggers_replace: resource is replaced when value changes
  triggers_replace = {
    vm_id       = libvirt_domain.web.id
    config_hash = sha256(file("config.sh"))
  }

  provisioner "local-exec" {
    command = "echo 'VM is ready'"
  }
}
```

### Key Differences from `null_resource`

| Feature | `null_resource` | `terraform_data` |
|---------|----------------|-----------------|
| Provider required | `hashicorp/null` | None (built-in) |
| Trigger attribute | `triggers` (map) | `triggers_replace` (any type) |
| Input storage | Via `triggers` only | `input` attribute |
| Output access | `self.triggers.*` | `self.output` |
| Minimum version | Any | Terraform 1.4+ |
| Recommended | ❌ Legacy | ✅ Modern |

### `terraform_data` with `input`

`terraform_data` has an `input` attribute that stores arbitrary data and exposes it as `output`:

```hcl
resource "terraform_data" "server_info" {
  # Store any value — accessible as self.output
  input = {
    name    = libvirt_domain.web.name
    ip      = libvirt_domain.web.network_interface[0].addresses[0]
    created = timestamp()
  }
}

output "server_info" {
  value = terraform_data.server_info.output
}
```

### Triggering Re-runs

```hcl
# Run on every apply (equivalent to always_run = timestamp())
resource "terraform_data" "always_run" {
  triggers_replace = timestamp()  # Note: any type, not just map

  provisioner "local-exec" {
    command = "date >> /tmp/apply-log.txt"
  }
}

# Run only when specific resources change
resource "terraform_data" "on_vm_change" {
  triggers_replace = [
    libvirt_domain.web.id,
    libvirt_volume.disk.id,
  ]

  provisioner "local-exec" {
    command = "echo 'Infrastructure changed, running post-deploy tasks'"
  }
}
```

---

## 🔧 Provisioners

Provisioners execute scripts or commands as part of resource creation or destruction. They're available on any resource, not just `null_resource`/`terraform_data`.

### `local-exec` Provisioner

Runs a command on the **machine running Terraform** (not the target infrastructure):

```hcl
resource "terraform_data" "notify" {
  triggers_replace = libvirt_domain.web.id

  # Runs on creation
  provisioner "local-exec" {
    command = "echo 'VM created: ${libvirt_domain.web.name}'"
  }

  # Runs on destruction
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'VM being destroyed'"
  }
}
```

### `local-exec` with Environment Variables

```hcl
resource "terraform_data" "configure" {
  triggers_replace = libvirt_domain.web.id

  provisioner "local-exec" {
    command = "./scripts/configure.sh"

    environment = {
      VM_NAME = libvirt_domain.web.name
      VM_IP   = libvirt_domain.web.network_interface[0].addresses[0]
      ENV     = var.environment
    }

    # Optional: working directory for the command
    working_dir = path.module
  }
}
```

### `local-exec` with Different Interpreters

```hcl
resource "terraform_data" "windows_script" {
  provisioner "local-exec" {
    # Run PowerShell on Windows
    interpreter = ["PowerShell", "-Command"]
    command     = "Write-Host 'Hello from PowerShell'"
  }
}

resource "terraform_data" "python_script" {
  provisioner "local-exec" {
    interpreter = ["python3", "-c"]
    command     = "print('Hello from Python')"
  }
}
```

---

## ⚠️ When Provisioners Are an Anti-Pattern

HashiCorp considers provisioners a **last resort**. Here's why:

### Problems with Provisioners

1. **Not idempotent** — Running `terraform apply` twice may produce different results
2. **No state tracking** — Terraform doesn't know if the script succeeded or what it changed
3. **Failure handling** — If a provisioner fails, the resource may be left in an unknown state
4. **Breaks the declarative model** — Provisioners are imperative (do this) not declarative (be this)
5. **Hard to test** — Scripts are harder to validate than Terraform resources

### The Provisioner Decision Tree

```
Do you need to run a script?
│
├── Can you use a Terraform resource instead?
│   ├── YES → Use the resource (e.g., local_file, template, etc.)
│   └── NO  → Continue...
│
├── Can you use cloud-init or user_data?
│   ├── YES → Use cloud-init (better for VM initialization)
│   └── NO  → Continue...
│
├── Can you use Packer to bake it into the image?
│   ├── YES → Use Packer (best for configuration management)
│   └── NO  → Continue...
│
└── Use local-exec as a last resort
    └── Document WHY you couldn't use a better approach
```

### Acceptable Use Cases for `local-exec`

```hcl
# ✅ Acceptable: Triggering an external system notification
resource "terraform_data" "notify_slack" {
  triggers_replace = libvirt_domain.web.id

  provisioner "local-exec" {
    command = "curl -X POST ${var.slack_webhook} -d '{\"text\":\"VM deployed\"}'"
  }
}

# ✅ Acceptable: Generating a local file that Terraform can't create
resource "terraform_data" "generate_kubeconfig" {
  triggers_replace = libvirt_domain.k8s_master.id

  provisioner "local-exec" {
    command = "ssh ubuntu@${var.master_ip} 'cat ~/.kube/config' > kubeconfig.yaml"
  }
}

# ❌ Anti-pattern: Installing software (use Packer or cloud-init instead)
resource "terraform_data" "install_nginx" {
  provisioner "local-exec" {
    command = "ssh ubuntu@${var.vm_ip} 'sudo apt install nginx'"
  }
}
```

---

## 🧪 Hands-On Lab: `terraform_data` in Practice

### Lab Setup

Create a new directory and follow along:

```bash
mkdir tf101-terraform-data
cd tf101-terraform-data
```

### Step 1: Create `main.tf`

```hcl
# main.tf
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Create a file resource
resource "local_file" "config" {
  content  = "app_version = ${var.app_version}\nenvironment = ${var.environment}"
  filename = "${path.module}/app.conf"
}

# Use terraform_data to track when config changes and "notify"
resource "terraform_data" "config_changed" {
  # Trigger when the file content changes
  triggers_replace = local_file.config.content

  provisioner "local-exec" {
    command = "echo '[${timestamp()}] Config updated for ${var.environment}' >> deploy-log.txt"
  }
}

# Store computed values for later use
resource "terraform_data" "deployment_info" {
  input = {
    environment = var.environment
    version     = var.app_version
    deployed_at = timestamp()
    config_file = local_file.config.filename
  }
}
```

### Step 2: Create `variables.tf`

```hcl
# variables.tf
variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

variable "app_version" {
  type        = string
  description = "Application version to deploy"
  default     = "1.0.0"
}
```

### Step 3: Create `outputs.tf`

```hcl
# outputs.tf
output "deployment_info" {
  description = "Information about this deployment"
  value       = terraform_data.deployment_info.output
}

output "config_file" {
  description = "Path to the generated config file"
  value       = local_file.config.filename
}
```

### Step 4: Run the Lab

```bash
# Initialize
terraform init

# Apply
terraform apply -var="environment=dev" -var="app_version=1.0.0"

# Check the deploy log
cat deploy-log.txt

# Check the outputs
terraform output deployment_info

# Change the version — watch the provisioner re-run
terraform apply -var="environment=dev" -var="app_version=1.1.0"

# Check the log again — new entry added
cat deploy-log.txt

# Clean up
terraform destroy
```

### Expected Output

```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

deployment_info = {
  "config_file" = "./app.conf"
  "deployed_at" = "2024-01-15T10:30:00Z"
  "environment" = "dev"
  "version" = "1.0.0"
}
```

---

## 📊 Migration: `null_resource` → `terraform_data`

If you encounter `null_resource` in existing code, here's how to migrate:

### Before (Legacy)

```hcl
resource "null_resource" "example" {
  triggers = {
    vm_id = libvirt_domain.web.id
  }

  provisioner "local-exec" {
    command = "echo ${self.triggers.vm_id}"
  }
}
```

### After (Modern)

```hcl
resource "terraform_data" "example" {
  triggers_replace = libvirt_domain.web.id

  provisioner "local-exec" {
    command = "echo ${libvirt_domain.web.id}"
  }
}
```

### Migration Steps

1. Replace `resource "null_resource"` with `resource "terraform_data"`
2. Replace `triggers = { key = value }` with `triggers_replace = value`
3. Replace `self.triggers.key` references with direct resource references
4. Remove `hashicorp/null` from `required_providers` if no longer used
5. Run `terraform state mv null_resource.example terraform_data.example`

---

## ✅ Checkpoint Quiz

**Question 1**: What provider does `null_resource` require?
- A) `hashicorp/terraform`
- B) `hashicorp/null`
- C) No provider needed
- D) `hashicorp/local`

<details>
<summary>Answer</summary>
**B) `hashicorp/null`** — `null_resource` requires the `hashicorp/null` provider. This is one reason `terraform_data` is preferred — it's built into Terraform with no extra provider needed.
</details>

---

**Question 2**: What is the minimum Terraform version required for `terraform_data`?
- A) 1.0.0
- B) 1.2.0
- C) 1.4.0
- D) 1.6.0

<details>
<summary>Answer</summary>
**C) 1.4.0** — `terraform_data` was introduced in Terraform 1.4.0.
</details>

---

**Question 3**: Which attribute in `terraform_data` replaces `triggers` from `null_resource`?
- A) `input`
- B) `output`
- C) `triggers_replace`
- D) `depends_on`

<details>
<summary>Answer</summary>
**C) `triggers_replace`** — When the value of `triggers_replace` changes, the `terraform_data` resource is replaced (destroyed and recreated), causing any provisioners to re-run.
</details>

---

**Question 4**: According to HashiCorp, provisioners should be used:
- A) For all configuration management tasks
- B) As the primary way to configure VMs
- C) As a last resort when no better option exists
- D) Instead of cloud-init

<details>
<summary>Answer</summary>
**C) As a last resort** — HashiCorp recommends using Terraform resources, cloud-init, or Packer instead of provisioners whenever possible. Provisioners break the declarative model and are harder to test and maintain.
</details>

---

## 📚 Key Takeaways

| Concept | Key Point |
|---------|-----------|
| `null_resource` | Legacy — still works, but avoid in new code |
| `terraform_data` | Modern built-in replacement (Terraform 1.4+) |
| `triggers` | `null_resource` attribute — map of values |
| `triggers_replace` | `terraform_data` attribute — any type |
| `input` / `output` | `terraform_data` data storage attributes |
| `local-exec` | Runs commands on the Terraform host machine |
| Provisioners | Last resort — prefer resources, cloud-init, or Packer |

---

## 🔗 Next Steps

- **Next Section**: This is the final section of TF-101
- **Next Course**: [TF-102: Variables, Loops & Functions](../../TF-102-variables-loops/README.md)
- **Related**: [PKR-100: Packer Fundamentals](../../../PKR-100-fundamentals/README.md) — the right way to configure VM images

---

## 📖 Additional Resources

- [terraform_data documentation](https://developer.hashicorp.com/terraform/language/resources/terraform-data)
- [null_resource documentation](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)
- [Provisioners documentation](https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax)
- [Provisioners are a last resort](https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax#provisioners-are-a-last-resort)
# TF-301 Supplement: `sensitive` Variables, Outputs & `nonsensitive()`

**Course**: TF-301 Input Validation & Advanced Functions  
**Section**: Supplement  
**Duration**: 20 minutes  
**Prerequisites**: TF-301 core content (variable validation)  
**Terraform Version**: 0.14+ (`sensitive` variables), 0.15+ (`nonsensitive()`)

---

## 📋 Overview

Terraform's `sensitive` attribute prevents secret values — passwords, API keys, tokens — from appearing in plan/apply output and logs. This is a critical security feature for production infrastructure. This section covers how `sensitive` works, its limitations, and the `nonsensitive()` escape hatch.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Mark variables as `sensitive = true` to suppress output
- ✅ Mark outputs as `sensitive = true`
- ✅ Understand how sensitivity propagates automatically
- ✅ Use `nonsensitive()` safely when appropriate
- ✅ Understand what `sensitive` does NOT protect against
- ✅ Apply best practices for secrets in Terraform

---

## 🔑 What `sensitive` Does

When a value is marked sensitive, Terraform:

1. **Redacts it in `terraform plan` output** — shows `(sensitive value)` instead
2. **Redacts it in `terraform apply` output** — same redaction
3. **Redacts it in `terraform output`** — shows `<sensitive>` unless `-json` or `-raw` flag used
4. **Does NOT redact it in state** — the value is stored in plaintext in `terraform.tfstate`

> ⚠️ **Critical**: `sensitive` is a **display filter**, not encryption. The value is still stored in state. Protect your state file!

---

## 📚 Sensitive Variables

### Basic Usage

```hcl
variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}
```

### In `terraform plan` output:

```
  + resource "local_file" "db_config" {
      + content  = (sensitive value)
      + filename = "./db.conf"
    }
```

### Combining with Validation

```hcl
variable "api_key" {
  type        = string
  description = "API key for external service"
  sensitive   = true

  validation {
    condition     = length(var.api_key) >= 32
    error_message = "API key must be at least 32 characters."
  }
}
```

> **Note**: Validation error messages are shown in output — do NOT include the actual value in error messages for sensitive variables.

---

## 📚 Sensitive Outputs

### Explicit Sensitive Output

```hcl
output "db_password" {
  description = "Database password (sensitive)"
  value       = var.db_password
  sensitive   = true
}
```

### Automatic Sensitivity Propagation

If an output contains a sensitive value, Terraform **automatically** marks it sensitive — even if you don't set `sensitive = true`:

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

# This output is automatically sensitive because it contains var.db_password
output "connection_string" {
  value = "postgresql://admin:${var.db_password}@${var.db_host}/mydb"
  # sensitive = true  ← not needed, Terraform infers it
}
```

If you forget to mark an output sensitive but it contains a sensitive value, Terraform will **error** and tell you to add `sensitive = true`.

### Viewing Sensitive Outputs

```bash
# Shows: db_password = <sensitive>
terraform output

# Shows the actual value (use carefully!)
terraform output -raw db_password

# Shows all values including sensitive in JSON
terraform output -json
```

---

## 📚 `nonsensitive()` — The Escape Hatch

`nonsensitive()` removes the sensitive marking from a value. Use it **only** when you are certain the value is safe to display.

### When to Use `nonsensitive()`

```hcl
variable "db_host" {
  type      = string
  sensitive = true  # Marked sensitive because it's in a sensitive variable group
}

variable "db_password" {
  type      = string
  sensitive = true
}

# The host is not actually secret — safe to display
output "db_host_display" {
  value = nonsensitive(var.db_host)  # ✅ OK — hostname is not a secret
}

# ❌ NEVER do this with actual secrets
output "db_password_display" {
  value = nonsensitive(var.db_password)  # ❌ DANGEROUS — exposes the password!
}
```

### Practical Use Case: Partial Redaction

```hcl
variable "api_key" {
  type      = string
  sensitive = true
}

# Show only the first 4 characters for debugging (safe to display)
output "api_key_prefix" {
  description = "First 4 chars of API key for identification"
  value       = nonsensitive(substr(var.api_key, 0, 4))
}
```

---

## 🔄 Sensitivity Propagation Through Modules

Sensitive values propagate automatically through module boundaries:

```hcl
# Root module
variable "db_password" {
  type      = string
  sensitive = true
}

module "database" {
  source      = "./modules/database"
  db_password = var.db_password  # Sensitive value passed to module
}
```

```hcl
# modules/database/main.tf
variable "db_password" {
  type      = string
  sensitive = true  # Must also be marked sensitive in the module
}

resource "local_file" "db_config" {
  content  = "password=${var.db_password}"  # Automatically sensitive
  filename = "/etc/db/config"
}
```

> **Rule**: If you pass a sensitive value into a module variable, that module variable must also be marked `sensitive = true`.

---

## ⚠️ What `sensitive` Does NOT Protect

| Scenario | Protected? |
|----------|-----------|
| `terraform plan` output | ✅ Yes — shows `(sensitive value)` |
| `terraform apply` output | ✅ Yes — shows `(sensitive value)` |
| `terraform output` | ✅ Yes — shows `<sensitive>` |
| Terraform state file | ❌ No — stored in plaintext |
| State in HCP Terraform | ✅ Yes — encrypted at rest |
| Crash logs (`crash.log`) | ❌ No — may appear in logs |
| Provider debug logs | ❌ No — may appear in `TF_LOG` output |
| Git history (if state committed) | ❌ No — never commit state to git |

### Best Practices for Secrets

```hcl
# ✅ DO: Use environment variables for sensitive inputs
# export TF_VAR_db_password="mysecret"
# terraform apply  ← picks up from environment

# ✅ DO: Use a secrets manager (Vault, AWS Secrets Manager)
# data "vault_generic_secret" "db" {
#   path = "secret/database"
# }

# ✅ DO: Use HCP Terraform for encrypted state storage

# ❌ DON'T: Put secrets in .tfvars files committed to git
# ❌ DON'T: Put secrets in terraform.tfvars (auto-loaded)
# ❌ DON'T: Echo sensitive outputs in CI/CD pipelines
```

---

## 🧪 Hands-On Lab

### Lab: Sensitive Variables in Action

```bash
mkdir tf301-sensitive
cd tf301-sensitive
```

**Step 1**: Create `variables.tf`:

```hcl
variable "app_name" {
  type        = string
  description = "Application name (not sensitive)"
  default     = "hashi-training"
}

variable "db_password" {
  type        = string
  description = "Database password (sensitive)"
  sensitive   = true
  default     = "super-secret-password-123"

  validation {
    condition     = length(var.db_password) >= 12
    error_message = "Password must be at least 12 characters."
  }
}

variable "api_key" {
  type        = string
  description = "API key (sensitive)"
  sensitive   = true
  default     = "abcd1234efgh5678ijkl9012"
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

# This file will contain the sensitive value (in real life, protect this file!)
resource "local_file" "app_config" {
  content = <<-EOT
    app_name = "${var.app_name}"
    db_password = "${var.db_password}"
  EOT
  filename = "${path.module}/app.conf"
}
```

**Step 3**: Create `outputs.tf`:

```hcl
output "app_name" {
  description = "Application name"
  value       = var.app_name
  # Not sensitive — shows normally
}

output "db_password" {
  description = "Database password"
  value       = var.db_password
  sensitive   = true  # Explicitly marked sensitive
}

output "api_key_prefix" {
  description = "First 4 chars of API key (safe to display)"
  value       = nonsensitive(substr(var.api_key, 0, 4))
}

# This output is automatically sensitive (contains sensitive var)
output "connection_string" {
  value = "postgresql://admin:${var.db_password}@localhost/mydb"
  # sensitive = true  ← Terraform will require this automatically
  sensitive = true
}
```

**Step 4**: Run and observe:

```bash
terraform init
terraform plan
# Notice: db_password shows as (sensitive value) in plan

terraform apply -auto-approve
# Notice: sensitive values are redacted in output

terraform output
# app_name = "hashi-training"
# api_key_prefix = "abcd"
# connection_string = <sensitive>
# db_password = <sensitive>

terraform output -raw db_password
# super-secret-password-123  ← actual value shown with -raw

terraform destroy -auto-approve
```

---

## ✅ Checkpoint Quiz

**Question 1**: What does `sensitive = true` on a variable do?
- A) Encrypts the value in the state file
- B) Prevents the value from appearing in plan/apply output
- C) Prevents the value from being used in resources
- D) Deletes the value after apply

<details>
<summary>Answer</summary>
**B) Prevents the value from appearing in plan/apply output** — `sensitive = true` is a display filter. It shows `(sensitive value)` in plan/apply output. The value is still stored in plaintext in the state file.
</details>

---

**Question 2**: If a variable is marked `sensitive = true` and you use it in an output, what happens?
- A) Terraform errors — sensitive values cannot be used in outputs
- B) The output automatically becomes sensitive
- C) The output shows the value normally
- D) You must use `nonsensitive()` to use it in an output

<details>
<summary>Answer</summary>
**B) The output automatically becomes sensitive** — Terraform propagates sensitivity. If you use a sensitive value in an output without marking it `sensitive = true`, Terraform will error and require you to add `sensitive = true` to the output.
</details>

---

**Question 3**: When is it appropriate to use `nonsensitive()`?
- A) When you want to see the value in plan output for debugging
- B) When the value is not actually secret (e.g., a hostname that was grouped with secrets)
- C) When you need to pass the value to another module
- D) When the value is stored in HCP Terraform

<details>
<summary>Answer</summary>
**B) When the value is not actually secret** — `nonsensitive()` should only be used when you are certain the value is safe to display. A common case is when a non-secret value (like a hostname) was grouped with sensitive values and inherited the sensitive marking.
</details>

---

## 📚 Key Takeaways

| Feature | Behavior |
|---------|----------|
| `sensitive = true` on variable | Redacts in plan/apply output |
| `sensitive = true` on output | Redacts in `terraform output` |
| Automatic propagation | Outputs containing sensitive values are auto-marked sensitive |
| `nonsensitive()` | Removes sensitive marking — use with extreme caution |
| State file | Sensitive values stored in **plaintext** — protect your state! |
| HCP Terraform | Encrypts state at rest — recommended for production |

---

## 🔗 Next Steps

- **Related**: [TF-301 Core: Variable Validation](../README.md) — validation blocks for sensitive variables
- **Related**: [TF-104: State Management](../../../TF-100-fundamentals/TF-104-state-cli/README.md) — protecting state files

---

## 📖 Additional Resources

- [sensitive — Terraform Documentation](https://developer.hashicorp.com/terraform/language/values/variables#suppressing-values-in-cli-output)
- [nonsensitive() — Terraform Documentation](https://developer.hashicorp.com/terraform/language/functions/nonsensitive)
- [Sensitive Data in State — Terraform Documentation](https://developer.hashicorp.com/terraform/language/state/sensitive-data)
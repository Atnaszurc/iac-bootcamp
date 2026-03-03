# Ephemeral Values (Terraform 1.10+)

## Overview

**Terraform 1.10** introduced **ephemeral values** — a new category of value that is **never written to state, plan files, or logs**. Unlike `sensitive = true` (which redacts display but still stores the value in state), ephemeral values are truly transient: they exist only during the Terraform operation and are discarded afterward.

> **Version Note**: Ephemeral variables, ephemeral outputs, and the `ephemeralasnull()` function require **Terraform 1.10+**.

---

## The Problem Ephemeral Values Solve

### `sensitive = true` — Display Filter Only

```hcl
variable "db_password" {
  type      = string
  sensitive = true  # Redacted in output, BUT still stored in state!
}
```

**What `sensitive` does**:
- ✅ Hides value in `terraform plan` / `terraform apply` output
- ✅ Hides value in `terraform output`
- ❌ Value IS stored in `terraform.tfstate` (plaintext)
- ❌ Value IS stored in plan files

### `ephemeral = true` — Never Persisted

```hcl
variable "db_password" {
  type      = string
  ephemeral = true  # NEVER written to state or plan files (Terraform 1.10+)
}
```

**What `ephemeral` does**:
- ✅ Value is NEVER written to state
- ✅ Value is NEVER written to plan files
- ✅ Value is NEVER written to logs
- ✅ Exists only in memory during the Terraform operation
- ⚠️ Can only be used in ephemeral contexts (see below)

---

## Comparison: `sensitive` vs `ephemeral`

| Feature | `sensitive = true` | `ephemeral = true` |
|---------|-------------------|-------------------|
| Redacted in plan output | ✅ Yes | ✅ Yes |
| Stored in state | ✅ Yes (plaintext) | ❌ Never |
| Stored in plan files | ✅ Yes | ❌ Never |
| Can be used in resource attributes | ✅ Yes | ⚠️ Only write-only attributes |
| Can be used in provisioners | ✅ Yes | ✅ Yes |
| Can be used in `local-exec` | ✅ Yes | ✅ Yes |
| Can be used in `locals` | ✅ Yes | ⚠️ Result becomes ephemeral |
| Can be used in non-ephemeral outputs | ✅ Yes | ❌ No |

**Rule of thumb**:
- Use `sensitive` when the value must be stored in state (e.g., a generated resource ID)
- Use `ephemeral` when the value should NEVER touch state (e.g., a password used only at creation time)

---

## Ephemeral Variables

Mark a variable as ephemeral to prevent it from ever being written to state:

```hcl
variable "db_password" {
  type        = string
  description = "Database password — never stored in state"
  ephemeral   = true  # Terraform 1.10+
}

variable "api_token" {
  type        = string
  description = "API token for external service"
  ephemeral   = true
}
```

### Where You Can Use Ephemeral Variables

```hcl
# ✅ In provisioners (local-exec, remote-exec)
resource "null_resource" "configure_db" {
  provisioner "local-exec" {
    command = "configure-db --password=${var.db_password}"
  }
}

# ✅ In locals (result becomes ephemeral)
locals {
  connection_string = "postgresql://admin:${var.db_password}@${var.db_host}/mydb"
  # connection_string is now ephemeral — cannot be used in non-ephemeral outputs
}

# ✅ In write-only resource attributes (provider must support it — Terraform 1.11+)
# resource "aws_db_instance" "main" {
#   password_wo = var.db_password  # write-only attribute
# }

# ❌ In regular resource attributes (would be stored in state)
# resource "local_file" "config" {
#   content = var.db_password  # ERROR: ephemeral value in non-ephemeral context
# }
```

---

## Ephemeral Outputs

Outputs can also be marked ephemeral. Ephemeral outputs:
- Are not stored in state
- Cannot be read by `terraform output`
- Can only be consumed by other ephemeral contexts (e.g., module-to-module passing)

```hcl
# Ephemeral output — only usable by calling modules in ephemeral contexts
output "connection_string" {
  value       = "postgresql://admin:${var.db_password}@${var.db_host}/mydb"
  description = "Database connection string — ephemeral, never stored"
  ephemeral   = true  # Terraform 1.10+
}

# Regular output — stored in state (cannot reference ephemeral values)
output "db_host" {
  value       = var.db_host
  description = "Database hostname — safe to store in state"
  # No ephemeral = true, so this IS stored in state
}
```

### Ephemeral Output Rules

```hcl
# ❌ ERROR: Cannot use ephemeral value in non-ephemeral output
output "bad_output" {
  value = var.db_password  # var.db_password is ephemeral
  # This will fail: ephemeral value cannot be used in non-ephemeral output
}

# ✅ CORRECT: Mark the output as ephemeral too
output "good_output" {
  value     = var.db_password
  ephemeral = true  # Now it's valid
}
```

---

## The `ephemeralasnull()` Function

Sometimes you need to use an ephemeral value in a non-ephemeral context — but you only care about whether it's null, not its actual value. The `ephemeralasnull()` function converts an ephemeral value to `null` for use in non-ephemeral contexts:

```hcl
variable "optional_token" {
  type      = string
  default   = null
  ephemeral = true
}

# ✅ Use ephemeralasnull() to check if the token was provided
# without storing the token value itself in state
output "token_provided" {
  value = ephemeralasnull(var.optional_token) != null
  # Stores: true or false (not the token value)
}

locals {
  # Check if token was provided — stores boolean, not the secret
  has_token = ephemeralasnull(var.optional_token) != null
}
```

### How `ephemeralasnull()` Works

| Input | Output |
|-------|--------|
| Ephemeral value (non-null) | `null` |
| Ephemeral value (null) | `null` |
| Non-ephemeral value | The value unchanged |

```hcl
locals {
  # If var.token is ephemeral and has a value → returns null
  # If var.token is ephemeral and is null → returns null
  # If var.token is NOT ephemeral → returns var.token unchanged
  safe_token = ephemeralasnull(var.token)
}
```

**Use case**: You want to record in state that a secret was provided (for drift detection), but not the secret itself.

---

## Practical Example: Database Provisioning

See the `example/` directory for a complete working example.

The example demonstrates:
1. Ephemeral variable for a database password
2. Using the password in a `local-exec` provisioner
3. Using `ephemeralasnull()` to record whether a password was set
4. Ephemeral output for a connection string
5. Non-ephemeral output for safe metadata

```
example/
├── main.tf        # Resources using ephemeral values
├── variables.tf   # Ephemeral and regular variables
└── outputs.tf     # Ephemeral and regular outputs
```

---

## Key Rules Summary

### ✅ Ephemeral values CAN be used in:
- `provisioner "local-exec"` and `provisioner "remote-exec"` blocks
- `connection` blocks
- Write-only resource attributes (provider must support, Terraform 1.11+)
- Other ephemeral variables, locals, and outputs
- `ephemeralasnull()` function calls

### ❌ Ephemeral values CANNOT be used in:
- Regular resource attributes (stored in state)
- Non-ephemeral outputs
- `count` or `for_each` meta-arguments
- Resource `id` or any attribute that Terraform tracks for drift

---

## When to Use Ephemeral Values

| Scenario | Recommendation |
|----------|---------------|
| Password used only during resource creation | `ephemeral = true` |
| API token for a one-time configuration call | `ephemeral = true` |
| Certificate private key (never store in state) | `ephemeral = true` |
| Database password that must be in state for rotation tracking | `sensitive = true` |
| Resource ID or ARN (needed for references) | Neither — regular value |
| Secret that must be readable via `terraform output` | `sensitive = true` |

---

## Related Topics

- **[3-sensitive-values/](../3-sensitive-values/)** — `sensitive = true` for display redaction
- **[TF-302: Write-Only Attributes](../../TF-302-conditions-checks/4-write-only-attributes/)** — provider-defined attributes that accept ephemeral values (Terraform 1.11+)
- **[TF-306: ephemeralasnull() function](../../TF-306-functions/)** — function reference

---

## Further Reading

- [Terraform Docs: Ephemeral Values](https://developer.hashicorp.com/terraform/language/values/variables#ephemeral-values)
- [Terraform 1.10 Release Notes](https://github.com/hashicorp/terraform/releases/tag/v1.10.0)
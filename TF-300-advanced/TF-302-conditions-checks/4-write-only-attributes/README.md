# Write-Only Attributes (Terraform 1.11+)

## Overview

**Terraform 1.11** introduced **write-only attributes** — a provider-defined feature where certain resource attributes are accepted by Terraform during `apply` but are **never stored in state**. Write-only attributes are designed to work with ephemeral values (Terraform 1.10+), enabling a complete solution for secrets that should never touch state.

> **Version Note**: Write-only attributes require **Terraform 1.11+** AND a provider that implements them. Not all providers support write-only attributes yet.

---

## The Problem Write-Only Attributes Solve

### The Traditional Problem: Passwords in State

```hcl
# Traditional approach — password stored in state!
resource "aws_db_instance" "main" {
  identifier = "production-db"
  password   = var.db_password  # ⚠️ Stored in terraform.tfstate in plaintext
}
```

After `terraform apply`, your `terraform.tfstate` contains:
```json
{
  "resources": [{
    "instances": [{
      "attributes": {
        "password": "MySecretPassword123"  // ⚠️ Plaintext in state!
      }
    }]
  }]
}
```

### The Write-Only Solution

```hcl
# Write-only approach — password NEVER stored in state
resource "aws_db_instance" "main" {
  identifier  = "production-db"
  password_wo = var.db_password  # ✅ Accepted during apply, never stored in state
  # password_wo_version = 1      # Increment to trigger password rotation
}
```

After `terraform apply`, the state contains:
```json
{
  "resources": [{
    "instances": [{
      "attributes": {
        "password_wo": null  // ✅ Never stored — always null in state
      }
    }]
  }]
}
```

---

## How Write-Only Attributes Work

Write-only attributes follow a naming convention: the attribute name ends with `_wo` (write-only). Providers that implement write-only attributes typically also provide a `_wo_version` companion attribute for triggering updates.

### The `_wo_version` Pattern

Because write-only values are never stored in state, Terraform cannot detect when they change (it has nothing to compare against). The `_wo_version` attribute solves this:

```hcl
resource "aws_db_instance" "main" {
  identifier          = "production-db"
  password_wo         = var.db_password  # Write-only: never stored
  password_wo_version = 1                # Stored in state — increment to rotate password
}
```

When you want to rotate the password:
1. Change `var.db_password` to the new password
2. Increment `password_wo_version` from `1` to `2`
3. Run `terraform apply` — Terraform sees the version changed and re-applies the password

---

## Comparison: Regular vs Sensitive vs Ephemeral vs Write-Only

| Feature | Regular | `sensitive = true` | `ephemeral = true` | Write-Only (`_wo`) |
|---------|---------|-------------------|-------------------|-------------------|
| Stored in state | ✅ Yes | ✅ Yes (redacted display) | ❌ Never | ❌ Never |
| Visible in plan output | ✅ Yes | ❌ Redacted | ❌ Redacted | ❌ Redacted |
| Can detect drift | ✅ Yes | ✅ Yes | ❌ No | ❌ No (use `_wo_version`) |
| Provider support needed | ❌ No | ❌ No | ❌ No | ✅ Yes |
| Works with ephemeral values | ✅ Yes | ✅ Yes | N/A | ✅ Yes |

---

## Using Write-Only Attributes with Ephemeral Values

Write-only attributes are the primary use case for ephemeral values in resource blocks. An ephemeral variable can be passed to a write-only attribute — the value is used during apply but never stored anywhere:

```hcl
# Ephemeral variable — never stored in state or plan files
variable "db_password" {
  type      = string
  ephemeral = true  # Terraform 1.10+
}

# Write-only attribute — accepts ephemeral values (Terraform 1.11+)
resource "aws_db_instance" "main" {
  identifier          = "production-db"
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20

  # ✅ Ephemeral variable → write-only attribute
  # Neither the variable nor the attribute is ever stored in state
  password_wo         = var.db_password
  password_wo_version = var.db_password_version  # Regular variable — stored in state
}

variable "db_password_version" {
  type    = number
  default = 1
  # Not ephemeral — we want to track the version in state
}
```

---

## Identifying Write-Only Attributes in Provider Documentation

Write-only attributes are documented in provider documentation with a **"Write-Only"** badge or note. Look for:

1. **Attribute name ending in `_wo`**: e.g., `password_wo`, `secret_wo`
2. **Documentation note**: "This attribute is write-only and will not be stored in state"
3. **Companion `_wo_version` attribute**: For triggering updates

### Example from AWS Provider Documentation

```
password_wo (String, Write-Only)
  The password for the database master user. This attribute is write-only
  and will not be stored in the Terraform state. Use password_wo_version
  to trigger password rotation.

password_wo_version (Number)
  An integer that, when changed, triggers an update of the password_wo
  attribute. Increment this value to rotate the database password.
```

---

## Practical Example: Simulated Write-Only Pattern

Since write-only attributes require provider support, this example uses the `local` provider to demonstrate the **concept** using a `null_resource` with a provisioner — the closest equivalent available without a cloud provider:

See the `example/` directory for a working demonstration.

```
example/
├── main.tf        # Demonstrates write-only pattern with null_resource
├── variables.tf   # Ephemeral and version variables
└── outputs.tf     # Shows what IS and ISN'T stored in state
```

---

## Password Rotation Workflow

```hcl
# Step 1: Initial deployment
variable "db_password" {
  type      = string
  ephemeral = true
}

variable "db_password_version" {
  type    = number
  default = 1  # Start at version 1
}

resource "aws_db_instance" "main" {
  password_wo         = var.db_password    # e.g., "InitialPassword123"
  password_wo_version = var.db_password_version  # 1
}
```

```bash
# Step 2: Rotate the password
# 1. Update your secret store with the new password
# 2. Update terraform.tfvars (or use -var flags):
#    db_password_version = 2
# 3. Apply with new password:
terraform apply \
  -var="db_password=NewPassword456" \
  -var="db_password_version=2"
```

**Why this works**: Terraform sees `db_password_version` changed from `1` to `2` in state, so it re-applies the resource with the new `password_wo` value.

---

## Key Rules Summary

### ✅ Write-only attributes CAN accept:
- Regular string/number values
- `sensitive = true` variables
- `ephemeral = true` variables (primary use case)
- Computed values from other resources (if non-ephemeral)

### ❌ Write-only attributes CANNOT:
- Be read back after apply (always `null` in state)
- Be used for drift detection (use `_wo_version` instead)
- Be referenced in other resource attributes
- Be output via `terraform output`

### ⚠️ Provider Requirements:
- The provider must explicitly implement write-only attributes
- Not all providers support write-only attributes yet
- Check provider documentation for `_wo` suffix attributes

---

## When to Use Write-Only Attributes

| Scenario | Recommendation |
|----------|---------------|
| Database password (cloud provider) | `password_wo` + `password_wo_version` |
| API key for a managed service | Write-only attribute if provider supports it |
| TLS certificate private key | Write-only attribute if provider supports it |
| Resource name or ID | Regular attribute (needs drift detection) |
| Configuration that changes frequently | Regular or sensitive (needs drift detection) |

---

## Related Topics

- **[TF-301: Ephemeral Values](../../TF-301-validation/5-ephemeral-values/)** — `ephemeral = true` variables and outputs (Terraform 1.10+)
- **[3-lifecycle-arguments/](../3-lifecycle-arguments/)** — `lifecycle` meta-arguments including `ignore_changes`
- **[TF-306: ephemeralasnull() function](../../TF-306-functions/)** — function for using ephemeral values in non-ephemeral contexts

---

## Further Reading

- [Terraform Docs: Write-Only Attributes](https://developer.hashicorp.com/terraform/language/resources/ephemeral-values#write-only-arguments)
- [Terraform 1.11 Release Notes](https://github.com/hashicorp/terraform/releases/tag/v1.11.0)
- [AWS Provider: Write-Only Attributes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
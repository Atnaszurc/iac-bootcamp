# Identity-Based Import (Terraform 1.12+)

## Overview

**Terraform 1.12** introduced an alternative to string-based import IDs: the **`identity` attribute** in `import` blocks. Instead of constructing a string ID, you provide a structured object that the provider uses to look up the resource.

> **Version Note**: Identity-based import requires **Terraform 1.12+** AND a provider that implements the identity schema for the resource. Not all resources support `identity` yet — check provider documentation.

---

## The Problem with String IDs

Traditional import uses a string `id` that must be formatted exactly as the provider expects:

```hcl
# Traditional import — string ID must be formatted correctly
import {
  to = aws_iam_role.admin
  id = "my-admin-role"  # Must know the exact string format
}

import {
  to = aws_s3_bucket_policy.main
  id = "my-bucket"  # For some resources, the ID is just the bucket name
}

import {
  to = aws_vpc_security_group_rule.ingress
  id = "sgr-0123456789abcdef0"  # Must look up the rule ID separately
}
```

**Problems with string IDs**:
- Format varies by resource type (sometimes ARN, sometimes name, sometimes composite)
- Must look up the correct format in provider documentation
- Composite IDs use provider-specific separators (e.g., `bucket/key`, `id:region`)
- Error-prone — wrong format causes import failure

---

## Identity-Based Import

With `identity`, you provide a structured map of attributes that uniquely identify the resource:

```hcl
# Identity-based import — structured, self-documenting (Terraform 1.12+)
import {
  to = aws_iam_role.admin
  identity = {
    name = "my-admin-role"  # Named attribute — clear and unambiguous
  }
}

import {
  to = aws_s3_bucket_policy.main
  identity = {
    bucket = "my-bucket"  # Explicit attribute name
  }
}
```

**Benefits of identity**:
- ✅ Self-documenting — attribute names make the import clear
- ✅ No need to know the string ID format
- ✅ Structured — matches the resource's actual attributes
- ✅ Less error-prone — provider validates the identity object

---

## `id` vs `identity` — Key Differences

| Feature | `id` (string) | `identity` (object) |
|---------|--------------|---------------------|
| Format | Single string | Map of named attributes |
| Terraform version | 1.5+ | 1.12+ |
| Provider support | All providers | Provider must implement |
| Self-documenting | ❌ Opaque string | ✅ Named attributes |
| Composite resources | Requires separator (e.g., `/`) | Each attribute is separate |
| Mutually exclusive | ✅ Cannot use both | ✅ Cannot use both |

> ⚠️ **Important**: `id` and `identity` are **mutually exclusive** in an import block. You must use one or the other, not both.

---

## Syntax

```hcl
# Using id (traditional — Terraform 1.5+)
import {
  to     = resource_type.name
  id     = "string-identifier"
}

# Using identity (new — Terraform 1.12+)
import {
  to       = resource_type.name
  identity = {
    attribute_name = "value"
    # Additional attributes as needed
  }
}
```

---

## Practical Examples

### Example 1: AWS IAM Role

```hcl
# Traditional (id)
import {
  to = aws_iam_role.deployer
  id = "my-deployer-role"
}

# Identity-based (1.12+)
import {
  to = aws_iam_role.deployer
  identity = {
    name = "my-deployer-role"
  }
}

resource "aws_iam_role" "deployer" {
  name = "my-deployer-role"
  # ... rest of configuration
}
```

### Example 2: AWS S3 Bucket

```hcl
# Traditional (id)
import {
  to = aws_s3_bucket.data
  id = "my-data-bucket-prod"
}

# Identity-based (1.12+)
import {
  to = aws_s3_bucket.data
  identity = {
    bucket = "my-data-bucket-prod"
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket-prod"
}
```

### Example 3: Composite Resource (where identity really shines)

```hcl
# Traditional — composite ID with separator (hard to remember format)
import {
  to = aws_s3_bucket_acl.main
  id = "my-bucket,private"  # bucket,acl — must know the separator!
}

# Identity-based — clear and explicit
import {
  to = aws_s3_bucket_acl.main
  identity = {
    bucket = "my-bucket"
    acl    = "private"
  }
}

resource "aws_s3_bucket_acl" "main" {
  bucket = "my-bucket"
  acl    = "private"
}
```

---

## Using `for_each` with Identity Import

Identity import works with `for_each` just like string `id`:

```hcl
# Import multiple resources using for_each + identity
variable "roles_to_import" {
  default = {
    admin    = { name = "my-admin-role" }
    deployer = { name = "my-deployer-role" }
    readonly = { name = "my-readonly-role" }
  }
}

import {
  for_each = var.roles_to_import
  to       = aws_iam_role.roles[each.key]
  identity = {
    name = each.value.name
  }
}

resource "aws_iam_role" "roles" {
  for_each = var.roles_to_import
  name     = each.value.name
  # ... rest of configuration
}
```

---

## How to Check if a Resource Supports Identity

1. **Provider documentation**: Look for an "Import" section that mentions `identity`
2. **Provider version**: Must be a recent version that implements identity for the resource
3. **Error message**: If you try `identity` on an unsupported resource, Terraform will error with a clear message

```bash
# If identity is not supported, you'll see:
# Error: Resource does not support identity-based import
# Use the "id" attribute instead.
```

---

## Working Example

See the `example/` directory for a working demonstration using the `local` provider.

> **Note**: The `local` provider does not currently implement identity-based import. The example demonstrates the syntax and pattern using comments, with a working traditional `id`-based import for comparison.

```
example/
└── main.tf    # Import block examples (id vs identity syntax)
```

---

## When to Use Identity vs ID

| Scenario | Recommendation |
|----------|---------------|
| Provider supports identity | Use `identity` — more readable |
| Provider only supports string ID | Use `id` — required |
| Composite resource with separator | Use `identity` if supported — avoids separator confusion |
| Bulk import with `for_each` | Either works — `identity` is cleaner for complex resources |
| Terraform < 1.12 | Must use `id` |

---

## Related Topics

- **[example/](../example/)** — Main TF-204 import examples (traditional `id`-based)
- **[removed-blocks/](../removed-blocks/)** — `removed` blocks for decommissioning resources
- **[TF-201: moved blocks](../../TF-201-module-design/moved-blocks/)** — Refactoring with `moved` blocks

---

## Further Reading

- [Terraform Docs: Import Blocks](https://developer.hashicorp.com/terraform/language/import)
- [Terraform 1.12 Release Notes](https://github.com/hashicorp/terraform/releases/tag/v1.12.0)
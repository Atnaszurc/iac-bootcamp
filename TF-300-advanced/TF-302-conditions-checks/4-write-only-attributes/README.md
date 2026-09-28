# Write-Only Attributes (Terraform 1.11+)

## Overview

**Terraform 1.11** introduced **write-only attributes**: a provider-defined feature where certain resource arguments are accepted by Terraform during `apply` but are **never stored in state or plan files**. Write-only attributes are designed to work with ephemeral values (Terraform 1.10+), which together keep a secret out of state from start to finish.

> **Version Note**: Write-only attributes require **Terraform 1.11+** AND a provider that implements them. Not every provider has them yet.

Everything on this page uses the `hashicorp/tls` provider, which runs locally: no account, no server. The output below was produced with Terraform 1.16.4 and tls 4.x.

---

## The Problem Write-Only Attributes Solve

### The Traditional Problem: Secrets in State

`tls_self_signed_cert` signs a certificate with a private key. The classic argument for that key is `private_key_pem`:

```hcl
# Traditional approach: the private key is stored in state
resource "tls_self_signed_cert" "web" {
  private_key_pem       = file("web.key") # ⚠️ Stored in terraform.tfstate in plaintext
  validity_period_hours = 24
  allowed_uses          = ["server_auth"]

  subject {
    common_name = "web.lab.local"
  }
}
```

After `terraform apply`:

```bash
grep -c "PRIVATE KEY" terraform.tfstate
# 1
jq '.resources[0].instances[0].attributes.private_key_pem' terraform.tfstate
# "-----BEGIN PRIVATE KEY-----\nMC4CAQAwBQYD..."
```

`sensitive` hides the key in plan output, but state holds it in plaintext. Anyone who can read the state (a teammate, a CI job, a backup) has your key.

### The Write-Only Solution

```hcl
# Write-only approach: the key is sent to the provider, never stored
resource "tls_self_signed_cert" "web" {
  private_key_pem_wo         = file("web.key") # ✅ Used during apply, never stored
  private_key_pem_wo_version = 1               # Stored; increment to use a new key
  validity_period_hours      = 24
  allowed_uses               = ["server_auth"]

  subject {
    common_name = "web.lab.local"
  }
}
```

After `terraform apply`:

```bash
grep -c "PRIVATE KEY" terraform.tfstate
# 0
jq '.resources[0].instances[0].attributes | {private_key_pem_wo, private_key_pem_wo_version}' terraform.tfstate
# { "private_key_pem_wo": null, "private_key_pem_wo_version": 1 }
```

---

## How Write-Only Attributes Work

Write-only attributes follow a naming convention: the name ends in `_wo`. Providers usually add a `_wo_version` companion argument next to it.

### The `_wo_version` Pattern

Because a write-only value is never stored, Terraform has nothing to compare a new value against: it can't tell that the key changed. The `_wo_version` argument solves this. It *is* stored, and when it changes, the provider uses the current write-only value:

```hcl
resource "tls_self_signed_cert" "web" {
  private_key_pem_wo         = var.private_key_pem # Write-only: never stored
  private_key_pem_wo_version = var.key_version     # Stored: change it to rotate
  # ...
}
```

To rotate the key:
1. Give Terraform the new key (`var.private_key_pem`)
2. Increment `key_version` from `1` to `2`
3. Run `terraform apply`: Terraform sees the version changed and uses the new key

Change only the key and not the version, and Terraform reports **No changes**. The hands-on below shows exactly that.

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

`file("web.key")` above keeps the key out of state, but the path is in your configuration. The usual combination is an **ephemeral variable** feeding a **write-only attribute**: the value comes from outside, is used during apply, and is stored nowhere. This is the example's `variables.tf` and `main.tf`:

```hcl
# Ephemeral variable: never stored in state or plan files (Terraform 1.10+)
variable "private_key_pem" {
  type      = string
  ephemeral = true
}

variable "key_version" {
  type    = number
  default = 1 # Not ephemeral: the version is tracked in state
}

resource "tls_self_signed_cert" "web" {
  # ✅ Ephemeral variable → write-only attribute (Terraform 1.11+)
  private_key_pem_wo         = var.private_key_pem
  private_key_pem_wo_version = var.key_version
  # ...
}
```

An ephemeral value can only go into places that don't store it: write-only attributes, ephemeral resources, provider configuration, other ephemeral values. `private_key_pem = var.private_key_pem` (the regular argument) is an error:

```
Error: Invalid use of ephemeral value

Ephemeral values are not valid for "private_key_pem", because it is not a
write-only attribute and must be persisted to state.
```

---

## Identifying Write-Only Attributes in Provider Documentation

Look for:

1. **An argument name ending in `_wo`**: `private_key_pem_wo`, `password_wo`, `secret_string_wo`
2. **A note in the argument's description** that it is write-only and not stored in state
3. **A companion `_wo_version` argument** to trigger updates

Or ask Terraform itself, after `terraform init`:

```bash
terraform providers schema -json | jq -r '
  .provider_schemas[].resource_schemas | to_entries[]
  | .key as $r | .value.block.attributes // {} | to_entries[]
  | select(.value.write_only) | "\($r).\(.key)"'
# tls_cert_request.private_key_pem_wo
# tls_locally_signed_cert.ca_private_key_pem_wo
# tls_self_signed_cert.private_key_pem_wo
```

Real-world examples in cloud providers include database passwords (`password_wo` on `aws_db_instance` in the AWS provider 6.x) and secret values in secret managers. The pattern is always the one on this page: the `_wo` argument plus a `_wo_version`.

---

## Hands-On: A Certificate Whose Key Terraform Never Sees

**Directory**: [`example/`](./example/) — uses the `hashicorp/tls` provider, which runs locally: no account, no server.

The scenario: your web server's private key is kept outside Terraform (a file only you have, a password manager, Vault), and Terraform manages the certificate.

```hcl
variable "private_key_pem" {
  type      = string
  ephemeral = true # never in state or plan files
}

variable "key_version" {
  type    = number
  default = 1
}

resource "tls_self_signed_cert" "web" {
  private_key_pem_wo         = var.private_key_pem # write-only
  private_key_pem_wo_version = var.key_version

  validity_period_hours = 24 * 90
  allowed_uses          = ["server_auth", "digital_signature", "key_encipherment"]
  dns_names             = [var.hostname]

  subject {
    common_name = var.hostname
  }
}
```

### Step 1: Sign a certificate

```bash
cd example
openssl genpkey -algorithm ed25519 -out web.key     # the key lives outside Terraform
export TF_VAR_private_key_pem="$(cat web.key)"
terraform init
terraform apply
```

### Step 2: Look for the key

```bash
grep -c "PRIVATE KEY" terraform.tfstate
# 0

# ...but the certificate really belongs to your key:
diff <(openssl x509 -in out/web.lab.local.crt -noout -pubkey) <(openssl pkey -in web.key -pubout) && echo "match"
```

Compare with the old way: set `private_key_pem = var.private_key_pem` instead (and remove `ephemeral = true`, which that attribute won't accept). Apply, and `grep` finds the key in plain text in the state.

### Step 3: See why `_wo_version` exists

```bash
openssl genpkey -algorithm ed25519 -out web2.key
export TF_VAR_private_key_pem="$(cat web2.key)"
terraform plan
# No changes. Your infrastructure matches the configuration.
```

A different key, and Terraform doesn't notice: it doesn't store the value, so it has nothing to compare with. The version number is how you tell it:

```bash
terraform apply -var key_version=2
#   # tls_self_signed_cert.web must be replaced
```

Now the certificate is signed with the new key.

### Step 4: Run the tests

```bash
terraform test
```

The tests generate a throwaway key with a helper module (`tests/setup`) and assert that `private_key_pem_wo` reads back as `null`.

---

## Key Rules Summary

### ✅ Write-only attributes CAN accept:
- Regular values (strings, numbers, `file(...)`)
- `sensitive = true` variables
- `ephemeral = true` variables (the main use case)
- Values from other resources and data sources, including ephemeral resources

### ❌ Write-only attributes CANNOT:
- Be read back: every reference to them, in state, outputs or other resources, is `null`
- Be used for drift detection (use `_wo_version` instead)
- Tell Terraform that their value changed: only a `_wo_version` change does

### ⚠️ Provider Requirements:
- The provider must implement write-only attributes, and Terraform must be 1.11+
- Not all providers have them yet
- Check the provider documentation, or the schema query above

---

## When to Use Write-Only Attributes

| Scenario | Recommendation |
|----------|---------------|
| Database password (cloud provider) | `password_wo` + `password_wo_version` |
| API key for a managed service | Write-only attribute if provider supports it |
| TLS certificate private key | `tls_self_signed_cert.private_key_pem_wo` (the hands-on above) |
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
- [tls provider: `tls_self_signed_cert`](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert)
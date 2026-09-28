# Capturing Ephemeral Values with `terraform_data` (Terraform 1.16+)

**New in Terraform 1.16**

Objective: Learn when and how to deliberately persist an ephemeral value using the `store` block of `terraform_data` — and why you need `version` to keep it stable.

**Prerequisites**: [Section 5: Ephemeral Values](../5-ephemeral-values/README.md)

## Table of Contents

1. [Overview](#overview)
2. [The Problem](#the-problem)
3. [The `store` Block](#the-store-block)
4. [Why `version` Matters](#why-version-matters)
5. [`replace`: Update vs Replace](#replace-update-vs-replace)
6. [Instructions](#instructions)
7. [When to Use It (and When Not To)](#when-to-use-it-and-when-not-to)
8. [Checkpoint Quiz](#checkpoint-quiz)

---

## Overview

Section 5 showed that ephemeral values **never** reach state. That's what you want most of the time. But sometimes you need a generated secret to be **stable across runs** and usable in **ordinary resource attributes**:

- An ephemeral `random_password` produces a **new** password on every plan and apply
- A regular attribute (like `local_sensitive_file.content`) cannot accept an ephemeral value at all

Terraform 1.16 adds a `store` block to the built-in `terraform_data` resource. It takes an ephemeral value through a **write-only** `input` and saves a copy in state as `store.output` or `store.sensitive_output`.

> ⚠️ **This is an explicit opt-out of ephemerality.** The captured value is stored in state in plaintext, exactly like any `sensitive` value. Use it on purpose, not by default.

---

## The Problem

```hcl
ephemeral "random_password" "db" {
  length = 24
}

resource "local_sensitive_file" "db_credentials" {
  filename = "${path.module}/out/db-credentials.env"
  content  = "DB_PASSWORD=${ephemeral.random_password.db.result}"
}
```

```
Error: Invalid use of ephemeral value
```

Before 1.16 the workarounds were a non-ephemeral `resource "random_password"` (which stores the password in state anyway) or an external secret store.

---

## The `store` Block

```hcl
resource "terraform_data" "db_password" {
  store {
    input     = ephemeral.random_password.db.result # write-only: accepts ephemeral values
    sensitive = true                                 # value goes to store.sensitive_output
    version   = var.password_version                 # only re-capture when this changes
    # replace = true                                 # replace the resource instead of updating
  }
}

resource "local_sensitive_file" "db_credentials" {
  filename = "${path.module}/out/db-credentials.env"
  content  = "DB_PASSWORD=${terraform_data.db_password.store.sensitive_output}"
}
```

| Argument | Description |
|----------|-------------|
| `input` | Write-only. Accepts any type, including ephemeral values. Never stored itself. |
| `sensitive` | `true` → the value is saved in `store.sensitive_output`; otherwise in `store.output` |
| `version` | When set, `input` changes are ignored until `version` changes |
| `replace` | When `true`, a change to the stored value replaces the `terraform_data` resource instead of updating it |

| Attribute | Description |
|-----------|-------------|
| `store.output` | Captured value when `sensitive` is not `true` |
| `store.sensitive_output` | Captured value when `sensitive = true` |

---

## Why `version` Matters

An ephemeral resource runs again on **every** plan. Without `version`, the captured password changes on every apply:

```bash
# store block WITHOUT version
terraform apply   # captures password A
terraform plan
# terraform_data.db_password will be updated in-place
# Plan: 0 to add, 1 to change, 0 to destroy.   ← a different password, every time
```

With `version`, Terraform keeps the captured value until you change the version:

```bash
terraform apply                          # captures password A (version 1)
terraform plan                           # No changes.
terraform apply -var password_version=2  # captures password B — a rotation
```

This is the same pattern as the `*_wo_version` arguments that accompany write-only attributes ([TF-302 Section 4](../../TF-302-conditions-checks/4-write-only-attributes/README.md)).

---

## `replace`: Update vs Replace

When the stored value changes:
- **`replace = false`** (default) — `terraform_data` is **updated in place**
- **`replace = true`** — `terraform_data` is **replaced** (destroy + create)

Replacement matters when something keys off the resource's **lifecycle** rather than its values:
- `terraform_data.db_password.id` only changes on replacement — an update keeps the same ID
- An `action_trigger` on `after_create` fires on replacement, not on an in-place update (see [TF-307](../../TF-307-query-actions/README.md))

> 💡 `replace_triggered_by = [terraform_data.db_password]` fires on **both** update and replace, so you don't need `replace = true` for that.

---

## Instructions

**Directory**: [`example/`](./example/) — uses `hashicorp/random` and `hashicorp/local`, no credentials needed.

### Task 1: Capture and Inspect

```bash
cd example
terraform init
terraform apply
cat out/db-credentials.env
```

Look in `terraform.tfstate` for `terraform_data.db_password`:
- `store.input` is `null` — the write-only input was never saved
- `store.sensitive_output` contains the password **in plaintext**

### Task 2: Prove the Value Is Stable

```bash
terraform plan   # No changes.
terraform apply
cat out/db-credentials.env   # same password as before
```

### Task 3: Rotate

```bash
terraform apply -var password_version=2
cat out/db-credentials.env   # new password
```

### Task 4: Remove `version`

1. Delete the `version = var.password_version` line from `main.tf`.
2. Run `terraform plan` twice. Every plan wants to change the password — that's the ephemeral resource producing a new value each run.
3. Put the line back.

### Task 5: Try the Direct Route

1. In `local_sensitive_file.db_credentials`, replace `terraform_data.db_password.store.sensitive_output` with `ephemeral.random_password.db.result`.
2. Run `terraform validate` and read the `Invalid use of ephemeral value` error.
3. Revert the change.

### Task 6: Run the Tests

```bash
terraform test
```

The test runs share state, so `same_version_keeps_password` can compare its password fingerprint with the first run's, and `bump_version_rotates_password` can prove the rotation.

---

## When to Use It (and When Not To)

| Situation | Use |
|-----------|-----|
| Secret only needed during apply (provisioner, write-only attribute) | Plain ephemeral value — **don't** store it |
| Provider supports a write-only attribute (`password_wo`) | Write-only attribute + `*_wo_version` |
| Stable generated secret needed in regular attributes | `terraform_data` + `store` (this section) |
| Secret must be shared with other teams or systems | An external secret manager (Vault, AWS Secrets Manager) |

Rules of thumb:
- ✅ Always set `sensitive = true` when capturing a secret
- ✅ Always set `version` when the input is an ephemeral resource
- ✅ Protect your state backend (encryption, access control) — the value is in it
- ❌ Don't use `store` just to silence an ephemeral-value error; first check whether the destination supports write-only attributes

---

## Checkpoint Quiz

**Question 1**: What does Terraform store in state for `store.input`?
- A) The value, in plaintext
- B) The value, encrypted
- C) Nothing — it's write-only
- D) A hash of the value

<details>
<summary>Answer</summary>

**C) Nothing — it's write-only.** The captured copy lives in `store.output` or `store.sensitive_output`.
</details>

---

**Question 2**: You capture an ephemeral `random_password` without `version`. What happens on the next `terraform plan`?
- A) No changes
- B) `terraform_data` is updated with a new password
- C) An error, because ephemeral values can't be stored
- D) The password is removed from state

<details>
<summary>Answer</summary>

**B)** — The ephemeral resource generates a new password on every run. Without `version`, each new value is captured.
</details>

---

**Question 3**: Is a value captured with `store { sensitive = true }` ephemeral?
- A) Yes — it never reaches state
- B) No — it's stored in state in plaintext and only redacted in CLI output

<details>
<summary>Answer</summary>

**B)** — `store` deliberately turns an ephemeral value into a regular sensitive value.
</details>

---

## Related Topics

- [Section 5: Ephemeral Values](../5-ephemeral-values/README.md) — ephemeral variables and outputs
- [TF-302 Section 4: Write-Only Attributes](../../TF-302-conditions-checks/4-write-only-attributes/README.md) — the `*_wo_version` pattern
- [TF-101 Section 4: null_resource vs terraform_data](../../../TF-100-fundamentals/TF-101-intro-basics/4-null-resource-terraform-data/README.md) — `terraform_data` basics

## Further Reading

- [`terraform_data` resource](https://developer.hashicorp.com/terraform/language/resources/terraform-data)
- [Ephemeral values](https://developer.hashicorp.com/terraform/language/manage-sensitive-data/ephemeral)

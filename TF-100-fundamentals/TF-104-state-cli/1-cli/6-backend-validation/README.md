# Backend Validation: What `validate` Checks, and What Only `init` Can

**Terraform Version**: 1.15+  
**Needs**: nothing (no cloud account, no credentials)

Objective: know exactly which mistakes in a `backend` block `terraform validate` catches, which ones only `terraform init` catches, and why.

## Table of Contents

1. [Overview](#overview)
2. [Why `validate` Can't Check Everything](#why-validate-cant-check-everything)
3. [What Gets Checked Where](#what-gets-checked-where)
4. [Hands-On](#hands-on)
5. [Using This in CI](#using-this-in-ci)
6. [Summary](#summary)

## Overview

Terraform 1.15 made `terraform validate` look at the `backend` block. It checks that the backend **type** exists, so a typo like `backend "s4"` fails in `validate` instead of later in `init`.

You may read, in the 1.15.0 changelog or in older articles, that `validate` also checks that required backend arguments are present and have the right type. That was true for **1.15.0 only**. Terraform 1.15.1 removed it again ([#38466](https://github.com/hashicorp/terraform/issues/38466)) because it broke configurations that use `-backend-config`. The next section explains why, and it's worth understanding, because you'll use `-backend-config` yourself in TF-305.

## Why `validate` Can't Check Everything

A backend block doesn't have to be complete. This is a perfectly good S3 backend:

```hcl
terraform {
  backend "s3" {
    key    = "terraform.tfstate"
    region = "us-east-1"
    # no bucket!
  }
}
```

The bucket name is supplied when you initialise:

```bash
terraform init -backend-config="bucket=my-terraform-state"
# or from a file:
terraform init -backend-config=prod.s3.tfbackend
```

This is called **partial configuration**. Teams use it to keep one configuration and point it at a different bucket per environment, or to keep account-specific names out of the code.

`terraform validate` only sees the `.tf` files. It has no way of knowing what will be passed to `init -backend-config`, so it can't say a backend argument is "missing". When 1.15.0 tried, every partial configuration failed validation. Only `terraform init` sees the complete backend configuration, so that's where the arguments are checked.

## What Gets Checked Where

Every row below was verified on Terraform 1.16.4 and 1.17.0-beta2.

| Mistake | `terraform validate` | `terraform init` |
|---|---|---|
| Unknown backend type (`backend "s4"`) | ❌ `Unsupported backend type` | ❌ same error |
| Two `backend` blocks | ❌ `Duplicate 'backend' configuration block` | ❌ same error |
| Required argument missing (`bucket`) | ✅ passes (it could come from `-backend-config`) | ❌ `Missing Required Value` |
| Misspelt argument (`bucket_name`) | ✅ passes | ❌ `Unsupported argument` |
| Wrong type (`encrypt = "yes"`) | ✅ passes | ❌ `Incorrect attribute value type` |
| Wrong bucket name, no access, bad credentials | ✅ passes | ❌ only when it contacts the storage |

The last three rows are caught by `init` **locally**, before it contacts AWS. A config mistake costs nothing to find, and doesn't need credentials.

> Two things that are *not* errors, which you may expect to be:
> - `encrypt = "true"` (a string): Terraform converts `"true"` to `true`. Only a string that isn't a boolean, like `"yes"`, is rejected.
> - `workspace_key_prefix = ""`: accepted by the schema. `init` goes straight on to contacting AWS.

## Hands-On

All the examples are in [`example/`](./example/). The invalid ones are `.tf.example` files, so they don't break the valid one. You copy each one on its own into a scratch directory, `try/`, and run Terraform there with `-chdir`. `try/` is git-ignored.

```bash
cd example
```

### 1. A valid backend

```bash
terraform validate
# Success! The configuration is valid.
```

`validate` doesn't need `init` to check the backend block. (It does need `init` before it can check anything that uses providers or modules. This configuration has neither, apart from the built-in `terraform_data`.)

### 2. A typo in the backend type: caught by `validate`

```bash
mkdir -p try && cp 2-invalid-backend-type.tf.example try/main.tf
terraform -chdir=try validate
```

```
Error: Unsupported backend type

  on main.tf line 14, in terraform:
  14:   backend "s4" { # typo: should be "s3"

There is no backend type named "s4".
```

### 3. A missing `bucket`: valid, until `init`

```bash
cp 3-partial-backend.tf.example try/main.tf
terraform -chdir=try validate
# Success! The configuration is valid.

terraform -chdir=try init -input=false
```

```
Error: Missing Required Value

  on main.tf line 21, in terraform:
  21:   backend "s3" {

The attribute "bucket" is required by the backend.
```

`-input=false` matters here: without it, `init` *asks* you for the bucket name interactively, which is another way to supply a partial configuration. In CI there's no one to answer, so always pass `-input=false`.

Now supply the bucket:

```bash
terraform -chdir=try init -input=false -backend-config="bucket=my-terraform-state"
```

The configuration check passes, and `init` moves on to contacting AWS, where it fails because you (probably) have no AWS credentials. That's expected: everything *Terraform* can check locally has passed. To see a complete S3 backend `init` against a free local S3 emulator, including locking and state migration, do the [TF-305 Section 2 hands-on](../../../../TF-300-advanced/TF-305-workspaces-remote-state/2-remote-backends/README.md).

### 4. Misspelt argument and wrong type: valid, until `init`

```bash
rm -rf try/.terraform*
cp 4-wrong-arguments.tf.example try/main.tf
terraform -chdir=try validate
# Success! The configuration is valid.

terraform -chdir=try init -input=false
```

```
Error: Unsupported argument

  on main.tf line 23, in terraform:
  23:     bucket_name = "my-terraform-state" # should be: bucket

An argument named "bucket_name" is not expected here.

Error: Incorrect attribute value type

  on main.tf line 26, in terraform:
  26:     encrypt     = "yes" # should be: true

Inappropriate value for attribute "encrypt": a bool is required.
```

`init` reports all the argument errors at once, not one per run.

### 5. Two backend blocks: caught by `validate`

```bash
cp 5-duplicate-backend.tf.example try/main.tf
terraform -chdir=try validate
```

```
Error: Duplicate 'backend' configuration block

  on main.tf line 18, in terraform:
  18:   backend "s3" {

A module may have only one 'backend' configuration block. The backend was
previously configured at main.tf:15,3-18.
```

### Clean up

```bash
rm -rf try
```

### Exercise

For each of these backend blocks, predict whether `validate` fails, `init -input=false` fails, or neither, then check your answers the same way:

```hcl
# a)
backend "S3" {
  bucket = "b"
  key    = "k"
  region = "us-east-1"
}

# b)
backend "s3" {
  bucket = "b"
  region = "us-east-1"
}

# c)
backend "local" {
  path = 42
}

# d)
backend "s3" {
  bucket       = "b"
  key          = "k"
  region       = "us-east-1"
  use_lockfile = "true"
}
```

(Each goes inside a `terraform { }` block.)

<details>
<summary>Answers</summary>

- a) `validate` fails: backend types are case-sensitive, and there is no `S3`.
- b) `init` fails with `Missing Required Value`: `key` is required too.
- c) Neither: the number 42 converts to the string `"42"`, so `init` succeeds and your state file is called `42`.
- d) Neither: `"true"` converts to `true`. `init` passes the configuration check and goes on to contact AWS.

</details>

## Using This in CI

A zero-credential check that catches as much as possible:

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false   # providers and modules, no backend
terraform validate                           # includes the backend type
```

`init -backend=false` skips the backend entirely, **including** the argument checks from the table. If you want those in CI too, run the real `terraform init -input=false` with the same `-backend-config` your deploy uses. That needs credentials for the state storage, so it usually lives in the same job as `plan`.

## Summary

- `terraform validate` checks that the backend type exists and that there's only one backend block (1.15+).
- It does **not** check the arguments inside the block, because partial configuration (`-backend-config`) can supply them at `init` time. 1.15.0 tried and 1.15.1 reverted it.
- `terraform init` checks the arguments (missing, unknown, wrong type) locally, before contacting anything.
- In CI, pass `-input=false` so a missing value fails instead of waiting for input.

---

**Version Requirements**: Terraform >= 1.15.1  
**Related Topics**: [CLI Commands](../README.md), [State Management](../../2-state/README.md), [TF-305 Remote Backends](../../../../TF-300-advanced/TF-305-workspaces-remote-state/2-remote-backends/README.md)  
**Next**: [State Management](../../2-state/README.md)

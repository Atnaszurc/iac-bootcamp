# Identity-Based Import (Terraform 1.12+)

## Overview

**Terraform 1.12** introduced an alternative to string import IDs: the **`identity` argument** in `import` blocks. Instead of building a string in whatever format the provider expects, you give a small object of named attributes that identify the resource.

> **Version Note**: Identity-based import needs **Terraform 1.12+** AND a provider that defines an identity for the resource type. Many don't yet; see [Which providers support it?](#which-providers-support-it).

**Needs**: Docker (for Moto, see [Why Moto?](#why-moto)). Verified with Terraform 1.16.4 and 1.17.0-beta2, AWS provider 6.x.

---

## The Problem with String IDs

A traditional `import` block takes an `id` string, and every resource type has its own format:

```hcl
import {
  to = aws_iam_role.deployer
  id = "legacy-deployer" # the role name
}

import {
  to = aws_s3_bucket.data
  id = "legacy-data-prod" # the bucket name
}

import {
  to = aws_iam_role_policy_attachment.read_logs
  id = "legacy-readonly/arn:aws:iam::123456789012:policy/legacy-read-logs" # "<role>/<policy ARN>"
}
```

The last one is the problem: a *composite* ID, two values joined with a separator you have to look up. Get it wrong (a comma instead of the `/`) and all you get is:

```
Error: Cannot import non-existent remote object

While attempting to import an existing object to
"aws_iam_role_policy_attachment.read_logs", the provider detected that no
object exists with the given id.
```

---

## Identity-Based Import

With `identity`, you name each part:

```hcl
import {
  to = aws_iam_role_policy_attachment.read_logs
  identity = {
    role       = "legacy-readonly"
    policy_arn = "arn:aws:iam::123456789012:policy/legacy-read-logs"
  }
}
```

No format to remember, and the import block documents itself.

### `id` vs `identity`

| | `id` | `identity` |
|---|---|---|
| **Format** | One string, format depends on the resource | An object with named attributes |
| **Terraform version** | 1.5+ | 1.12+ |
| **Provider support** | Every resource that supports import | Only resources with an identity schema |
| **Composite resources** | Values joined with a separator | One attribute per value |

You can use one or the other in an `import` block, not both:

```
Error: Invalid import block

Only one of 'id' or 'identity' can be specified.
```

### What's in an identity?

The provider defines it, per resource type. Some attributes are required, some optional. For example, in the AWS provider 6.x:

| Resource | Required | Optional |
|---|---|---|
| `aws_s3_bucket` | `bucket` | `region`, `account_id` |
| `aws_iam_role` | `name` | `account_id` |
| `aws_iam_policy` | `arn` | |
| `aws_iam_role_policy_attachment` | `role`, `policy_arn` | `account_id` |

To see the identity of any resource type, ask Terraform (after `terraform init`):

```bash
terraform providers schema -json \
  | jq '.provider_schemas[].resource_identity_schemas.aws_iam_role_policy_attachment.attributes'
```

> ⚠️ **Unknown attributes are silently ignored.** `identity = { bucket = "legacy-data-prod", acl = "private" }` imports the bucket without a word about `acl`, which `aws_s3_bucket`'s identity doesn't have (tested on 1.16.4 and 1.17.0-beta2). Check the schema instead of trusting that a successful import used everything you wrote.

### Identities are stored in state

After an import (or a create) with a provider that supports identity, the state records each resource's identity next to its attributes:

```bash
jq -c '.resources[] | {type, identity: .instances[0].identity}' terraform.tfstate
```

```
{"type":"aws_iam_policy","identity":{"arn":"arn:aws:iam::123456789012:policy/legacy-read-logs"}}
{"type":"aws_iam_role","identity":{"account_id":null,"name":"legacy-deployer"}}
{"type":"aws_iam_role_policy_attachment","identity":{"account_id":null,"policy_arn":"arn:aws:iam::123456789012:policy/legacy-read-logs","role":"legacy-readonly"}}
{"type":"aws_s3_bucket","identity":{"account_id":null,"bucket":"legacy-data-prod","region":null}}
```

`terraform query` (TF-307) uses the same identities to describe what it finds.

---

## Which providers support it?

Identity is new, and it's up to each provider. When this was written:

| Provider | Resource types with an identity |
|---|---|
| `hashicorp/aws` 6.x | 534 |
| `hashicorp/kubernetes` | 41 |
| `dmacvicar/libvirt`, `local`, `random`, `null`, `tls`, `time`, `http`, `kreuzwerker/docker` | 0 |

On a resource type without one, Terraform stops at plan time:

```
Error: unknown identity type "local_file"
```

Check your own providers:

```bash
terraform providers schema -json | jq -r '
  .provider_schemas | to_entries[]
  | "\(.key): \((.value.resource_identity_schemas // {}) | length) resource types"'
```

---

## Why Moto?

The rest of this course uses libvirt and local providers, and none of them implement identity. So this section uses the AWS provider against [Moto](https://github.com/getmoto/moto), an open-source server that imitates the AWS APIs. It runs in Docker on your machine, needs no AWS account, and costs nothing. The provider sends exactly the calls it would send to AWS, just to `http://localhost:5000`.

- ✅ Import blocks, identities and state are exactly what you'd get with real AWS
- ✅ Nothing you do can create a bill
- ⚠️ `providers.tf` has Moto-only settings (fake keys, `endpoints`, `skip_*`); remove them to use a real account
- ⚠️ Moto keeps everything in memory: restart the container and the "infrastructure" is gone

TF-307 (Query & Actions) uses the same setup.

---

## Hands-On

```
example/
├── providers.tf   # AWS provider → Moto
├── main.tf        # import blocks with identity, and the matching resources
└── seed/          # creates the "existing" infrastructure
    ├── providers.tf
    └── main.tf
```

### Step 1: Start Moto

```bash
docker run -d --name moto -p 5000:5000 motoserver/moto:latest
```

(If you did TF-307 you may already have it running.)

### Step 2: Create infrastructure that nobody manages

`seed/` plays the colleague who built things by hand: a bucket, two IAM roles, a policy, and the policy attached to one of the roles. Deleting its state afterwards leaves the resources in Moto with no Terraform configuration managing them:

```bash
cd example/seed
terraform init
terraform apply
rm terraform.tfstate*
cd ..
```

### Step 3: Import them by identity

Read [`main.tf`](./example/main.tf). It imports:

- the bucket, with `identity = { bucket = ... }`
- both roles at once, with `for_each` and `identity = { name = each.key }`
- the policy, with `identity = { arn = ... }`
- the attachment, with the composite `identity = { role = ..., policy_arn = ... }`

```bash
terraform init
terraform plan
```

```
  # aws_iam_policy.read_logs will be imported
  # aws_iam_role.roles["legacy-deployer"] will be imported
  # aws_iam_role.roles["legacy-readonly"] will be imported
  # aws_iam_role_policy_attachment.read_logs will be imported
  # aws_s3_bucket.data will be imported
Plan: 5 to import, 0 to add, 0 to change, 0 to destroy.
```

**5 to import, 0 to change**: the configuration matches what exists. Apply it, and plan again:

```bash
terraform apply
terraform plan
# No changes. Your infrastructure matches the configuration.
```

The `import` blocks have done their job; you can delete them now, or leave them (an import block for a resource that's already in state does nothing).

### Step 4: Explore

1. Look at the identities in state (the `jq` command [above](#identities-are-stored-in-state)).
2. Import the attachment with `id` instead of `identity`: replace its import block with the `id` version from [The Problem with String IDs](#the-problem-with-string-ids), `terraform state rm aws_iam_role_policy_attachment.read_logs`, and plan. Then change the `/` to a `,` and plan again.
3. Add `acl = "private"` to the bucket's identity and plan. Does Terraform complain?
4. Put `id` *and* `identity` in one import block. What does `terraform validate` say?

### Clean up

```bash
terraform destroy
```

Or restart the container, which forgets everything: `docker restart moto`.

> This example isn't part of `scripts/run-tests.sh`: `terraform test` with a mocked provider can't import by identity (`override_resource` doesn't return an identity), so it needs Moto running.

---

## When to Use Identity vs ID

| Scenario | Recommendation |
|----------|---------------|
| The resource type has an identity | `identity`: readable, and no format to look up |
| No identity for the resource type | `id`: the only option |
| Composite IDs (`a/b`, `a:b`, `a,b`) | `identity` if available: this is where it helps most |
| Bulk import with `for_each` | Either; `identity` reads better for composite resources |
| Terraform < 1.12 | `id` |

---

## Related Topics

- **[example/](../example/)**: the main TF-204 import examples (libvirt, `id`-based, UUIDs)
- **[removed-blocks/](../removed-blocks/)**: `removed` blocks for decommissioning resources
- **[TF-307: Query & Actions](../../../TF-300-advanced/TF-307-query-actions/README.md)**: find resources to import with `terraform query`
- **[TF-201: moved blocks](../../TF-201-module-design/moved-blocks/)**: refactoring with `moved` blocks

---

## Further Reading

- [Terraform Docs: Import blocks](https://developer.hashicorp.com/terraform/language/import)
- [`import` block reference](https://developer.hashicorp.com/terraform/language/block/import)

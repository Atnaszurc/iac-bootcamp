# Advanced Terraform Functions and Provider-Defined Functions

## Introduction

This lesson covers advanced usage of Terraform functions: chaining built-in functions into small pipelines, and **provider-defined functions** (Terraform 1.8+), which providers ship alongside their resources and call as `provider::<name>::<function>()`.

The examples come from running a libvirt lab: naming VMs, building descriptions, checking the age of a base image, splitting a network range, and turning human-readable durations into numbers.

**Example**: [`example/`](./example/) — every task below, plus 9 tests. No infrastructure is created: `random_string` is the only resource, and the `time` provider's functions run locally.

```bash
cd example
terraform init
terraform apply
terraform output
terraform test
```

## Table of Contents
- [Function Chaining](#function-chaining)
- [Provider-Defined Functions](#provider-defined-functions)
- [Combining Built-in and Provider-Defined Functions](#combining-built-in-and-provider-defined-functions)
- [Best Practices](#best-practices)
- [Task 1: VM Naming Convention](#task-1-vm-naming-convention)
- [Task 2: Labels to Description](#task-2-labels-to-description)
- [Task 3: Base Image Age](#task-3-base-image-age)
- [Task 4: Network per Tier](#task-4-network-per-tier)
- [Task 5: Durations](#task-5-durations)
- [Task 6: Name Builder with Lookup and Error Handling](#task-6-name-builder-with-lookup-and-error-handling)

## Function Chaining

Function chaining uses the output of one function as the input of the next.

### Example: Formatting a Name

```hcl
locals {
  raw_name       = "MY-APP PROD 001"
  formatted_name = replace(lower(local.raw_name), " ", "-")
}

output "formatted_name" {
  value = local.formatted_name # "my-app-prod-001"
}
```

Read chains inside out: `lower()` runs first, then `replace()`.

### Example: Complex Data Manipulation

```hcl
variable "labels" {
  type = map(string)
  default = {
    Owner   = "devops-team"
    Project = "iac-bootcamp"
    Tier    = "web"
  }
}

locals {
  label_pairs = [for k in sort(keys(var.labels)) : "${lower(k)}=${var.labels[k]}"]
  description = join(";", local.label_pairs)
}

output "description" {
  value = local.description # "owner=devops-team;project=iac-bootcamp;tier=web"
}
```

A `for` expression, `sort()`, `keys()`, `lower()` and `join()` turn a map into one string. `sort()` matters: map iteration order is lexical by key anyway, but sorting makes the intent explicit and survives refactoring to other collection types.

## Provider-Defined Functions

Terraform 1.8 lets providers ship functions. You call them with `provider::<local name>::<function>()`, where the local name is the key in `required_providers`. They need the provider in `required_providers`, but **no `provider` block and no credentials**: the function runs inside the provider plugin, without it being configured.

Some zero-cost providers with functions:

| Provider | Functions |
|----------|-----------|
| `hashicorp/time` | `rfc3339_parse`, `duration_parse`, `unix_timestamp_parse` |
| `hashicorp/local` | `direxists` |
| `hashicorp/kubernetes` | `manifest_decode`, `manifest_decode_multi`, `manifest_encode` |

### rfc3339_parse

Parses a timestamp into its parts:

```hcl
terraform {
  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

output "parsed" {
  value = provider::time::rfc3339_parse("2026-09-15T00:00:00Z")
}
# {
#   day = 15, month = 9, month_name = "September", year = 2026,
#   weekday_name = "Tuesday", iso_week = 38, unix = 1789430400, ...
# }
```

### duration_parse

Turns a Go-style duration into numbers:

```hcl
output "retention" {
  value = provider::time::duration_parse("36h30m")
}
# { hours = 36.5, minutes = 2190, seconds = 131400, ... }
```

## Combining Built-in and Provider-Defined Functions

`regex()` pulls the date out of an Ubuntu image version, `format()` builds a timestamp, `rfc3339_parse()` understands it, and arithmetic does the rest:

```hcl
locals {
  build_date  = regex("^(\\d{4})(\\d{2})(\\d{2})", "20260915.1") # ["2026", "09", "15"]
  image_built = provider::time::rfc3339_parse(format("%s-%s-%sT00:00:00Z", local.build_date...))
  now_unix    = provider::time::rfc3339_parse(plantimestamp()).unix
  age_days    = floor((local.now_unix - local.image_built.unix) / 86400)
}
```

The `...` after `local.build_date` expands the list into separate arguments.

## Best Practices

1. Break long chains into named `locals`. `local.clean_name` is easier to debug than one 200-character expression, and you can inspect each step in `terraform console`.
2. Use `plantimestamp()`, never `timestamp()`, in anything that ends up in a resource. `timestamp()` returns a new value every run, so the resource shows a change on every plan.
3. Use `try()` and `lookup()` defaults to handle bad input deliberately, and validate what you can't handle (see [Section 1](../1-variable-conditions/README.md)).
4. Test function logic with `terraform test`. It needs no infrastructure, and `override_resource` makes random values predictable.

## Task 1: VM Naming Convention

Create a naming chain for VMs:
- Start with a base name (e.g., "My App")
- Add the environment and a random suffix
- Lowercase, with anything that isn't a letter, digit or hyphen replaced by a hyphen
- At most 63 characters (the hostname limit), without a trailing hyphen

### Example
```hcl
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  raw_name   = "${var.base_name}-${var.environment}-${random_string.suffix.result}"
  clean_name = replace(lower(trimspace(local.raw_name)), "/[^a-z0-9-]+/", "-")
  vm_name    = trimsuffix(substr(local.clean_name, 0, 63), "-")
}
# "My App" + "dev" -> "my-app-dev-s78i0r"
```

Order matters. Clean first, *then* truncate: otherwise the replacement can make the name longer again. And truncating can cut the name right after a hyphen, which `trimsuffix()` removes. When a string argument to `replace()` is wrapped in `/.../`, Terraform treats it as a regular expression.

## Task 2: Labels to Description

libvirt has no tags, but a VM has a `description` that shows up in `virsh dominfo` and virt-manager. Turn a map of labels into one description string:
- keys lowercased, as `key=value`
- sorted, joined with `;`
- at most 255 characters

### Example
```hcl
locals {
  label_pairs = [for k in sort(keys(var.labels)) : "${lower(k)}=${var.labels[k]}"]
  description = substr(join(";", local.label_pairs), 0, 255)
}
```

## Task 3: Base Image Age

Warn when the Ubuntu base image is more than 90 days old. Parse the build date from the image version (`20260915` or `20260915.1`) with `provider::time::rfc3339_parse()`, and compare it with `plantimestamp()`.

### Example
```hcl
locals {
  build_date = regex("^(\\d{4})(\\d{2})(\\d{2})", var.image_version)
  image_built = provider::time::rfc3339_parse(
    format("%s-%s-%sT00:00:00Z", local.build_date[0], local.build_date[1], local.build_date[2])
  )
  now_unix       = provider::time::rfc3339_parse(plantimestamp()).unix
  image_age_days = floor((local.now_unix - local.image_built.unix) / 86400)
}

check "base_image_is_fresh" {
  assert {
    condition     = local.image_age_days <= var.max_image_age_days
    error_message = "Base image ${var.image_version} is ${local.image_age_days} days old (limit ${var.max_image_age_days}). Rebuild it with Packer (PKR-100)."
  }
}
```

A `check` block warns but doesn't stop the run: an old image is worth knowing about, not worth blocking a deployment for. Try `terraform plan -var image_version=20200101`.

## Task 4: Network per Tier

Split a lab range (e.g. `10.140.0.0/22`) into one `/24` per tier and return a map from tier name to CIDR.

### Example
```hcl
locals {
  tier_cidrs = zipmap(var.tiers, cidrsubnets(var.lab_cidr, [for t in var.tiers : 2]...))
}
# { app = "10.140.1.0/24", db = "10.140.2.0/24", web = "10.140.0.0/24" }
```

`cidrsubnets()` takes the number of *extra* bits for each subnet: a `/22` plus 2 bits is a `/24`. The list is built with a `for` expression and expanded with `...`, so it grows with `var.tiers`. Feed the result into the network module from [TF-201](../../../TF-200-modules/TF-201-module-design/README.md) with `for_each`.

## Task 5: Durations

Let users write snapshot retention as a readable duration (`72h`, `1h30m`) and work out how many snapshots to keep for a given interval. Reject durations Terraform can't parse.

### Example
```hcl
variable "snapshot_retention" {
  type    = string
  default = "72h"

  validation {
    condition     = can(provider::time::duration_parse(var.snapshot_retention))
    error_message = "snapshot_retention must be a duration like 72h or 1h30m (units: h, m, s)."
  }
}

locals {
  snapshot_retention_hours = provider::time::duration_parse(var.snapshot_retention).hours
  snapshots_to_keep        = ceil(local.snapshot_retention_hours / var.snapshot_interval_hours)
}
```

Provider-defined functions work inside `validation` blocks too. Note the units: Go durations stop at hours, so "3 days" is `72h`.

## Task 6: Name Builder with Lookup and Error Handling

Build host names from a service name, environment and site:
- Convert site names to short codes with a lookup table (`"Home lab"` → `hom`), and use `unk` for unknown sites
- Use the service name only if it starts with a letter, otherwise fall back to `svc`
- Add the random suffix from Task 1
- Don't use the current date: `timestamp()` changes every run, so the name (and the VM) would change on every plan

### Example
```hcl
locals {
  site_codes = {
    "Stockholm lab" = "sto"
    "Home lab"      = "hom"
    "Classroom"     = "cls"
  }

  site_code    = lookup(local.site_codes, var.site, "unk")
  service_slug = try(regex("^[a-z][a-z0-9]*", lower(var.service_name)), "svc")

  host_name = join("-", compact([
    local.service_slug,
    var.environment,
    local.site_code,
    random_string.suffix.result,
  ]))
}
# "Grafana" in "Home lab"         -> "grafana-dev-hom-s78i0r"
# "42-bad-name" in "Mars base"    -> "svc-dev-unk-s78i0r"
```

`regex()` errors when nothing matches; `try()` turns that error into the fallback. `compact()` drops empty strings, so an empty environment doesn't leave a double hyphen.

Remember to use clear names for your locals and add comments to explain complex parts of your function chains.

# Dynamic Module Sources: `const` Variables in `source` and `version`

**New in Terraform 1.15+**

Objective: pick a module's `source` and `version` with variables and locals, understand why those variables must be `const`, and know the traps.

Everything here runs locally: two versions of a local module, and a small registry module (`hashicorp/dir/template`) that needs no provider. Verified with Terraform 1.16.4 and 1.17.0-beta2.

## Table of Contents

1. [Overview](#overview)
2. [Why `const`?](#why-const)
3. [Syntax](#syntax)
4. [The Rules, and the Errors](#the-rules-and-the-errors)
5. [Hands-On](#hands-on)
6. [Testing: a Trap](#testing-a-trap)
7. [Use Cases](#use-cases)
8. [Best Practices](#best-practices)

## Overview

Until Terraform 1.15, a module's `source` and `version` had to be literal strings:

```hcl
module "network" {
  source = "./modules/network/v1" # literal only
}
```

Since 1.15, they can use **input variables declared with `const = true`**, and **locals** built only from those and literals:

```hcl
variable "network_module_version" {
  type    = string
  default = "v1"
  const   = true
}

module "network" {
  source = "./modules/network/${var.network_module_version}"
}
```

## Why `const`?

`terraform init` installs modules: it copies local modules into place and downloads registry modules. It does that *before* any plan, so it has to know every `source` and `version` while loading the configuration.

An ordinary variable is only evaluated during plan, and it might depend on things only known then. `const = true` promises Terraform the opposite: this variable has a known, constant value from the start (a default, `-var`, `TF_VAR_`, or a `.tfvars` file), so it's safe to use at `init`. In exchange, a `const` variable can't depend on anything computed during plan.

## Syntax

### A `const` variable in `source`

```hcl
variable "network_module_version" {
  type    = string
  default = "v1"
  const   = true
}

module "network" {
  source = "./modules/network/${var.network_module_version}"
  # ...
}
```

### A local built from `const` variables

```hcl
variable "environment" {
  type    = string
  default = "dev"
  const   = true

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

locals {
  network_module_version = {
    dev  = "v2"
    prod = "v1"
  }[var.environment]
}

module "network" {
  source = "./modules/network/${local.network_module_version}"
  # ...
}
```

`validation` works on `const` variables, and runs at `init`.

### A `const` variable in `version`

`version` only applies to registry modules:

```hcl
variable "template_module_version" {
  type    = string
  default = "1.0.2"
  const   = true
}

module "motd" {
  source  = "hashicorp/dir/template"
  version = var.template_module_version
  # ...
}
```

## The Rules, and the Errors

Every error below is real output from Terraform 1.16.4.

**1. The variable must be `const`.** Without `const = true`, `init` stops:

```
Error: Unknown module source

  on main.tf line 7, in module "app":
   7:   source = "./modules/${var.variant}"

Only literal values and const variables can be evaluated during init.
```

**2. No resources, data sources or module outputs.** They don't exist at `init`:

```
Error: Invalid module source

  on main.tf line 6, in module "app":
   6:   source = "./modules/${terraform_data.x.output}"

The module source can only reference constant input variables and local
values.
```

**3. `plan` and `apply` must use the value `init` used.** Initialise for `dev`, then plan with `-var environment=prod`, and Terraform refuses instead of quietly using the wrong module:

```
Error: Module source has changed

  on main.tf line 25, in module "network":
  25:   source = "./modules/network/${local.network_module_version}"

The source address was changed since this module was installed. Run
"terraform init" to install all modules required by this configuration.
```

Pass the same values to `init` as to `plan` and `apply`. A `.tfvars` file per environment makes that hard to get wrong: `init`, `plan` and `apply` all read `terraform.tfvars` and `-var-file` the same way.

**4. A `const` variable without a value stops `init`** (`Error: No value for required variable`), just as an ordinary one stops `plan`.

## Hands-On

```
example/
├── variables.tf            # environment and template_module_version are const
├── main.tf                 # module sources built from them
├── outputs.tf
├── templates/motd.txt.tmpl
├── modules/network/
│   ├── v1/main.tf          # one flat subnet
│   └── v2/main.tf          # a subnet per tier, same interface
└── tests/basic.tftest.hcl
```

The scenario: the network module has a new version, v2. `dev` tries it first; `prod` stays on v1 until v2 has proven itself. One configuration, and the environment picks the version.

### Step 1: dev

```bash
cd example
terraform init
```

```
Downloading registry.terraform.io/hashicorp/dir/template 1.0.2 for motd...
- network in modules/network/v2
```

```bash
terraform plan
```

```
Changes to Outputs:
  + motd                   = <<-EOT
        Welcome to the dev lab.
        Network lab-dev, planned by network module v2.
    EOT
  + network_module_version = "v2"
  + subnets                = {
      + app = "10.30.20.0/24"
      + db  = "10.30.30.0/24"
      + web = "10.30.10.0/24"
    }
```

### Step 2: prod, the wrong way and the right way

```bash
terraform plan -var environment=prod
# Error: Module source has changed
```

The installed module is v2, but prod wants v1. Initialise for prod:

```bash
terraform init -var environment=prod
# - network in modules/network/v1
terraform plan -var environment=prod
#   + network_module_version = "v1"
#   + subnets                = {
#       + all = "10.30.0.0/24"
#     }
```

### Step 3: a registry module version

```bash
terraform init -var environment=prod -var template_module_version=1.0.0
# Downloading registry.terraform.io/hashicorp/dir/template 1.0.0 for motd...
```

`.terraform/modules/modules.json` records which source and version is installed for each module; have a look.

### Step 4: validation at init

```bash
terraform init -var environment=qa
```

You get two errors: the map lookup in the local (`Invalid index`) and the variable's own validation (`environment must be dev or prod.`). Both come from `init`, before any plan.

### Step 5: tests

```bash
terraform init      # back to the default: dev
terraform test
# Success! 2 passed, 0 failed.
```

## Testing: a Trap

Module sources are resolved by `terraform init`, not by each `run` block in a test. If a run block sets a `const` variable that changes a module source:

```hcl
run "prod" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = output.network_module_version == "v1"
    error_message = "prod should use v1, got ${output.network_module_version}"
  }
}
```

it does **not** switch to v1. It runs against whatever `init` installed (v2 for the default `dev`), with no warning:

```
prod should use v1, got v2
```

Unlike `plan`, `terraform test` doesn't report "Module source has changed". So test each module-source combination from its own `init`:

```bash
terraform init -var environment=prod && terraform test -var environment=prod
```

The example's tests only cover the default, and say why in a comment.

## Use Cases

### 1. Roll out a new module version environment by environment

What the example does: a map from environment to module version, in one place. Promoting v2 to prod is a one-line change, reviewed like any other.

### 2. One place for registry module versions

```hcl
variable "module_versions" {
  type = object({
    templates = string
  })
  default = {
    templates = "1.0.2"
  }
  const = true
}

module "motd" {
  source  = "hashicorp/dir/template"
  version = var.module_versions.templates
  # ...
}
```

### 3. A local checkout while developing a module

```hcl
variable "use_local_network_module" {
  type    = bool
  default = false
  const   = true
}

locals {
  # example.com is a placeholder: use your module's repository
  network_source = var.use_local_network_module ? "../terraform-libvirt-network" : "git::https://example.com/terraform-libvirt-network.git?ref=v2.1.0"
}

module "network" {
  source = local.network_source
  # ...
}
```

`terraform init -var use_local_network_module=true` while you work on the module; the default everywhere else.

### 4. CI chooses the version

```bash
export TF_VAR_template_module_version=1.0.0
terraform init
terraform plan
```

## Best Practices

1. **Keep `const` variables few and simple**: environment names, version strings, booleans. Everything else stays an ordinary variable.
2. **Give them defaults**, and validation, so a plain `terraform init` works and a typo fails early.
3. **Use a `.tfvars` file per environment** (`-var-file=prod.tfvars` for `init`, `plan` and `apply`) instead of repeating `-var` flags that must match.
4. **Keep the module interface stable across versions**: v1 and v2 in the example have the same inputs and outputs, so the caller doesn't change when the version does.
5. **Don't use it to hide what's deployed.** Anyone reading the code should be able to tell which module version each environment gets. A small, explicit map does that; a chain of conditionals doesn't.
6. **Test each combination from its own `init`** (see [Testing: a Trap](#testing-a-trap)).

## Summary

- Since Terraform 1.15, `source` and `version` can use variables with `const = true` and locals built from them
- `const` variables get their value before plan (default, `-var`, `TF_VAR_`, `.tfvars`) and can't depend on resources
- `init` installs modules for the values it sees; `plan` and `apply` must use the same values, or Terraform stops with "Module source has changed"
- `terraform test` runs against the modules from `init`, whatever a run block sets

---

**Version Requirements**: Terraform >= 1.15.0  
**Related Topics**: [TF-201 Module Design](../README.md), [TF-102 Variables](../../../TF-100-fundamentals/TF-102-variables-loops/README.md)  
**Reference**: [`variable` block: `const`](https://developer.hashicorp.com/terraform/language/block/variable#const), [`module` block: `source`](https://developer.hashicorp.com/terraform/language/block/module)

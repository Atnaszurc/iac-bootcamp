# Variable Conditions

## Introduction

A `validation` block on a variable checks the input before Terraform plans anything. A bad value stops the run with *your* error message, instead of failing halfway through an apply with a provider error, or worse, succeeding with a value nobody intended.

Since **Terraform 1.9**, a condition can also reference other variables, locals and data sources ("cross-variable validation"). Before that, a condition could only look at its own variable.

This lesson validates the inputs for a small libvirt setup: a VM name, memory size, network range, SSH key and firewall rules.

**Example**: [`example/`](./example/) — all validations from this lesson, a VM that uses them, and 15 tests (`terraform test`, no libvirt daemon needed).

## Table of Contents
- [Basic Variable Validation](#basic-variable-validation)
- [Multiple Conditions](#multiple-conditions)
- [Cross-Variable Validation](#cross-variable-validation)
- [Best Practices](#best-practices)
- [Task 1: VM Name Validation](#task-1-vm-name-validation)
- [Task 2: Memory Validation](#task-2-memory-validation)
- [Task 3: Private Network Range](#task-3-private-network-range)
- [Task 4: Firewall Rule Validation](#task-4-firewall-rule-validation)
- [Task 5: Production Rules](#task-5-production-rules)
- [Bonus Task: OS Image Catalogue](#bonus-task-os-image-catalogue)

## Basic Variable Validation

### Single Condition Example

```hcl
variable "vm_name" {
  type        = string
  description = "Name of the VM, also used as its hostname"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.vm_name))
    error_message = "vm_name must be a valid hostname: 1-63 characters, lowercase letters, digits and hyphens, not starting or ending with a hyphen."
  }
}
```

`regex()` *errors* when there's no match, and a condition that errors isn't the same as one that returns `false`. `can()` turns "did this work?" into `true`/`false`.

```bash
terraform plan -var vm_name=Web_01
# Error: Invalid value for variable
#   vm_name must be a valid hostname: 1-63 characters, ...
```

## Multiple Conditions

Several `validation` blocks on one variable each get their own error message, so the user learns exactly *which* rule they broke:

```hcl
variable "memory_mb" {
  type        = number
  description = "VM memory in MiB"
  default     = 1024

  validation {
    condition     = var.memory_mb >= 512
    error_message = "memory_mb must be at least 512: Ubuntu cloud images don't boot reliably with less."
  }

  validation {
    condition     = var.memory_mb <= 16384
    error_message = "memory_mb can't exceed 16384 (16 GiB) in this lab."
  }

  validation {
    condition     = var.memory_mb % 256 == 0
    error_message = "memory_mb must be a multiple of 256 (e.g. 512, 768, 1024)."
  }
}
```

## Cross-Variable Validation

### Referencing Other Variables (Terraform 1.9+)

```hcl
variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test or prod."
  }
}

variable "vm_count" {
  type    = number
  default = 1

  validation {
    condition     = var.environment == "prod" ? var.vm_count >= 2 : var.vm_count >= 1
    error_message = "prod needs at least 2 VMs; other environments at least 1."
  }
}
```

The error is reported on `vm_count`, the variable whose block holds the rule. Put a cross-variable rule on the variable the user should change.

### Validating a List of Objects

Use `alltrue()` with a `for` expression to check every element:

```hcl
variable "firewall_rules" {
  type = list(object({
    port     = number
    protocol = optional(string, "tcp")
    from     = optional(string, "any") # "any" or a CIDR block
  }))
  default = [{ port = 22 }]

  validation {
    condition     = alltrue([for r in var.firewall_rules : r.port >= 1 && r.port <= 65535 && floor(r.port) == r.port])
    error_message = "Every port must be a whole number from 1 to 65535."
  }

  validation {
    condition     = alltrue([for r in var.firewall_rules : contains(["tcp", "udp"], r.protocol)])
    error_message = "protocol must be tcp or udp."
  }
}
```

In the example these rules become `ufw` commands that cloud-init runs inside the VM.

## Best Practices

1. Use `can()` (or `try()`) around functions that can error, such as `regex()`, `cidrnetmask()` or `tonumber()`.
2. **`&&` and `||` do not short-circuit in Terraform.** `can(cidrnetmask(x)) && split("/", x)[1] ...` still evaluates the right-hand side when `x` is garbage, and errors. Wrap the whole condition in `try(..., false)` instead.
3. Write error messages that say what a *valid* value looks like, not just that the value is wrong.
4. Prefer several small `validation` blocks over one big condition: each failure gets a precise message.
5. Test your validations. [`terraform test`](../../TF-303-test-framework/README.md) with `expect_failures = [var.name]` proves a bad value is rejected (see `example/tests/validation.tftest.hcl`).

## Task 1: VM Name Validation

The VM name is also its hostname, so it must be a valid hostname label (RFC 1123):
- 1-63 characters
- Lowercase letters, digits and hyphens only
- Must not start or end with a hyphen

### Example:
See [Single Condition Example](#single-condition-example). Test it:

```bash
cd example
terraform init
terraform test
```

Then try `terraform plan -var vm_name=web- -var ssh_public_key="ssh-ed25519 AAAA x"` and read the error.

## Task 2: Memory Validation

Implement the three rules from [Multiple Conditions](#multiple-conditions) and find out what happens with `memory_mb = 1000` (not a multiple of 256) and `memory_mb = 100` (too small *and* not a multiple of 256). How many errors do you get for the second one?

## Task 3: Private Network Range

The VM network must be a valid CIDR block inside one of the private ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16). Terraform has no `cidrcontains` function, so build the check yourself.

### Example:
```hcl
variable "network_cidr" {
  type    = string
  default = "10.130.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.network_cidr))
    error_message = "network_cidr must be an IPv4 CIDR block, e.g. 10.130.0.0/24."
  }

  # Put the network's address into each private range's prefix length and
  # see whether the range's own network address comes out.
  validation {
    condition = try(anytrue([
      for r in ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] :
      tonumber(split("/", var.network_cidr)[1]) >= tonumber(split("/", r)[1]) &&
      cidrhost("${split("/", var.network_cidr)[0]}/${split("/", r)[1]}", 0) == cidrhost(r, 0)
    ]), false)
    error_message = "network_cidr must be inside a private range (10.0.0.0/8, 172.16.0.0/12 or 192.168.0.0/16)."
  }
}
```

Why the prefix-length comparison? Without it, `10.0.0.0/7` would pass, although it's bigger than the private 10.0.0.0/8 range. Remove `try(..., false)` and pass `network_cidr = "not-a-cidr"` to see why it's there.

## Task 4: Firewall Rule Validation

Extend `firewall_rules` from [Validating a List of Objects](#validating-a-list-of-objects) with a third rule: `from` must be `"any"` or a valid CIDR block.

### Example
```hcl
  validation {
    condition     = alltrue([for r in var.firewall_rules : r.from == "any" || can(cidrnetmask(r.from))])
    error_message = "from must be \"any\" or a CIDR block like 10.0.0.0/8."
  }
```

Apply the example (`terraform apply -var ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"`), SSH to the VM and run `sudo ufw status` to see your rules inside the guest.

## Task 5: Production Rules

Add two rules that only apply in production:
- the SSH key must be an OpenSSH *public* key (people paste private keys more often than you'd think)
- in `prod`, port 22 may not be open to `any`

### Example
```hcl
variable "ssh_public_key" {
  type = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp[0-9]+) [A-Za-z0-9+/=]+( .*)?$", var.ssh_public_key))
    error_message = "ssh_public_key must be an OpenSSH public key (starting with ssh-ed25519, ssh-rsa or ecdsa-sha2-...). Did you paste the private key?"
  }
}

# Inside variable "firewall_rules":
  validation {
    condition = var.environment != "prod" || alltrue([
      for r in var.firewall_rules : !(r.port == 22 && r.from == "any")
    ])
    error_message = "In prod, port 22 must be restricted with from = \"<cidr>\", not open to any."
  }
```

## Bonus Task: OS Image Catalogue

You offer a fixed set of images. Validate that `os_version` exists for the chosen `os_family`:
- `os_family`: ubuntu, debian or alpine
- `os_version`: ubuntu 22.04/24.04, debian 12/13, alpine 3.21/3.22
- The error message should name the combination that doesn't exist

### Example
```hcl
locals {
  images = {
    ubuntu = ["22.04", "24.04"]
    debian = ["12", "13"]
    alpine = ["3.21", "3.22"]
  }
}

variable "os_family" {
  type = string
  validation {
    condition     = contains(keys(local.images), var.os_family)
    error_message = "os_family must be one of: ${join(", ", keys(local.images))}."
  }
}

variable "os_version" {
  type = string
  validation {
    condition     = contains(lookup(local.images, var.os_family, []), var.os_version)
    error_message = "os_version ${var.os_version} is not available for ${var.os_family}."
  }
}
```

```bash
terraform plan -var os_family=debian -var os_version=24.04
# Error: Invalid value for variable
#   os_version 24.04 is not available for debian.
```

Error messages can use variables too, so they can say exactly what was wrong.

Remember to use appropriate error messages that clearly explain why a validation failed and what the correct input should be.

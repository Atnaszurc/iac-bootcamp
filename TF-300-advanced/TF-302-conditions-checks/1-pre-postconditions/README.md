# Pre and Postconditions in Terraform

## Introduction

Terraform 1.2 introduced preconditions and postconditions in the `lifecycle` block of resources, data sources and outputs. Where [variable validation](../../TF-301-validation/1-variable-conditions/README.md) checks one input, conditions check *assumptions*: things that depend on several values, on the real environment, or on what a resource turned out like after it was created.

This lesson guards a libvirt VM: a network that must not clash with other networks, a pool that needs free space, a disk that must be big enough for its image, a VM that must fit on the host and actually start, and an IP address that must land where you expect.

**Example**: [`example/`](./example/) — all conditions below, verified on a real libvirt host, with 6 tests that run without libvirt (`terraform test`).

## Table of Contents
- [Preconditions](#preconditions)
- [Postconditions](#postconditions)
- [When Are Conditions Checked?](#when-are-conditions-checked)
- [Best Practices](#best-practices)
- [Task 1: Network Overlap](#task-1-network-overlap)
- [Task 2: Pool Free Space](#task-2-pool-free-space)
- [Task 3: Disk vs Image Size](#task-3-disk-vs-image-size)
- [Task 4: VM Fits the Host](#task-4-vm-fits-the-host)
- [Task 5: The VM Actually Started](#task-5-the-vm-actually-started)
- [Bonus Task: Postcondition on a Data Source](#bonus-task-postcondition-on-a-data-source)
- [Testing Conditions](#testing-conditions)

## Preconditions

A precondition is checked **before** Terraform creates, updates or destroys the resource. Use it for assumptions the resource depends on.

### Example: Network Must Not Overlap

```hcl
resource "libvirt_network" "main" {
  name    = "${var.vm_name}-net"
  forward = { mode = "nat" }
  ips = [{
    address = cidrhost(var.network_cidr, 1)
    prefix  = tonumber(split("/", var.network_cidr)[1])
  }]

  lifecycle {
    precondition {
      condition     = length(local.overlapping_reserved) == 0
      error_message = "network_cidr ${var.network_cidr} overlaps ${join(", ", local.overlapping_reserved)}. Pick another range."
    }
  }
}
```

Without it, libvirt refuses to start an overlapping network, but only at apply time and with a far less helpful message. With it, `terraform plan` stops:

```
Error: Resource precondition failed
  network_cidr 192.168.0.0/16 overlaps 192.168.122.0/24. Pick another range.
```

Why not a variable validation? Validation could do this too. A precondition fits better when the rule is about *this resource* (it's shown right next to it) or needs things a validation can't reach cleanly, such as resource attributes.

## Postconditions

A postcondition is checked **after** Terraform creates or updates the resource (or reads a data source). `self` refers to the resource's final values, including everything the provider computed.

### Example: Pool Needs Free Space

```hcl
resource "libvirt_pool" "main" {
  name   = "${var.vm_name}-pool"
  type   = "dir"
  target = { path = "/var/lib/libvirt/images/${var.vm_name}" }

  lifecycle {
    postcondition {
      condition     = self.available >= var.min_free_gib * local.gib
      error_message = "Pool ${self.name} has only ${floor(self.available / local.gib)} GiB free; need at least ${var.min_free_gib} GiB."
    }
  }
}
```

`available` is computed by libvirt: nobody can know it before the pool exists.

```
Error: Resource postcondition failed
  Pool tf302-conditions-pool has only 938 GiB free; need at least 100000 GiB.
```

A failed postcondition stops the apply, but the resource *has* been created. Terraform keeps it in state, and it's reported again on the next plan until you fix the cause.

## When Are Conditions Checked?

Terraform checks a condition as early as it can:
- **Plan**, if every value in the condition is known. The network overlap and the host-memory check run at plan time.
- **Apply**, if something is only known after a resource is created. The disk check (next) needs the size of an image that is downloaded during apply.

```bash
terraform apply -var disk_gib=1
# ... downloads the base image, then:
# Error: Resource precondition failed
#   disk_gib (1) is smaller than the base image (3 GiB).
```

## Best Practices

1. Use preconditions for assumptions a resource depends on; postconditions for guarantees about what it turned out like.
2. Put facts into error messages: `${self.available}`, `${var.network_cidr}`. "Condition failed" helps nobody.
3. Use data sources for real-world facts (host memory, existing ranges) instead of hard-coding them.
4. Use a [`check` block](../2-check-blocks/README.md) instead when a failed assumption should *warn*, not block.

## Task 1: Network Overlap

Add a precondition to the network: `network_cidr` must not overlap any range in `var.reserved_cidrs` (default: libvirt's own `192.168.122.0/24`).

Hint: two ranges overlap exactly when they have the same network address at the *shorter* of their two prefix lengths.

### Example
```hcl
locals {
  overlapping_reserved = [
    for r in var.reserved_cidrs : r
    if cidrhost(
      "${split("/", var.network_cidr)[0]}/${min(tonumber(split("/", var.network_cidr)[1]), tonumber(split("/", r)[1]))}", 0
      ) == cidrhost(
      "${split("/", r)[0]}/${min(tonumber(split("/", var.network_cidr)[1]), tonumber(split("/", r)[1]))}", 0
    )
  ]
}
```

Test both directions: `network_cidr = "192.168.0.0/16"` (contains the reserved range) and `reserved_cidrs = ["10.0.0.0/8"]` with the default `10.150.0.0/24` (inside the reserved range).

## Task 2: Pool Free Space

Add the pool postcondition from [Postconditions](#postconditions). Try `terraform apply -var min_free_gib=100000`, then look at `terraform state list`: the pool is there even though the apply failed.

## Task 3: Disk vs Image Size

A VM disk that is a copy-on-write clone must be at least as large as its base image. Add a precondition to the disk volume that compares `var.disk_gib` with the base volume's `capacity`.

### Example
```hcl
resource "libvirt_volume" "disk" {
  # ...
  lifecycle {
    precondition {
      condition     = var.disk_gib * local.gib >= libvirt_volume.base.capacity
      error_message = "disk_gib (${var.disk_gib}) is smaller than the base image (${ceil(libvirt_volume.base.capacity / local.gib)} GiB)."
    }
  }
}
```

Run it with `disk_gib = 1` and notice *when* it fails: after the download, not during plan.

## Task 4: VM Fits the Host

Use the `libvirt_node_info` data source to stop a VM from asking for more than half of the host's memory.

### Example
```hcl
data "libvirt_node_info" "host" {}

resource "libvirt_domain" "vm" {
  memory      = var.memory_mb
  memory_unit = "MiB"
  # ...

  lifecycle {
    precondition {
      condition     = var.memory_mb * 1024 <= data.libvirt_node_info.host.memory_total_kb / 2
      error_message = "memory_mb (${var.memory_mb}) is more than half of this host's ${floor(data.libvirt_node_info.host.memory_total_kb / 1024)} MiB."
    }
  }
}
```

The limit adapts to whoever runs the code: a 16 GiB laptop allows 8 GiB, a 256 GiB server 128 GiB.

## Task 5: The VM Actually Started

Add two postconditions to the VM: it must be running, and it must have at least one network interface.

### Example
```hcl
    postcondition {
      condition     = self.running
      error_message = "VM ${self.name} was created but isn't running."
    }

    postcondition {
      condition     = length(coalesce(self.devices.interfaces, [])) > 0
      error_message = "VM ${self.name} has no network interface."
    }
```

The second one looks unnecessary, since you *wrote* the interface. But Terraform silently ignores a misspelled key inside a nested attribute: change `interfaces` to `interface` in `main.tf` and run `terraform apply`. Without the postcondition you'd get a VM with no network and no error.

## Bonus Task: Postcondition on a Data Source

Data sources can have postconditions too. Read the VM's address with `libvirt_domain_interface_addresses` and check that it is inside `network_cidr`.

### Example
```hcl
data "libvirt_domain_interface_addresses" "vm" {
  domain = libvirt_domain.vm.name
  source = "lease"

  lifecycle {
    postcondition {
      condition = anytrue([
        for i in self.interfaces : anytrue([
          for a in i.addrs : a.type == "ipv4" && cidrhost("${a.addr}/${split("/", var.network_cidr)[1]}", 0) == cidrhost(var.network_cidr, 0)
        ])
      ])
      error_message = "${libvirt_domain.vm.name} has no IPv4 address inside ${var.network_cidr}."
    }
  }
}
```

## Testing Conditions

`example/tests/conditions.tftest.hcl` tests the conditions with a mocked provider. A few things about testing conditions that the example had to work around, and that you'll run into too:

| Situation | Solution |
|-----------|----------|
| A precondition depends on a value only known after apply (the image size) | `override_resource` with `override_during = plan`, so the value is known at plan time where `expect_failures` can catch it |
| A postcondition test reuses a resource an earlier run already created, so the override never applies | Give the run its own state with `state_key` (Terraform 1.11+) |
| The condition checks a value the configuration sets (`running = true`) | Can't be tested with mocks: overrides only replace computed values. It's there for real failures |
| The value is a computed *nested list* (the data source's `interfaces`) | Terraform 1.16/1.17 can't mock it (`expected object type, found tuple`). Verify with a real apply |

Remember to use appropriate error messages that clearly explain why a condition failed and what the correct configuration should be.

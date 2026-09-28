# Libvirt Network Setup with Terraform

Objective: Create a NAT network and an isolated network on your libvirt host using Terraform.

## Prerequisites:
- libvirt/KVM installed and running, see [docs/libvirt-setup.md](../../../docs/libvirt-setup.md)
- Terraform CLI
- Your user in the `libvirt` group (`virsh -c qemu:///system list` works without sudo)

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Tasks](#tasks)
3. [Applying the Configuration](#8-run-the-following-commands-to-initialize-terraform-plan-and-apply-your-changes)
4. [Verifying the Network Setup](#9-verify-that-your-networks-have-been-created)

## Tasks:

1. Using your experience from the previous block, create your `main.tf`, `variables.tf` and `terraform.tfvars` files.

2. Ensure you use the new required provider for this lab:
```hcl
libvirt = {
  source  = "dmacvicar/libvirt"
  version = "~> 0.9"
}
```

3. Next we configure the provider. There's no login step: Terraform talks to the libvirt daemon on your own machine. Add the following to your provider block:
```hcl
provider "libvirt" {
  uri = "qemu:///system"
}
```

4. Next we use a data source to get information about the host we're deploying to. Add the following to your `main.tf` file:
```hcl
data "libvirt_node_info" "host" {}

output "host_memory_mb" {
  value = floor(data.libvirt_node_info.host.memory_total_kb / 1024)
}
```

> A data source in Terraform is a read-only query that fetches information from an external source, such as a cloud provider or other infrastructure component. Data sources allow you to use existing resources or information in your Terraform configuration without managing them directly.
> Key points about data sources:
> 1. Read-only: Data sources don't create, modify, or delete resources. They only retrieve information.
> 2. External information: They fetch data from outside your Terraform configuration, like cloud provider APIs or other systems.
> 3. Use existing resources: Data sources let you reference and use properties of resources that already exist and aren't managed by your current Terraform configuration.
> 4. Dynamic configurations: They enable more dynamic and flexible Terraform configurations by allowing you to base your resource definitions on existing infrastructure.
> 5. Syntax: Data sources are defined using the `data` block in Terraform, similar to how resources are defined with the `resource` block.
> In the example above, `data "libvirt_node_info" "host"` asks libvirt about the machine it runs on: CPU model, core count and memory. Later you can use that to size VMs so they never ask for more memory than the host has.

5. Next we create the network resources, starting with a NAT network. VMs on it can reach the internet through your host, and libvirt hands out addresses with DHCP. Add the following to your `main.tf` file:
```hcl
resource "libvirt_network" "main" {
  name      = "${var.network_name}-net"
  autostart = true

  forward = {
    mode = "nat"
  }

  ips = [
    {
      address = "10.10.0.1" # the host's own address on this network
      prefix  = 24
      dhcp = {
        ranges = [{ start = "10.10.0.100", end = "10.10.0.200" }]
      }
    }
  ]
}
```

> Notice the `=` in `forward = { ... }`. In the libvirt provider these are *nested attributes*, not blocks. Be careful with the names too: if you misspell a key inside one of them, Terraform ignores it without an error.

6. Now add a second network that is isolated. VMs on it can talk to each other and to the host, but not to the internet. An isolated network is simply one without `forward`:
```hcl
resource "libvirt_network" "isolated" {
  name      = "${var.network_name}-isolated"
  autostart = false

  ips = [
    {
      address = "10.20.0.1"
      prefix  = 24
    }
  ]
}
```

No `dhcp` here either, so VMs on this network need a static address. That's a common choice for a backend network.

7. Finally, add your network name to your `variables.tf` and `terraform.tfvars` files.
```hcl
# variables.tf
variable "network_name" {
  type = string
}
```
```hcl
# terraform.tfvars
network_name = "tf-103"
```

8. Run the following commands to initialize Terraform, plan, and apply your changes:
```bash
terraform init
terraform plan
terraform apply
```

9. Verify that your networks have been created:
```bash
virsh -c qemu:///system net-list --all
virsh -c qemu:///system net-dumpxml tf-103-net
```

In the XML you'll find `<forward mode='nat'>` and the DHCP range. Run `net-dumpxml` on the isolated network and notice that it has neither.

To avoid typing `-c qemu:///system` every time, set it as your default connection:
```bash
export LIBVIRT_DEFAULT_URI=qemu:///system
```

The [`example/`](./example/) folder has a complete solution, with the addresses in variables and tests you can run with `terraform test`.

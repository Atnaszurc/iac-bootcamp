# Adding a Linux Virtual Machine to a Libvirt Setup with Terraform

Objective: Create Ubuntu Linux virtual machines on your libvirt host using Terraform.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Tasks](#tasks)
   - [Using a Custom Packer Image (Optional)](#using-a-custom-packer-image-optional)
3. [Verifying the Virtual Machines](#6-verify-the-virtual-machines)

## Prerequisites:
- Completed the previous blocks on networks and security
- libvirt/KVM installed and running
- Terraform CLI

## Tasks:

A VM on libvirt is built from a few pieces. It helps to know them before you start:

| Piece | Resource | Why |
|-------|----------|-----|
| Storage pool | `libvirt_pool` | A directory where libvirt keeps disk images |
| Base image | `libvirt_volume` | The Ubuntu cloud image, downloaded once |
| VM disk | `libvirt_volume` | A copy-on-write clone of the base image, one per VM |
| Cloud-init ISO | `libvirt_cloudinit_disk` + `libvirt_volume` | User, SSH key and packages for first boot |
| The VM | `libvirt_domain` | CPU, memory and the devices above |

1. Create a new file called `virtual-machine.tf` in your project directory.

2. Add a storage pool and the base image:
```hcl
resource "libvirt_pool" "vms" {
  name   = "${var.project_name}-vms"
  type   = "dir"
  target = { path = "/var/lib/libvirt/images/${var.project_name}-vms" }
}

resource "libvirt_volume" "base" {
  name = "${var.project_name}-base.qcow2"
  pool = libvirt_pool.vms.name
  create = {
    content = { url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" }
  }
  target = { format = { type = "qcow2" } }
}

resource "libvirt_volume" "vm_disk" {
  name     = "${var.project_name}-vm.qcow2"
  pool     = libvirt_pool.vms.name
  capacity = 10737418240 # 10 GB
  backing_store = {
    path   = libvirt_volume.base.path
    format = { type = "qcow2" }
  }
  target = { format = { type = "qcow2" } }
}
```

3. The cloud-init disk from the previous block is built on your machine. Upload it to the pool so the VM can use it:
```hcl
resource "libvirt_volume" "cloudinit" {
  name = "${var.project_name}-init.iso"
  pool = libvirt_pool.vms.name
  create = {
    content = { url = libvirt_cloudinit_disk.secure.path }
  }
}
```

4. Now the VM itself:
```hcl
resource "libvirt_domain" "vm" {
  name        = "${var.project_name}-vm"
  memory      = 1024
  memory_unit = "MiB" # the default unit is KiB!
  vcpu        = 1
  type        = "kvm"
  running     = true # the default is false: defined but not started

  os = { type = "hvm", type_arch = "x86_64", type_machine = "q35" }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.vm_disk.pool
            volume = libvirt_volume.vm_disk.name
          }
        }
        target = { dev = "vda", bus = "virtio" }
        driver = { type = "qcow2" }
      },
      {
        device = "cdrom" # cloud-init reads its config from here
        source = {
          volume = {
            pool   = libvirt_volume.cloudinit.pool
            volume = libvirt_volume.cloudinit.name
          }
        }
        target = { dev = "sda", bus = "sata" }
      }
    ]
    interfaces = [
      {
        model       = { type = "virtio" }
        source      = { network = { network = libvirt_network.secure.name } }
        wait_for_ip = { source = "lease" } # apply waits until DHCP has answered
      }
    ]
  }
}

data "libvirt_domain_interface_addresses" "vm" {
  domain = libvirt_domain.vm.name
  source = "lease"
}

output "vm_ip" {
  value = data.libvirt_domain_interface_addresses.vm.interfaces[0].addrs[0].addr
}
```

Three things in there trip up almost everyone the first time:
- Disks and networks are referenced by **name** (`pool`, `volume`, `network`), not by ID.
- Without `memory_unit = "MiB"`, `memory = 1024` means 1 MiB and the VM won't boot.
- The keys inside `devices` are plural (`disks`, `interfaces`). Write `disk` and Terraform silently ignores it, and you get a VM without a disk.

### Using a Custom Packer Image (Optional)

If you took part in the Packer training, you can use the image you built there. `url` also accepts a local path, so change the base image:
```hcl
create = {
  content = { url = "/var/lib/libvirt/images/ubuntu-web-v1.0.0.qcow2" }
}
```

5. Run `terraform plan` and `terraform apply` to create the virtual machine. The first apply downloads the Ubuntu image, so give it a minute or two.

6. Verify the virtual machines:
```bash
terraform output vm_ip
virsh -c qemu:///system list
virsh -c qemu:///system domblklist tf-103-vm   # both disks attached?
ssh terraform@$(terraform output -raw vm_ip)
```

With the static DHCP entry from the previous block, the IP is `10.30.0.10`.

The [`example/`](./example/) folder builds several VMs from a map variable with `for_each`, and has tests you can run with `terraform test`.

Once you are happy with your results, and with any changes you incorporate, run `terraform destroy` to destroy the entire setup in preparation for the next block.

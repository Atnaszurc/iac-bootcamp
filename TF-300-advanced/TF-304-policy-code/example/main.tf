# TF-304: Policy as Code — the infrastructure the policies check
#
# One network and a few VMs, each with a blank data disk. You never need to
# apply this: OPA checks the *plan*.
#
#   terraform init
#   terraform plan -var-file=violations.tfvars -out=tfplan
#   terraform show -json tfplan > plan.json
#   opa eval -d policy -i plan.json 'data.terraform.libvirt'
#
# plan.json in this directory was made exactly like that.

terraform {
  required_version = ">= 1.14"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_network" "app" {
  name      = var.network_name
  autostart = true
  forward   = { mode = var.network_mode }
  ips = [{
    address = "10.40.0.1"
    prefix  = 24
    dhcp = {
      ranges = [{ start = "10.40.0.100", end = "10.40.0.200" }]
    }
  }]
}

resource "libvirt_volume" "data" {
  for_each = var.vms

  name          = "${var.environment}-${each.key}-data.qcow2"
  pool          = var.pool
  capacity      = each.value.disk_gib
  capacity_unit = "GiB"
  target        = { format = { type = "qcow2" } }
}

resource "libvirt_domain" "vm" {
  for_each = var.vms

  name        = "${var.environment}-${each.key}"
  memory      = each.value.memory
  memory_unit = each.value.memory_unit
  vcpu        = each.value.vcpu
  type        = "kvm"
  os          = { type = "hvm" }

  # libvirt has no tags; the description is the closest thing
  description = "owner=${var.owner} environment=${var.environment}"

  devices = {
    disks = [{
      source = { volume = { pool = libvirt_volume.data[each.key].pool, volume = libvirt_volume.data[each.key].name } }
      target = { dev = "vda", bus = "virtio" }
      driver = { type = "qcow2" }
    }]
    interfaces = [{
      model = { type = "virtio" }
      # A VM joins the app network unless it names another one
      source = { network = { network = coalesce(each.value.network, libvirt_network.app.name) } }
    }]
  }
}

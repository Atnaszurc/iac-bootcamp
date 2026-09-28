# Securing a Libvirt Setup with Terraform

Objective: Limit who can join your network and harden the VM itself, using the libvirt network configuration and cloud-init.

## Prerequisites:
- Completed the previous block on setting up networks
- libvirt/KVM installed and running
- Terraform CLI

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Tasks](#tasks)
3. [Verifying the Setup](#5-verify-the-network-and-the-cloud-init-configuration)

## Where did the security group go?

If you've used a cloud provider, you'd reach for a security group now. libvirt doesn't have a Terraform resource for that. Its firewall feature (nwfilter) isn't managed by the provider. So we secure the setup at the two places we *do* control:

1. **The network**: who gets an address, and which address
2. **The VM**: a firewall inside the guest, set up by cloud-init on first boot

## Tasks:

1. If you haven't already, create a new file called `security.tf` in your project directory.

2. Add a network with a deliberately small DHCP range and a fixed address for the server:
```hcl
resource "libvirt_network" "secure" {
  name      = "${var.project_name}-secure-net"
  autostart = true

  forward = { mode = "nat" }

  ips = [
    {
      address = "10.30.0.1"
      prefix  = 24
      dhcp = {
        # Only 10 addresses for dynamic leases
        ranges = [{ start = "10.30.0.100", end = "10.30.0.109" }]
        # The hardened VM always gets .10, so firewall rules can rely on it
        hosts = [{ name = "${var.project_name}-secure-vm", ip = "10.30.0.10" }]
      }
    }
  ]
}
```

3. Add a cloud-init disk that hardens the guest on first boot: no root login, no passwords over SSH, and a firewall that only lets SSH in:
```hcl
resource "libvirt_cloudinit_disk" "secure" {
  name = "${var.project_name}-cloudinit.iso"

  user_data = <<-EOT
    #cloud-config
    hostname: ${var.project_name}-secure-vm
    disable_root: true
    ssh_pwauth: false
    users:
      - name: terraform
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_public_key}
    packages:
      - ufw
      - fail2ban
    runcmd:
      - ufw default deny incoming
      - ufw default allow outgoing
      - ufw allow ssh
      - ufw --force enable
  EOT

  meta_data = yamlencode({
    instance-id    = "${var.project_name}-secure-vm"
    local-hostname = "${var.project_name}-secure-vm"
  })
}
```

The disk isn't attached to anything yet. The next block creates the VM that boots from it.

4. Run `terraform plan` and `terraform apply`.

5. Verify the network and the cloud-init configuration:
```bash
virsh -c qemu:///system net-dumpxml tf-103-secure-net | grep -E "range|host "
```

You should see the range `.100` to `.109` and the host entry for `.10`.

The [`example/`](./example/) folder has a complete solution with a storage pool and base image already in place, plus tests you can run with `terraform test`.

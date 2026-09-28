# Production environment var-file
# Usage: packer build -var-file="prod.pkrvars.hcl" ubuntu.pkr.hcl
# Note: Set PKR_VAR_ssh_password environment variable before building

os_version     = "22.04"
disk_size      = "20G"
memory_mb      = 4096
cpu_count      = 4
headless       = true # No display in production builds
vm_name        = "ubuntu-prod"
extra_packages = ["curl", "wget", "unattended-upgrades", "fail2ban"]
# Development environment var-file
# Usage: packer build -var-file="dev.pkrvars.hcl" ubuntu.pkr.hcl

os_version     = "22.04"
disk_size      = "10G"
memory_mb      = 1024
cpu_count      = 1
headless       = false # Show display window for debugging
vm_name        = "ubuntu-dev"
extra_packages = ["curl", "wget", "vim", "htop"]
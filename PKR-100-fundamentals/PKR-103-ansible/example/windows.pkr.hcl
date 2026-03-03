# =============================================================================
# PKR-103: Ansible Configuration Management — Windows Server 2022
# Demonstrates: qemu builder + ansible provisioner for Windows
# Builder: hashicorp/qemu (local QEMU/KVM — no cloud credentials required)
# Run: packer init . && packer build windows.pkr.hcl
#
# Prerequisites:
#   - Windows Server 2022 evaluation ISO (free from Microsoft)
#   - VirtIO drivers ISO (https://fedorapeople.org/groups/virt/virtio-win/)
#   - Ansible with pywinrm: pip install pywinrm
# =============================================================================

packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "image_name" {
  description = "Output image name (without extension)"
  type        = string
  default     = "windows-server-2022-ansible"
}

variable "output_dir" {
  description = "Directory where the finished image will be written"
  type        = string
  default     = "output-windows-ansible"
}

variable "winrm_username" {
  description = "WinRM username for the build VM"
  type        = string
  default     = "Administrator"
}

variable "winrm_password" {
  description = "WinRM password for the build VM (used during build only)"
  type        = string
  default     = "Packer1234!"
  sensitive   = true
}

variable "memory_mb" {
  description = "RAM for the build VM (MiB)"
  type        = number
  default     = 4096
}

variable "cpus" {
  description = "vCPUs for the build VM"
  type        = number
  default     = 2
}

variable "windows_iso_path" {
  description = "Local path to the Windows Server 2022 evaluation ISO"
  type        = string
  default     = "iso/windows-server-2022.iso"
}

# ---------------------------------------------------------------------------
# Source: QEMU builder for Windows Server 2022
# ---------------------------------------------------------------------------

source "qemu" "windows_2022" {
  # Base ISO — Windows Server 2022 (local file, must be downloaded separately)
  iso_url      = var.windows_iso_path
  iso_checksum = "none"  # Set to actual checksum in production

  # Output
  output_directory = var.output_dir
  vm_name          = "${var.image_name}.qcow2"
  disk_image       = false
  format           = "qcow2"

  # VM resources
  memory    = var.memory_mb
  cpus      = var.cpus
  disk_size = "40G"

  # Accelerator
  accelerator = "kvm"

  # Network
  net_device = "virtio-net"

  # Autounattend for unattended Windows setup
  cd_files = ["autounattend/autounattend.xml"]
  cd_label = "AUTOUNATTEND"

  # WinRM communicator
  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "30m"
  winrm_insecure = true
  winrm_use_ssl  = true

  shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""

  # Boot configuration
  boot_wait    = "3s"
  boot_command = ["<spacebar>"]
}

# ---------------------------------------------------------------------------
# Build: Ansible provisioner for Windows
# ---------------------------------------------------------------------------

build {
  name    = "windows-server-2022-ansible"
  sources = ["source.qemu.windows_2022"]

  # Step 1: PowerShell — bootstrap WinRM for Ansible
  provisioner "powershell" {
    inline = [
      "Write-Host 'Configuring WinRM for Ansible...'",
      "winrm quickconfig -q",
      "winrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"512\"}'",
      "winrm set winrm/config '@{MaxTimeoutms=\"1800000\"}'",
      "winrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'",
      "winrm set winrm/config/service/auth '@{Basic=\"true\"}'",
      "Write-Host 'WinRM configured'"
    ]
  }

  # Step 2: Ansible provisioner — run Windows playbook
  provisioner "ansible" {
    playbook_file = "ansible/windows.yml"
    user          = var.winrm_username
    use_proxy     = false
    extra_arguments = [
      "-e", "ansible_winrm_server_cert_validation=ignore",
      "-e", "ansible_connection=winrm",
      "-e", "ansible_winrm_transport=basic"
    ]
  }

  # Step 3: Sysprep — generalise the image for deployment
  provisioner "powershell" {
    inline = [
      "Write-Host 'Running Sysprep...'",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit",
      "while ($true) {",
      "  $state = (Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State').ImageState",
      "  Write-Host \"Sysprep state: $state\"",
      "  if ($state -eq 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { break }",
      "  Start-Sleep -Seconds 10",
      "}"
    ]
  }

  # Post-processor: record the manifest
  post-processor "manifest" {
    output     = "${var.output_dir}/manifest.json"
    strip_path = true
  }
}

# TF-301 Section 1: Variable conditions
# Every input for the VM below is validated before Terraform plans anything.

# ─────────────────────────────────────────────────────────────────────────────
# Single condition
# ─────────────────────────────────────────────────────────────────────────────

variable "vm_name" {
  description = "Name of the VM, also used as its hostname"
  type        = string

  # A hostname label (RFC 1123): 1-63 characters, lowercase letters, digits
  # and hyphens, starting and ending with a letter or digit
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.vm_name))
    error_message = "vm_name must be a valid hostname: 1-63 characters, lowercase letters, digits and hyphens, not starting or ending with a hyphen."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Multiple conditions: each gets its own, specific error message
# ─────────────────────────────────────────────────────────────────────────────

variable "memory_mb" {
  description = "VM memory in MiB"
  type        = number
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

variable "network_cidr" {
  description = "IPv4 range for the VM network"
  type        = string
  default     = "10.130.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.network_cidr))
    error_message = "network_cidr must be an IPv4 CIDR block, e.g. 10.130.0.0/24."
  }

  # There's no "cidrcontains" function, so check containment by hand: put the
  # network's address into each private range's prefix length and see whether
  # the range's own network address comes out.
  # try(..., false): && does NOT short-circuit in Terraform, so for an invalid
  # CIDR the expression would error instead of returning false.
  validation {
    condition = try(anytrue([
      for r in ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] :
      tonumber(split("/", var.network_cidr)[1]) >= tonumber(split("/", r)[1]) &&
      cidrhost("${split("/", var.network_cidr)[0]}/${split("/", r)[1]}", 0) == cidrhost(r, 0)
    ]), false)
    error_message = "network_cidr must be inside a private range (10.0.0.0/8, 172.16.0.0/12 or 192.168.0.0/16)."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Cross-variable conditions (Terraform 1.9+): a condition may reference
# other variables
# ─────────────────────────────────────────────────────────────────────────────

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test or prod."
  }
}

variable "vm_count" {
  description = "Number of VMs"
  type        = number
  default     = 1

  validation {
    condition     = var.environment == "prod" ? var.vm_count >= 2 : var.vm_count >= 1
    error_message = "prod needs at least 2 VMs; other environments at least 1."
  }
}

variable "ssh_public_key" {
  description = "Public key for the terraform user"
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp[0-9]+) [A-Za-z0-9+/=]+( .*)?$", var.ssh_public_key))
    error_message = "ssh_public_key must be an OpenSSH public key (starting with ssh-ed25519, ssh-rsa or ecdsa-sha2-...). Did you paste the private key?"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Validating a list of objects: guest firewall rules (applied with ufw)
# ─────────────────────────────────────────────────────────────────────────────

variable "firewall_rules" {
  description = "Inbound ports to open in the guest firewall"
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

  validation {
    condition     = alltrue([for r in var.firewall_rules : r.from == "any" || can(cidrnetmask(r.from))])
    error_message = "from must be \"any\" or a CIDR block like 10.0.0.0/8."
  }

  # Cross-variable: in prod, SSH may not be open to the world
  validation {
    condition = var.environment != "prod" || alltrue([
      for r in var.firewall_rules : !(r.port == 22 && r.from == "any")
    ])
    error_message = "In prod, port 22 must be restricted with from = \"<cidr>\", not open to any."
  }
}

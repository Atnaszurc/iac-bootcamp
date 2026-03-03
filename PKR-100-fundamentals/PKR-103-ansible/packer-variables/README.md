# PKR-103 Supplemental: Packer Variables & Var-Files

**Course**: PKR-100 Packer Fundamentals  
**Module**: PKR-103 (Supplemental)  
**Duration**: 20 minutes  
**Prerequisites**: PKR-102 (QEMU Builder & Provisioners)  
**Packer Version**: 1.14+

---

## 📋 Overview

Packer variables work similarly to Terraform variables — they let you parameterize your templates so the same template can build different images without code changes. This section covers variable declaration, default values, var-files, and environment variable overrides.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Declare variables in a Packer template
- ✅ Set default values and add descriptions
- ✅ Override variables via CLI flags, var-files, and environment variables
- ✅ Use variables inside `source` and `build` blocks
- ✅ Organize variables with `.pkrvars.hcl` files
- ✅ Understand variable precedence order

---

## 📚 Declaring Variables

Variables are declared with a `variable` block:

```hcl
variable "os_version" {
  description = "Ubuntu LTS version to build"
  type        = string
  default     = "22.04"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = string
  default     = "10G"
}

variable "memory_mb" {
  description = "RAM in MB"
  type        = number
  default     = 2048
}

variable "headless" {
  description = "Run QEMU without a display window"
  type        = bool
  default     = true
}
```

### Using Variables

Reference variables with `var.<name>`:

```hcl
source "qemu" "ubuntu" {
  iso_url   = "https://releases.ubuntu.com/${var.os_version}/ubuntu-${var.os_version}-live-server-amd64.iso"
  disk_size = var.disk_size
  memory    = var.memory_mb
  headless  = var.headless
}
```

---

## 📚 Variable Types

Packer supports the same basic types as Terraform:

```hcl
# String
variable "vm_name" {
  type    = string
  default = "ubuntu-base"
}

# Number
variable "cpu_count" {
  type    = number
  default = 2
}

# Boolean
variable "enable_vnc" {
  type    = bool
  default = false
}

# List
variable "extra_packages" {
  type    = list(string)
  default = ["curl", "wget", "git"]
}

# Map
variable "image_tags" {
  type = map(string)
  default = {
    environment = "dev"
    team        = "platform"
  }
}
```

---

## 📚 Var-Files (`.pkrvars.hcl`)

Var-files let you define variable values in separate files — one per environment or use case:

### `dev.pkrvars.hcl`

```hcl
os_version = "22.04"
disk_size  = "10G"
memory_mb  = 1024
headless   = false  # Show display for debugging
vm_name    = "ubuntu-dev"
```

### `prod.pkrvars.hcl`

```hcl
os_version = "22.04"
disk_size  = "20G"
memory_mb  = 4096
headless   = true
vm_name    = "ubuntu-prod"
```

### Using Var-Files

```bash
# Build with dev settings
packer build -var-file="dev.pkrvars.hcl" template.pkr.hcl

# Build with prod settings
packer build -var-file="prod.pkrvars.hcl" template.pkr.hcl
```

**Note**: `.pkrvars.hcl` files are automatically loaded if they match `*.auto.pkrvars.hcl`. Otherwise, specify them with `-var-file`.

---

## 📚 Variable Precedence (Highest to Lowest)

```
1. -var flag on CLI          (highest priority)
   packer build -var "os_version=24.04" template.pkr.hcl

2. -var-file flag on CLI
   packer build -var-file="prod.pkrvars.hcl" template.pkr.hcl

3. *.auto.pkrvars.hcl files  (auto-loaded)

4. PKR_VAR_<name> environment variables
   export PKR_VAR_os_version="24.04"

5. Default values in variable blocks  (lowest priority)
```

---

## 📚 Environment Variable Overrides

Packer reads environment variables prefixed with `PKR_VAR_`:

```bash
# Override os_version via environment variable
export PKR_VAR_os_version="24.04"
export PKR_VAR_memory_mb="4096"

packer build template.pkr.hcl
# Uses os_version=24.04 and memory_mb=4096
```

This is useful for CI/CD pipelines where you don't want to commit var-files with environment-specific values.

---

## 📚 Sensitive Variables

Mark variables as sensitive to prevent them from appearing in logs:

```hcl
variable "ssh_password" {
  description = "SSH password for the build user"
  type        = string
  sensitive   = true
  # No default — must be provided at runtime
}

variable "api_key" {
  description = "API key for image registry"
  type        = string
  sensitive   = true
}
```

```bash
# Provide sensitive values via environment variables (recommended)
export PKR_VAR_ssh_password="my-secure-password"
export PKR_VAR_api_key="abc123"

packer build template.pkr.hcl
```

---

## 📚 Local Values

Use `locals` for computed or derived values:

```hcl
variable "os_version" {
  default = "22.04"
}

variable "build_date" {
  default = ""  # Will be overridden by local
}

locals {
  # Computed values
  timestamp  = formatdate("YYYYMMDD-HHmmss", timestamp())
  image_name = "ubuntu-${var.os_version}-${local.timestamp}"

  # Derived from variables
  iso_url = "https://releases.ubuntu.com/${var.os_version}/ubuntu-${var.os_version}-live-server-amd64.iso"
}

source "qemu" "ubuntu" {
  iso_url  = local.iso_url
  vm_name  = "${local.image_name}.qcow2"
}
```

---

## 📚 Complete Example with Var-Files

### Template: `ubuntu.pkr.hcl`

```hcl
packer {
  required_version = ">= 1.14.0"
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1.0"
    }
  }
}

variable "os_version"  { type = string; default = "22.04" }
variable "disk_size"   { type = string; default = "10G" }
variable "memory_mb"   { type = number; default = 2048 }
variable "headless"    { type = bool;   default = true }
variable "vm_name"     { type = string; default = "ubuntu-base" }
variable "ssh_password" {
  type      = string
  sensitive = true
  default   = "ubuntu"
}

locals {
  timestamp  = formatdate("YYYYMMDD", timestamp())
  image_name = "${var.vm_name}-${var.os_version}-${local.timestamp}"
}

source "qemu" "ubuntu" {
  iso_url      = "https://releases.ubuntu.com/${var.os_version}/ubuntu-${var.os_version}-live-server-amd64.iso"
  iso_checksum = "sha256:..."
  disk_size    = var.disk_size
  memory       = var.memory_mb
  headless     = var.headless
  vm_name      = "${local.image_name}.qcow2"
  format       = "qcow2"

  ssh_username = "ubuntu"
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"

  output_directory = "output-${var.vm_name}"
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    inline = ["echo 'Building ${local.image_name}'"]
  }

  post-processor "manifest" {
    output = "manifest.json"
    custom_data = {
      image_name = local.image_name
      os_version = var.os_version
      build_date = local.timestamp
    }
  }
}
```

### Build Commands

```bash
# Use defaults
packer build ubuntu.pkr.hcl

# Use dev var-file
packer build -var-file="dev.pkrvars.hcl" ubuntu.pkr.hcl

# Override a single variable
packer build -var "os_version=24.04" ubuntu.pkr.hcl

# Combine var-file with CLI override
packer build -var-file="prod.pkrvars.hcl" -var "headless=false" ubuntu.pkr.hcl
```

---

## 🧪 Hands-On Lab

### Lab: Parameterize a Packer Template

**Step 1**: Take an existing template and extract hardcoded values into variables:

```hcl
# Before: hardcoded
source "qemu" "ubuntu" {
  disk_size = "10G"
  memory    = 2048
}

# After: parameterized
variable "disk_size" { default = "10G" }
variable "memory_mb" { default = 2048 }

source "qemu" "ubuntu" {
  disk_size = var.disk_size
  memory    = var.memory_mb
}
```

**Step 2**: Create two var-files:

```bash
# dev.pkrvars.hcl
echo 'disk_size = "5G"
memory_mb = 1024' > dev.pkrvars.hcl

# prod.pkrvars.hcl
echo 'disk_size = "20G"
memory_mb = 4096' > prod.pkrvars.hcl
```

**Step 3**: Validate with each var-file:

```bash
packer validate -var-file="dev.pkrvars.hcl" ubuntu.pkr.hcl
packer validate -var-file="prod.pkrvars.hcl" ubuntu.pkr.hcl
```

**Step 4**: Inspect the variable values:

```bash
packer inspect ubuntu.pkr.hcl
```

---

## ✅ Checkpoint Quiz

**Question 1**: What is the highest-priority way to set a Packer variable?
- A) Default value in the variable block
- B) `*.auto.pkrvars.hcl` file
- C) `-var` flag on the CLI
- D) `PKR_VAR_` environment variable

<details>
<summary>Answer</summary>
**C) `-var` flag on the CLI** — CLI flags have the highest precedence, overriding var-files, auto-loaded files, environment variables, and defaults.
</details>

---

**Question 2**: How do you prevent a sensitive variable value from appearing in Packer logs?
- A) Use `type = "secret"`
- B) Set `sensitive = true` in the variable block
- C) Prefix the variable name with `_`
- D) Store it in a `.env` file

<details>
<summary>Answer</summary>
**B) Set `sensitive = true` in the variable block** — Marking a variable as sensitive causes Packer to redact its value in log output, similar to Terraform's sensitive variables.
</details>

---

## 📚 Key Takeaways

| Concept | Detail |
|---------|--------|
| `variable` block | Declares a parameterized input with type, default, description |
| `var.<name>` | References a variable value |
| `.pkrvars.hcl` | Var-file for environment-specific values |
| `-var-file` | CLI flag to load a var-file |
| `PKR_VAR_<name>` | Environment variable override |
| `sensitive = true` | Redacts value from logs |
| `locals` | Computed/derived values from variables |
| Precedence | CLI > var-file > auto-file > env var > default |

---

## 🔗 Related Topics

- **Back to**: [PKR-103 Main README](../README.md)
- **Next**: [PKR-104: Image Versioning & HCP Packer](../../PKR-104-versioning-hcp/README.md)
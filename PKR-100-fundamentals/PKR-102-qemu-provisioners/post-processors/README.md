# PKR-102 Supplemental: Post-Processors

**Course**: PKR-100 Packer Fundamentals  
**Module**: PKR-102 (Supplemental)  
**Duration**: 20 minutes  
**Prerequisites**: PKR-102 (QEMU Builder & Provisioners)  
**Packer Version**: 1.14+

---

## 📋 Overview

Post-processors run **after** the builder and provisioners complete. They transform, compress, upload, or record the finished artifact. This section covers the two most useful post-processors for local/QEMU workflows: `shell-local` and `manifest`.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Explain what post-processors do and when they run
- ✅ Use `shell-local` to run commands on the build machine after image creation
- ✅ Use `manifest` to record build metadata to a JSON file
- ✅ Chain multiple post-processors together
- ✅ Understand the difference between provisioners and post-processors

---

## 🔑 Post-Processor vs Provisioner

```
Build Timeline:
  1. Builder starts (QEMU boots the VM)
  2. Provisioners run (INSIDE the VM — shell, ansible, file)
  3. Builder shuts down and exports the image
  4. Post-processors run (on the BUILD MACHINE — not inside the VM)

Key difference:
  Provisioner  → runs inside the image being built
  Post-processor → runs on your local machine after the image is done
```

---

## 📚 `shell-local` Post-Processor

Runs a shell command on the **build machine** after the image is created. Useful for:
- Compressing the output image
- Moving the image to a storage location
- Sending a notification
- Registering the image with a catalog

### Basic Syntax

```hcl
post-processor "shell-local" {
  inline = ["echo 'Build complete!'"]
}
```

### Practical Examples

```hcl
# Compress the output image with qemu-img
post-processor "shell-local" {
  inline = [
    "qemu-img convert -O qcow2 -c output-ubuntu/ubuntu.qcow2 output-ubuntu/ubuntu-compressed.qcow2",
    "echo 'Compression complete'"
  ]
}

# Move image to a shared storage location
post-processor "shell-local" {
  inline = [
    "cp output-ubuntu/ubuntu.qcow2 /var/lib/libvirt/images/ubuntu-base.qcow2",
    "chmod 644 /var/lib/libvirt/images/ubuntu-base.qcow2"
  ]
}

# Send a notification (example using curl)
post-processor "shell-local" {
  inline = [
    "echo 'Image build completed at $(date)' >> /var/log/packer-builds.log"
  ]
}
```

### Using `script` Instead of `inline`

For longer post-processing logic, use a script file:

```hcl
post-processor "shell-local" {
  script = "scripts/post-build.sh"
}
```

```bash
#!/bin/bash
# scripts/post-build.sh
set -e

IMAGE_PATH="output-ubuntu/ubuntu.qcow2"
DEST="/var/lib/libvirt/images"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "Post-processing image: ${IMAGE_PATH}"

# Compress
qemu-img convert -O qcow2 -c "${IMAGE_PATH}" "${IMAGE_PATH}.compressed"

# Move to destination with timestamp
mv "${IMAGE_PATH}.compressed" "${DEST}/ubuntu-${TIMESTAMP}.qcow2"

echo "Image available at: ${DEST}/ubuntu-${TIMESTAMP}.qcow2"
```

---

## 📚 `manifest` Post-Processor

Records build metadata to a JSON file. Useful for:
- Tracking which images were built and when
- CI/CD pipelines that need to know the output artifact path
- Auditing image builds

### Basic Syntax

```hcl
post-processor "manifest" {
  output     = "manifest.json"
  strip_path = true
}
```

### Output Format

After a build, `manifest.json` contains:

```json
{
  "builds": [
    {
      "name": "ubuntu-qemu",
      "builder_type": "qemu",
      "build_time": 1709123456,
      "files": [
        {
          "name": "ubuntu.qcow2",
          "size": 1073741824
        }
      ],
      "artifact_id": "output-ubuntu/ubuntu.qcow2",
      "packer_run_uuid": "abc123-...",
      "custom_data": {
        "version": "22.04",
        "build_date": "2026-02-28"
      }
    }
  ],
  "last_run_uuid": "abc123-..."
}
```

### Adding Custom Data

Use `custom_data` to embed metadata from your build:

```hcl
post-processor "manifest" {
  output     = "manifest.json"
  strip_path = true
  custom_data = {
    version    = var.os_version
    build_date = formatdate("YYYY-MM-DD", timestamp())
    built_by   = "packer"
  }
}
```

---

## 📚 Chaining Post-Processors

Post-processors can be chained — the output of one feeds into the next. Use a list syntax:

```hcl
# Sequential: compress THEN record to manifest
post-processors {
  post-processor "shell-local" {
    inline = ["qemu-img convert -O qcow2 -c output/image.qcow2 output/image-compressed.qcow2"]
  }
  post-processor "manifest" {
    output = "manifest.json"
  }
}
```

**Note**: When using the list syntax (nested in `post-processors {}`), each post-processor in the chain receives the artifact from the previous one. When using separate `post-processor` blocks at the top level, they each receive the original builder artifact independently.

---

## 📚 Complete Example

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

variable "os_version" {
  default = "22.04"
}

source "qemu" "ubuntu" {
  iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
  iso_checksum = "sha256:..."
  disk_size    = "10G"
  memory       = 2048
  headless     = true

  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  ssh_timeout  = "20m"

  output_directory = "output-ubuntu"
  vm_name          = "ubuntu.qcow2"
  format           = "qcow2"
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
  }

  # Post-processor 1: compress the image
  post-processor "shell-local" {
    inline = [
      "echo 'Compressing image...'",
      "qemu-img info output-ubuntu/ubuntu.qcow2"
    ]
  }

  # Post-processor 2: record build metadata
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      os_version = var.os_version
      build_date = formatdate("YYYY-MM-DD", timestamp())
    }
  }
}
```

---

## 🧪 Hands-On Lab

### Lab: Add Post-Processors to a Build

**Step 1**: Add a `manifest` post-processor to an existing template:

```hcl
post-processor "manifest" {
  output     = "packer-manifest.json"
  strip_path = true
  custom_data = {
    build_date = formatdate("YYYY-MM-DD", timestamp())
  }
}
```

**Step 2**: Run the build:

```bash
packer build template.pkr.hcl
```

**Step 3**: Inspect the manifest:

```bash
cat packer-manifest.json
```

**Step 4**: Add a `shell-local` post-processor to log the build:

```hcl
post-processor "shell-local" {
  inline = ["echo 'Build finished: $(date)' >> build.log"]
}
```

---

## ✅ Checkpoint Quiz

**Question 1**: When does a post-processor run relative to provisioners?
- A) Before provisioners
- B) Inside the VM being built
- C) After the builder exports the image, on the build machine
- D) During the builder phase

<details>
<summary>Answer</summary>
**C) After the builder exports the image, on the build machine** — Post-processors run on your local machine after the image has been fully built and exported. Provisioners run inside the VM during the build.
</details>

---

**Question 2**: What does the `manifest` post-processor produce?
- A) A compressed version of the image
- B) A JSON file recording build metadata and artifact paths
- C) An uploaded image in a registry
- D) A checksum file for the image

<details>
<summary>Answer</summary>
**B) A JSON file recording build metadata and artifact paths** — The `manifest` post-processor writes a JSON file containing build details including artifact paths, build time, builder type, and any custom data you specify.
</details>

---

## 📚 Key Takeaways

| Concept | Detail |
|---------|--------|
| `shell-local` | Runs commands on the build machine after image creation |
| `manifest` | Records build metadata to a JSON file |
| Chaining | Use `post-processors {}` block to chain post-processors |
| vs provisioner | Provisioners run inside the VM; post-processors run on the build machine |
| `custom_data` | Embed version, date, and other metadata in the manifest |

---

## 🔗 Related Topics

- **Back to**: [PKR-102 Main README](../README.md)
- **Next**: [PKR-103: Ansible Configuration Management](../../PKR-103-ansible/README.md)
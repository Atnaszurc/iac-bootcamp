# TF-306 Section 4: Encoding Functions

**Course**: TF-306 Terraform Functions Deep Dive  
**Section**: 4 of 4  
**Duration**: 20 minutes  
**Prerequisites**: TF-102 (Variables, Loops & Functions)  
**Terraform Version**: 1.14+

---

## 📋 Overview

Encoding functions convert data between formats — JSON, YAML, Base64, and Terraform's native types. These are essential for working with cloud APIs, generating configuration files, passing structured data between modules, and handling secrets safely.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Use `jsonencode()` and `jsondecode()` to convert between HCL and JSON
- ✅ Use `yamlencode()` and `yamldecode()` to convert between HCL and YAML
- ✅ Use `base64encode()` and `base64decode()` for binary-safe encoding
- ✅ Use `tostring()`, `tonumber()`, `tobool()` for type conversion
- ✅ Apply encoding functions for cloud-init, IAM policies, and API payloads

---

## 📚 `jsonencode()` and `jsondecode()`

### `jsonencode()` — HCL → JSON

Converts a Terraform value (map, list, object) to a JSON string:

```hcl
locals {
  # Simple map to JSON
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::my-bucket/*"
      }
    ]
  })
}

# Result:
# {"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject","s3:PutObject"],"Resource":"arn:aws:s3:::my-bucket/*"}]}
```

### `jsondecode()` — JSON → HCL

Parses a JSON string into a Terraform map/list:

```hcl
locals {
  raw_json = <<-JSON
    {
      "environment": "production",
      "replicas": 3,
      "features": ["auth", "logging"]
    }
  JSON

  config = jsondecode(local.raw_json)
  # Access: local.config.environment → "production"
  # Access: local.config.replicas    → 3
  # Access: local.config.features    → ["auth", "logging"]
}
```

### Real-World: Load JSON Config Files

```hcl
locals {
  # Load a JSON config file
  app_config = jsondecode(file("${path.module}/config/app.json"))

  # Use values from the config
  db_host = local.app_config.database.host
  db_port = local.app_config.database.port
}
```

---

## 📚 `yamlencode()` and `yamldecode()`

### `yamlencode()` — HCL → YAML

Converts a Terraform value to a YAML string:

```hcl
locals {
  cloud_init = yamlencode({
    hostname = "web-server-01"
    users = [
      {
        name  = "ubuntu"
        shell = "/bin/bash"
        sudo  = "ALL=(ALL) NOPASSWD:ALL"
      }
    ]
    packages = ["nginx", "curl", "git"]
    runcmd = [
      "systemctl enable nginx",
      "systemctl start nginx"
    ]
  })
}

# Result (YAML format):
# hostname: web-server-01
# users:
#   - name: ubuntu
#     shell: /bin/bash
#     sudo: ALL=(ALL) NOPASSWD:ALL
# packages:
#   - nginx
#   - curl
#   - git
```

### `yamldecode()` — YAML → HCL

Parses a YAML string into a Terraform map/list:

```hcl
locals {
  # Load a YAML config file
  servers = yamldecode(file("${path.module}/config/servers.yaml"))

  # servers.yaml content:
  # web:
  #   count: 3
  #   size: medium
  # db:
  #   count: 1
  #   size: large

  web_count = local.servers.web.count  # → 3
  db_size   = local.servers.db.size    # → "large"
}
```

### `yamlencode()` vs `templatefile()` for YAML

```hcl
# Option 1: yamlencode() — structured, type-safe
locals {
  cloud_init_yaml = yamlencode({
    packages = var.packages
    runcmd   = var.startup_commands
  })
}

# Option 2: templatefile() — more control over formatting
locals {
  cloud_init_yaml = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    packages = var.packages
    commands = var.startup_commands
  })
}

# Use yamlencode() when: data is dynamic, structure varies
# Use templatefile() when: exact formatting matters (e.g., cloud-init requires #cloud-config header)
```

---

## 📚 `base64encode()` and `base64decode()`

### `base64encode()` — String → Base64

Encodes a UTF-8 string to Base64:

```hcl
locals {
  # Encode a script for user_data (AWS EC2 pattern)
  startup_script = base64encode(<<-SCRIPT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
  SCRIPT
  )
}

# Many cloud APIs accept Base64-encoded user_data
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  user_data     = local.startup_script
}
```

### `base64decode()` — Base64 → String

Decodes a Base64 string back to UTF-8:

```hcl
locals {
  # Decode a Base64-encoded secret from a data source
  decoded_secret = base64decode(data.aws_secretsmanager_secret_version.app.secret_string)
}
```

### `base64gzip()` — Compress + Encode

For large scripts, compress before encoding:

```hcl
locals {
  # Compress and encode a large script
  compressed_script = base64gzip(file("${path.module}/scripts/large-setup.sh"))
}
```

---

## 📚 Type Conversion Functions

Convert between Terraform's primitive types:

### `tostring()`

```hcl
locals {
  port_number = 8080
  port_string = tostring(local.port_number)  # → "8080"

  # Useful when building strings from numbers
  connection_string = "host:${tostring(var.port)}"

  # Convert bool to string
  flag_string = tostring(true)  # → "true"
}
```

### `tonumber()`

```hcl
locals {
  port_string = "8080"
  port_number = tonumber(local.port_string)  # → 8080

  # Useful when reading from YAML/JSON where types may be strings
  config      = yamldecode(file("config.yaml"))
  replica_count = tonumber(local.config.replicas)
}
```

### `tobool()`

```hcl
locals {
  flag_string = "true"
  flag_bool   = tobool(local.flag_string)  # → true

  # Valid inputs: "true", "false", true, false
}
```

### `tolist()`, `toset()`, `tomap()`

```hcl
locals {
  # Convert tuple to list (makes it indexable)
  items_list = tolist(["a", "b", "c"])

  # Convert list to set (removes duplicates, loses order)
  unique_items = toset(["a", "b", "a", "c"])  # → {"a", "b", "c"}

  # Convert object to map (all values must be same type)
  string_map = tomap({
    key1 = "value1"
    key2 = "value2"
  })
}
```

---

## 📚 Real-World Pattern: IAM Policy Generation

```hcl
variable "s3_buckets" {
  default = ["logs-bucket", "data-bucket", "backup-bucket"]
}

locals {
  # Generate IAM policy dynamically
  iam_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for bucket in var.s3_buckets : {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [
          "arn:aws:s3:::${bucket}",
          "arn:aws:s3:::${bucket}/*"
        ]
      }
    ]
  })
}
```

---

## 📚 Real-World Pattern: Cloud-Init with `yamlencode()`

```hcl
variable "vm_packages" {
  default = ["nginx", "curl", "git", "htop"]
}

variable "vm_users" {
  default = [
    { name = "ubuntu", groups = ["sudo", "docker"] }
  ]
}

locals {
  # Build cloud-init config programmatically
  # Note: prepend #cloud-config header manually
  cloud_init_body = yamlencode({
    packages = var.vm_packages
    users = [
      for user in var.vm_users : {
        name   = user.name
        groups = join(",", user.groups)
        shell  = "/bin/bash"
        sudo   = "ALL=(ALL) NOPASSWD:ALL"
      }
    ]
    runcmd = [
      "systemctl enable nginx",
      "systemctl start nginx"
    ]
  })

  # Prepend the required cloud-init header
  cloud_init_config = "#cloud-config\n${local.cloud_init_body}"
}
```

---

## 🧪 Hands-On Lab

### Lab: Encoding Pipeline

**Goal**: Build a configuration pipeline that reads YAML, transforms it, and outputs JSON.

**Step 1**: Create `config/servers.yaml`:

```yaml
servers:
  web:
    count: 3
    cpu: 2
    memory_gb: 4
  db:
    count: 1
    cpu: 4
    memory_gb: 16
```

**Step 2**: Read, transform, and re-encode:

```hcl
locals {
  # Read YAML config
  raw_config = yamldecode(file("${path.module}/config/servers.yaml"))

  # Transform: add computed fields
  enriched_servers = {
    for name, spec in local.raw_config.servers :
    name => merge(spec, {
      total_cpu    = spec.count * spec.cpu
      total_memory = spec.count * spec.memory_gb
      tier         = spec.count > 1 ? "high-availability" : "single-instance"
    })
  }

  # Output as JSON
  servers_json = jsonencode(local.enriched_servers)
}

resource "local_file" "servers_json" {
  filename = "${path.module}/output/servers.json"
  content  = local.servers_json
}
```

**Step 3**: Apply and inspect:

```bash
terraform init
terraform apply -auto-approve
cat output/servers.json | python3 -m json.tool
```

---

## ✅ Checkpoint Quiz

**Question 1**: When should you use `yamlencode()` instead of `templatefile()` for generating YAML?
- A) Always — `yamlencode()` is always better
- B) When the data structure is dynamic and type safety matters
- C) When you need exact formatting control (e.g., specific indentation)
- D) Never — `templatefile()` is always better

<details>
<summary>Answer</summary>
**B) When the data structure is dynamic and type safety matters** — `yamlencode()` is ideal when the structure varies based on variables (e.g., a list of users that could be empty). `templatefile()` is better when exact formatting is required, such as the `#cloud-config` header that cloud-init requires on the first line.
</details>

---

**Question 2**: What does `base64encode(file("script.sh"))` do?
- A) Compresses the file and encodes it
- B) Reads the file contents and returns a Base64-encoded string
- C) Writes a Base64-encoded file to disk
- D) Decodes a Base64 file

<details>
<summary>Answer</summary>
**B) Reads the file contents and returns a Base64-encoded string** — `file()` reads the raw contents, then `base64encode()` converts that string to Base64. This is commonly used for `user_data` in cloud VM resources that expect Base64-encoded scripts.
</details>

---

## 📚 Key Takeaways

| Function | Direction | Use Case |
|----------|-----------|---------|
| `jsonencode()` | HCL → JSON string | IAM policies, API payloads |
| `jsondecode()` | JSON string → HCL | Load JSON config files |
| `yamlencode()` | HCL → YAML string | Cloud-init, Kubernetes manifests |
| `yamldecode()` | YAML string → HCL | Load YAML config files |
| `base64encode()` | String → Base64 | VM user_data, binary-safe transfer |
| `base64decode()` | Base64 → String | Decode API responses |
| `tostring()` | Any → string | Type coercion for string interpolation |
| `tonumber()` | String → number | Parse numeric values from configs |
| `tobool()` | String → bool | Parse boolean flags from configs |
| `toset()` | List → set | Remove duplicates, use with for_each |

---

## 🔗 Next Steps

- **Previous**: [Section 3: Filesystem Functions](../3-filesystem-functions/README.md)
- **Back to**: [TF-306 Course Overview](../README.md)
- **Continue to**: [TF-300 Advanced Course Overview](../../README.md)
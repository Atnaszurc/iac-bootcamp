# TF-306 Section 3: Filesystem Functions

**Course**: TF-306 Terraform Functions Deep Dive  
**Section**: 3 of 4  
**Duration**: 20 minutes  
**Prerequisites**: TF-102 (Variables, Loops & Functions)  
**Terraform Version**: 1.14+

---

## 📋 Overview

Filesystem functions let Terraform read files from disk at plan/apply time. This is essential for loading configuration files, rendering templates, and discovering files dynamically — keeping your Terraform code clean while externalizing configuration data.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Use `file()` to read file contents into a string
- ✅ Use `templatefile()` to render templates with variable substitution
- ✅ Use `fileset()` to discover files matching a pattern
- ✅ Use `filebase64()` for binary file encoding
- ✅ Apply filesystem functions for cloud-init, scripts, and config files

---

## 📚 `file()`

Reads the contents of a file and returns it as a string:

```hcl
# Read a shell script
resource "libvirt_domain" "vm" {
  cloudinit = libvirt_cloudinit_disk.init.id
}

resource "libvirt_cloudinit_disk" "init" {
  name      = "init.iso"
  user_data = file("${path.module}/cloud-init/user-data.yaml")
}
```

### Common Uses

```hcl
locals {
  # Read SSH public key
  ssh_public_key = file("${path.module}/keys/id_rsa.pub")

  # Read a script
  startup_script = file("${path.module}/scripts/startup.sh")

  # Read a certificate
  tls_cert = file("${path.module}/certs/server.crt")
}
```

### Path Functions

Always use path variables with `file()` to ensure correct relative paths:

```hcl
# path.module  — directory of the current .tf file
# path.root    — directory of the root module
# path.cwd     — current working directory

locals {
  config = file("${path.module}/config/app.conf")
}
```

---

## 📚 `templatefile()`

Renders a template file with variable substitution. More powerful than `file()` — supports loops and conditionals:

### Template File: `user-data.yaml.tftpl`

```yaml
#cloud-config
hostname: ${hostname}
users:
  - name: ${admin_user}
    ssh_authorized_keys:
      - ${ssh_public_key}
    sudo: ALL=(ALL) NOPASSWD:ALL

packages:
%{ for pkg in packages ~}
  - ${pkg}
%{ endfor ~}

runcmd:
  - echo "Environment: ${environment}" > /etc/environment
  - systemctl enable ${service_name}
  - systemctl start ${service_name}
```

### Using `templatefile()`

```hcl
locals {
  user_data = templatefile("${path.module}/templates/user-data.yaml.tftpl", {
    hostname       = "web-server-01"
    admin_user     = "ubuntu"
    ssh_public_key = file("${path.module}/keys/id_rsa.pub")
    environment    = var.environment
    packages       = ["nginx", "curl", "wget"]
    service_name   = "nginx"
  })
}

resource "libvirt_cloudinit_disk" "init" {
  name      = "init.iso"
  user_data = local.user_data
}
```

### Template Syntax

```
${variable}              — Insert variable value
%{ if condition }        — Conditional block
%{ for item in list }    — Loop block
%{ endfor }              — End loop
%{ endif }               — End conditional
~                        — Strip whitespace/newline (trim marker)
```

### Conditional in Template

```
# nginx.conf.tftpl
server {
    listen ${port};
    server_name ${server_name};

%{ if enable_ssl ~}
    ssl_certificate     /etc/ssl/certs/server.crt;
    ssl_certificate_key /etc/ssl/private/server.key;
%{ endif ~}

    location / {
        proxy_pass http://${backend_host}:${backend_port};
    }
}
```

```hcl
locals {
  nginx_config = templatefile("${path.module}/templates/nginx.conf.tftpl", {
    port         = 443
    server_name  = "api.example.com"
    enable_ssl   = true
    backend_host = "localhost"
    backend_port = 8080
  })
}
```

---

## 📚 `fileset()`

Returns a set of file paths matching a glob pattern — useful for discovering configuration files dynamically:

```hcl
# Find all .yaml files in a directory
locals {
  config_files = fileset("${path.module}/configs", "*.yaml")
  # → toset(["app.yaml", "database.yaml", "cache.yaml"])

  # Find files in subdirectories
  all_scripts = fileset("${path.module}/scripts", "**/*.sh")
  # → toset(["setup/install.sh", "setup/configure.sh", "cleanup/remove.sh"])
}
```

### Real-World Use: Load All Config Files

```hcl
locals {
  # Discover all policy files
  policy_files = fileset("${path.module}/policies", "*.json")

  # Load each file's content into a map
  policies = {
    for filename in local.policy_files :
    trimsuffix(filename, ".json") => jsondecode(
      file("${path.module}/policies/${filename}")
    )
  }
}

# Create a resource for each policy
resource "local_file" "policy_output" {
  for_each = local.policies
  filename = "${path.module}/output/${each.key}-processed.json"
  content  = jsonencode(each.value)
}
```

---

## 📚 `filebase64()`

Reads a file and returns its contents as a Base64-encoded string. Used for binary files or when an API requires Base64 input:

```hcl
locals {
  # Encode a binary file (e.g., a certificate or image)
  cert_base64   = filebase64("${path.module}/certs/server.crt")
  logo_base64   = filebase64("${path.module}/assets/logo.png")
}
```

---

## 📚 Real-World Pattern: Multi-VM Cloud-Init

```hcl
variable "vms" {
  default = {
    web = { role = "webserver", packages = ["nginx"] }
    api = { role = "apiserver", packages = ["nodejs", "npm"] }
    db  = { role = "database",  packages = ["postgresql"] }
  }
}

locals {
  # Generate cloud-init for each VM from a shared template
  cloud_init_configs = {
    for name, config in var.vms :
    name => templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
      hostname   = name
      role       = config.role
      packages   = config.packages
      ssh_key    = file("${path.module}/keys/id_rsa.pub")
    })
  }
}
```

---

## 🧪 Hands-On Lab

### Lab: Template-Driven Configuration

**Step 1**: Create a template file `templates/app.conf.tftpl`:

```
# Application Configuration
# Generated by Terraform — do not edit manually

[server]
host = ${host}
port = ${port}
environment = ${environment}

[features]
%{ for feature in enabled_features ~}
${feature} = enabled
%{ endfor ~}
```

**Step 2**: Use `templatefile()` in your configuration:

```hcl
locals {
  app_config = templatefile("${path.module}/templates/app.conf.tftpl", {
    host             = "0.0.0.0"
    port             = 8080
    environment      = "production"
    enabled_features = ["auth", "logging", "metrics"]
  })
}

resource "local_file" "app_config" {
  filename = "${path.module}/output/app.conf"
  content  = local.app_config
}
```

**Step 3**: Apply and inspect the output:

```bash
terraform init
terraform apply -auto-approve
cat output/app.conf
```

---

## ✅ Checkpoint Quiz

**Question 1**: What is the difference between `file()` and `templatefile()`?
- A) `file()` is faster; `templatefile()` is more accurate
- B) `file()` reads raw content; `templatefile()` renders variables and loops
- C) `file()` works on any OS; `templatefile()` only works on Linux
- D) There is no difference

<details>
<summary>Answer</summary>
**B) `file()` reads raw content; `templatefile()` renders variables and loops** — `file()` returns the file contents unchanged. `templatefile()` processes `${variable}` substitutions and `%{ for }` / `%{ if }` directives before returning the result.
</details>

---

**Question 2**: What does `fileset("${path.module}/configs", "*.yaml")` return?
- A) The contents of all YAML files
- B) A set of file paths matching `*.yaml` in the configs directory
- C) A list of directory names
- D) The number of YAML files found

<details>
<summary>Answer</summary>
**B) A set of file paths matching `*.yaml` in the configs directory** — `fileset()` returns a set of relative file paths (not contents). You then use `file()` or `templatefile()` to read each file's contents.
</details>

---

## 📚 Key Takeaways

| Function | Purpose | Example |
|----------|---------|---------|
| `file()` | Read file contents as string | `file("${path.module}/key.pub")` |
| `templatefile()` | Render template with variables | `templatefile("tmpl.tftpl", vars)` |
| `fileset()` | Discover files by glob pattern | `fileset(path, "*.yaml")` |
| `filebase64()` | Read file as Base64 string | `filebase64("cert.crt")` |
| `path.module` | Directory of current .tf file | Use with all file functions |
| `.tftpl` extension | Convention for template files | `cloud-init.yaml.tftpl` |
| `%{ for item in list }` | Loop in template | Generates repeated blocks |
| `~` trim marker | Remove whitespace in templates | `%{ for x in list ~}` |

---

## 🔗 Next Steps

- **Next**: [Section 4: Encoding Functions](../4-encoding-functions/README.md)
- **Previous**: [Section 2: Collection Functions](../2-collection-functions/README.md)
- **Back to**: [TF-306 Course Overview](../README.md)
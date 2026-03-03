# TF-201 Supplement: `moved` Blocks — Code-Driven Refactoring

**Course**: TF-201 Module Design & Composition  
**Section**: Supplement  
**Duration**: 20 minutes  
**Prerequisites**: TF-201 core content, TF-104 (State Management)  
**Terraform Version**: 1.1+

---

## 📋 Overview

When you rename a resource, move it into a module, or reorganize your code, Terraform normally wants to **destroy the old resource and create a new one** — because it sees a different address in state. `moved` blocks solve this by telling Terraform: "the resource at address A is now at address B — don't recreate it."

`moved` blocks are the modern, code-driven, version-controlled alternative to `terraform state mv`.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Explain why `moved` blocks exist and what problem they solve
- ✅ Use `moved` blocks to rename resources without destroying them
- ✅ Use `moved` blocks to move resources into modules
- ✅ Use `moved` blocks to rename module calls
- ✅ Understand when to remove `moved` blocks
- ✅ Compare `moved` blocks vs `terraform state mv`

---

## 🔑 The Problem: Renaming Causes Destruction

Without `moved` blocks, renaming a resource causes Terraform to destroy and recreate it:

```hcl
# Before: resource named "web_server"
resource "local_file" "web_server" {
  content  = "web server config"
  filename = "${path.module}/web.conf"
}

# After: renamed to "web" — Terraform will DESTROY web_server and CREATE web!
resource "local_file" "web" {
  content  = "web server config"
  filename = "${path.module}/web.conf"
}
```

```
# terraform plan output (without moved block):
  # local_file.web_server will be destroyed
  - resource "local_file" "web_server" { ... }

  # local_file.web will be created
  + resource "local_file" "web" { ... }
```

For a local file this is harmless, but for a production VM, database, or load balancer — **this is catastrophic**.

---

## ✨ The Solution: `moved` Blocks

```hcl
# Tell Terraform: "web_server" is now called "web"
moved {
  from = local_file.web_server
  to   = local_file.web
}

# The renamed resource
resource "local_file" "web" {
  content  = "web server config"
  filename = "${path.module}/web.conf"
}
```

```
# terraform plan output (with moved block):
  # local_file.web_server has moved to local_file.web
    resource "local_file" "web" { ... }  # No changes!
```

---

## 📚 Use Cases

### 1. Renaming a Resource

```hcl
# Old name (remove this resource block)
# resource "local_file" "web_server" { ... }

# New name
resource "local_file" "web" {
  content  = "web server config"
  filename = "${path.module}/web.conf"
}

# moved block: tells Terraform about the rename
moved {
  from = local_file.web_server
  to   = local_file.web
}
```

### 2. Moving a Resource into a Module

When you extract a resource into a reusable module:

```hcl
# Before: resource in root module
# resource "local_file" "config" { ... }

# After: resource is now inside a module
module "app_config" {
  source = "./modules/app-config"
  # ...
}

# moved block: tells Terraform the resource moved into the module
moved {
  from = local_file.config
  to   = module.app_config.local_file.config
}
```

### 3. Renaming a Module Call

When you rename a `module` block:

```hcl
# Old module call (remove this)
# module "old_network" { ... }

# New module call
module "network" {
  source = "./modules/network"
  # ...
}

# moved block: tells Terraform the module was renamed
moved {
  from = module.old_network
  to   = module.network
}
```

### 4. Moving a `for_each` Resource

When a resource uses `for_each`, you reference instances with their key:

```hcl
# Before: single resource
# resource "local_file" "config" { ... }

# After: for_each resource
resource "local_file" "configs" {
  for_each = toset(["web", "api", "db"])
  content  = "${each.key} config"
  filename = "${path.module}/${each.key}.conf"
}

# Move the old single resource to the "web" instance of the new for_each
moved {
  from = local_file.config
  to   = local_file.configs["web"]
}
```

### 5. Moving Between `for_each` Keys

When you rename a key in a `for_each` map:

```hcl
# Before: key was "webserver"
# for_each = {"webserver" = {...}}

# After: key is now "web"
# for_each = {"web" = {...}}

moved {
  from = local_file.configs["webserver"]
  to   = local_file.configs["web"]
}
```

---

## ⚖️ `moved` Blocks vs `terraform state mv`

| Aspect | `moved` blocks | `terraform state mv` |
|--------|---------------|---------------------|
| **Where** | In `.tf` files | CLI command |
| **Version controlled** | ✅ Yes — in Git | ❌ No — manual command |
| **Reviewable** | ✅ Yes — in PRs | ❌ No |
| **Auditable** | ✅ Yes — Git history | ❌ No |
| **Team-friendly** | ✅ Yes — everyone applies | ❌ No — one person runs it |
| **Terraform version** | 1.1+ | Any |
| **Reversible** | ✅ Remove the block | ❌ Run another state mv |
| **Recommended** | ✅ Modern approach | ⚠️ Legacy/emergency use |

**Rule of thumb**: Use `moved` blocks for planned refactoring. Use `terraform state mv` only for emergency fixes or when working with Terraform < 1.1.

---

## ⏰ When to Remove `moved` Blocks

`moved` blocks are **not permanent**. Once everyone on your team has applied the change, you can remove them.

### Safe Removal Timeline

```
Week 1: Add moved block + rename resource
         → Everyone runs terraform apply
         → State is updated everywhere

Week 2+: Remove the moved block
          → It's now safe — state already reflects the new name
          → Keeping it is harmless but adds clutter
```

### What Happens if You Remove Too Early?

If someone hasn't applied yet and you remove the `moved` block:
- Terraform will try to destroy the old resource and create a new one
- This is why you should wait until all environments (dev, staging, prod) have been applied

### Keeping `moved` Blocks for Published Modules

If you're publishing a module to a registry, **keep `moved` blocks longer** — users may be on older versions of your module and need the migration path.

---

## 🧪 Hands-On Lab

### Lab: Refactor Without Destruction

```bash
mkdir tf201-moved-blocks
cd tf201-moved-blocks
```

**Step 1**: Create initial configuration (`main.tf`):

```hcl
terraform {
  required_version = ">= 1.1.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Original resource names (we'll rename these)
resource "local_file" "web_server_config" {
  content  = "server = web\nport = 80"
  filename = "${path.module}/web.conf"
}

resource "local_file" "api_server_config" {
  content  = "server = api\nport = 8080"
  filename = "${path.module}/api.conf"
}
```

**Step 2**: Apply to create initial state:

```bash
terraform init
terraform apply -auto-approve
terraform state list
# Output:
# local_file.api_server_config
# local_file.web_server_config
```

**Step 3**: Rename resources WITH `moved` blocks (`main.tf`):

```hcl
terraform {
  required_version = ">= 1.1.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Renamed resources
resource "local_file" "web" {
  content  = "server = web\nport = 80"
  filename = "${path.module}/web.conf"
}

resource "local_file" "api" {
  content  = "server = api\nport = 8080"
  filename = "${path.module}/api.conf"
}

# moved blocks — tell Terraform about the renames
moved {
  from = local_file.web_server_config
  to   = local_file.web
}

moved {
  from = local_file.api_server_config
  to   = local_file.api
}
```

**Step 4**: Plan — verify no destroy/create:

```bash
terraform plan
# Expected output:
# local_file.web_server_config has moved to local_file.web
# local_file.api_server_config has moved to local_file.api
# No changes. Your infrastructure matches the configuration.
```

**Step 5**: Apply and verify state:

```bash
terraform apply -auto-approve
terraform state list
# Output:
# local_file.api
# local_file.web
```

**Step 6**: Clean up:

```bash
terraform destroy -auto-approve
```

---

## ✅ Checkpoint Quiz

**Question 1**: What does a `moved` block do?
- A) Moves a file on the filesystem
- B) Tells Terraform that a resource address has changed without destroying/recreating it
- C) Moves state to a remote backend
- D) Renames a Terraform provider

<details>
<summary>Answer</summary>
**B) Tells Terraform that a resource address has changed without destroying/recreating it** — `moved` blocks update the state mapping so Terraform knows the resource at the old address is the same as the resource at the new address.
</details>

---

**Question 2**: What is the minimum Terraform version required for `moved` blocks?
- A) 1.0.0
- B) 1.1.0
- C) 1.5.0
- D) 1.7.0

<details>
<summary>Answer</summary>
**B) 1.1.0** — `moved` blocks were introduced in Terraform 1.1.
</details>

---

**Question 3**: When should you remove `moved` blocks?
- A) Immediately after adding them
- B) Never — keep them permanently
- C) After all environments have applied the change
- D) Only when Terraform gives an error

<details>
<summary>Answer</summary>
**C) After all environments have applied the change** — Once all state files (dev, staging, prod) have been updated with the new resource address, the `moved` block is no longer needed and can be removed.
</details>

---

## 📚 Key Takeaways

| Concept | Key Point |
|---------|-----------|
| Purpose | Rename/move resources without destroy+create |
| Version | Terraform 1.1+ |
| Location | In `.tf` files (version controlled) |
| vs `state mv` | `moved` blocks are reviewable, auditable, team-friendly |
| Removal | Safe to remove after all environments applied |
| Module moves | Use full module path: `module.name.resource_type.name` |
| `for_each` | Reference instances with key: `resource["key"]` |

---

## 🔗 Next Steps

- **Related**: [TF-204: Import & Migration Strategies](../TF-204-import-migration/README.md) — `removed` blocks and import workflows
- **Related**: [TF-104 Section 2: State Management](../../TF-100-fundamentals/TF-104-state-cli/2-state/README.md) — understanding state

---

## 📖 Additional Resources

- [moved blocks — Terraform Documentation](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring)
- [Refactoring — Terraform Documentation](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring)
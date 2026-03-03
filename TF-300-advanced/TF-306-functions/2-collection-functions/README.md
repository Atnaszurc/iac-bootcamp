# TF-306 Section 2: Collection Functions

**Course**: TF-306 Terraform Functions Deep Dive  
**Section**: 2 of 4  
**Duration**: 20 minutes  
**Prerequisites**: TF-102 (Variables, Loops & Functions)  
**Terraform Version**: 1.14+

---

## 📋 Overview

Collection functions operate on lists, sets, and maps. They are essential for transforming data structures, combining configurations, and generating complex resource configurations from simple inputs.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Use `flatten()` to collapse nested lists
- ✅ Use `merge()` to combine maps
- ✅ Use `setproduct()` to generate all combinations
- ✅ Use `zipmap()` to create maps from two lists
- ✅ Use `distinct()`, `compact()`, and `concat()` for list manipulation
- ✅ Use `keys()`, `values()`, `lookup()` for map operations
- ✅ Apply collection functions in real-world resource generation

---

## 📚 `flatten()`

Collapses a list of lists into a single flat list:

```hcl
locals {
  # Nested list — common when using for expressions with modules
  nested = [
    ["web-01", "web-02"],
    ["api-01"],
    ["db-01", "db-02", "db-03"]
  ]

  flat = flatten(local.nested)
  # → ["web-01", "web-02", "api-01", "db-01", "db-02", "db-03"]
}
```

### Real-World Use: Flatten Module Outputs

```hcl
# Each module returns a list of security group IDs
locals {
  all_sg_ids = flatten([
    module.web_tier.security_group_ids,
    module.app_tier.security_group_ids,
    module.db_tier.security_group_ids,
  ])
}

# Use all IDs in a single resource
resource "some_resource" "firewall_rule" {
  for_each = toset(local.all_sg_ids)
  group_id = each.value
}
```

### Flatten with for expressions

```hcl
variable "environments" {
  default = ["dev", "staging", "prod"]
}

variable "services" {
  default = ["web", "api", "db"]
}

locals {
  # Generate all env-service combinations as a flat list
  all_combinations = flatten([
    for env in var.environments : [
      for svc in var.services : "${env}-${svc}"
    ]
  ])
  # → ["dev-web", "dev-api", "dev-db", "staging-web", ...]
}
```

---

## 📚 `merge()`

Combines multiple maps into one. Later maps override earlier ones for duplicate keys:

```hcl
locals {
  default_tags = {
    managed_by  = "terraform"
    environment = "unknown"
  }

  env_tags = {
    environment = "production"  # Overrides default
    cost_center = "engineering"
  }

  resource_tags = {
    component = "web-server"
  }

  # Merge all — later maps win on conflicts
  all_tags = merge(local.default_tags, local.env_tags, local.resource_tags)
  # → {
  #     managed_by  = "terraform"
  #     environment = "production"   ← overridden by env_tags
  #     cost_center = "engineering"
  #     component   = "web-server"
  #   }
}
```

### Real-World Use: Tag Inheritance

```hcl
variable "global_tags" {
  default = {
    managed_by = "terraform"
    team       = "platform"
  }
}

variable "resource_specific_tags" {
  default = {
    component = "load-balancer"
    tier      = "frontend"
  }
}

locals {
  # Resource-specific tags override global tags
  final_tags = merge(var.global_tags, var.resource_specific_tags)
}
```

---

## 📚 `setproduct()`

Returns the Cartesian product (all combinations) of multiple sets:

```hcl
locals {
  environments = ["dev", "prod"]
  regions      = ["eastus", "westeurope"]

  # All environment × region combinations
  combos = setproduct(local.environments, local.regions)
  # → [
  #     ["dev", "eastus"],
  #     ["dev", "westeurope"],
  #     ["prod", "eastus"],
  #     ["prod", "westeurope"],
  #   ]

  # Convert to map for use with for_each
  deployment_map = {
    for combo in local.combos :
    "${combo[0]}-${combo[1]}" => {
      environment = combo[0]
      region      = combo[1]
    }
  }
  # → {
  #     "dev-eastus"      = { environment = "dev",  region = "eastus" }
  #     "dev-westeurope"  = { environment = "dev",  region = "westeurope" }
  #     "prod-eastus"     = { environment = "prod", region = "eastus" }
  #     "prod-westeurope" = { environment = "prod", region = "westeurope" }
  #   }
}

# Deploy to all environment × region combinations
resource "local_file" "deployment" {
  for_each = local.deployment_map
  filename = "${path.module}/${each.key}.conf"
  content  = "env=${each.value.environment}\nregion=${each.value.region}"
}
```

---

## 📚 `zipmap()`

Creates a map from two lists — one for keys, one for values:

```hcl
locals {
  server_names = ["web-01", "api-01", "db-01"]
  ip_addresses = ["10.0.0.10", "10.0.0.20", "10.0.0.30"]

  # Zip into a map
  server_ips = zipmap(local.server_names, local.ip_addresses)
  # → {
  #     "web-01" = "10.0.0.10"
  #     "api-01" = "10.0.0.20"
  #     "db-01"  = "10.0.0.30"
  #   }
}
```

### Real-World Use: Map Resource Outputs

```hcl
locals {
  # After creating VMs, zip names with their IDs
  vm_names = [for vm in libvirt_domain.servers : vm.name]
  vm_ids   = [for vm in libvirt_domain.servers : vm.id]
  vm_map   = zipmap(local.vm_names, local.vm_ids)
}
```

---

## 📚 List Manipulation: `distinct()`, `compact()`, `concat()`

### `distinct()` — Remove duplicates

```hcl
locals {
  tags_with_dupes = ["web", "frontend", "web", "nginx", "frontend"]
  unique_tags     = distinct(local.tags_with_dupes)
  # → ["web", "frontend", "nginx"]
}
```

### `compact()` — Remove empty strings

```hcl
locals {
  raw_list    = ["web", "", "api", "", "db"]
  clean_list  = compact(local.raw_list)
  # → ["web", "api", "db"]
}
```

### `concat()` — Combine lists

```hcl
locals {
  base_packages  = ["curl", "wget"]
  extra_packages = ["nginx", "git"]
  all_packages   = concat(local.base_packages, local.extra_packages)
  # → ["curl", "wget", "nginx", "git"]
}
```

---

## 📚 Map Operations: `keys()`, `values()`, `lookup()`

```hcl
variable "vm_sizes" {
  default = {
    small  = "1cpu-1gb"
    medium = "2cpu-4gb"
    large  = "4cpu-8gb"
  }
}

locals {
  size_names   = keys(var.vm_sizes)    # → ["large", "medium", "small"] (sorted)
  size_values  = values(var.vm_sizes)  # → ["4cpu-8gb", "2cpu-4gb", "1cpu-1gb"]

  # lookup with default (safe — won't error if key missing)
  selected_size = lookup(var.vm_sizes, "xlarge", "2cpu-4gb")
  # → "2cpu-4gb" (default, since "xlarge" doesn't exist)
}
```

---

## 🧪 Hands-On Lab

Try these in `terraform console`:

```hcl
# 1. Flatten nested lists
> flatten([["a", "b"], ["c"], ["d", "e"]])
tolist(["a", "b", "c", "d", "e"])

# 2. Merge maps
> merge({a = 1, b = 2}, {b = 3, c = 4})
{"a" = 1, "b" = 3, "c" = 4}

# 3. Setproduct
> setproduct(["dev", "prod"], ["us", "eu"])
[["dev", "us"], ["dev", "eu"], ["prod", "us"], ["prod", "eu"]]

# 4. Zipmap
> zipmap(["a", "b", "c"], [1, 2, 3])
{"a" = 1, "b" = 2, "c" = 3}

# 5. Distinct
> distinct(["a", "b", "a", "c", "b"])
tolist(["a", "b", "c"])

# 6. Compact
> compact(["a", "", "b", "", "c"])
tolist(["a", "b", "c"])

# 7. Keys and values
> keys({z = 3, a = 1, m = 2})
tolist(["a", "m", "z"])
```

---

## ✅ Checkpoint Quiz

**Question 1**: What does `flatten([[1, 2], [3], [4, 5]])` return?
- A) `[[1, 2], [3], [4, 5]]`
- B) `[1, 2, 3, 4, 5]`
- C) `[1, 2, 3, 4, 5, null]`
- D) An error

<details>
<summary>Answer</summary>
**B) `[1, 2, 3, 4, 5]`** — `flatten()` collapses one level of nesting, producing a single flat list.
</details>

---

**Question 2**: When merging two maps with `merge(map1, map2)` and both have the same key, which value wins?
- A) `map1`'s value
- B) `map2`'s value
- C) An error is thrown
- D) Both values are kept in a list

<details>
<summary>Answer</summary>
**B) `map2`'s value** — Later arguments to `merge()` override earlier ones for duplicate keys. This is intentional — it allows you to layer defaults with overrides.
</details>

---

## 📚 Key Takeaways

| Function | Purpose | Example |
|----------|---------|---------|
| `flatten()` | Collapse nested lists | `flatten([[1,2],[3]])` → `[1,2,3]` |
| `merge()` | Combine maps (later wins) | `merge(defaults, overrides)` |
| `setproduct()` | Cartesian product of sets | `setproduct(envs, regions)` |
| `zipmap()` | Two lists → one map | `zipmap(keys, values)` |
| `distinct()` | Remove duplicates from list | `distinct(["a","a","b"])` |
| `compact()` | Remove empty strings | `compact(["a","","b"])` |
| `concat()` | Combine multiple lists | `concat(list1, list2)` |
| `keys()` | Map → sorted list of keys | `keys({b=2, a=1})` → `["a","b"]` |
| `values()` | Map → list of values | `values({a=1, b=2})` |
| `lookup()` | Safe map access with default | `lookup(map, "key", "default")` |

---

## 🔗 Next Steps

- **Next**: [Section 3: Filesystem Functions](../3-filesystem-functions/README.md)
- **Previous**: [Section 1: String Functions](../1-string-functions/README.md)
- **Back to**: [TF-306 Course Overview](../README.md)
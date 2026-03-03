# TF-102 Section 5: `for` Expressions

**Course**: TF-102 Variables, Loops & Functions  
**Section**: 5 of 5  
**Duration**: 25 minutes  
**Prerequisites**: Sections 1-4 of TF-102 (especially Section 2: Loops)

---

## 📋 Overview

`for` expressions are one of Terraform's most powerful features for transforming data. Unlike `for_each` (which creates multiple resources), a `for` expression **transforms a collection into a new collection** — similar to list comprehensions in Python or `map()`/`filter()` in JavaScript.

You'll use `for` expressions constantly in real-world Terraform code — in `locals`, `outputs`, and variable defaults.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Distinguish between `for` expressions and `for_each` meta-argument
- ✅ Write `for` expressions that produce lists
- ✅ Write `for` expressions that produce maps
- ✅ Filter collections using the `if` clause
- ✅ Use `for` expressions in `locals`, `outputs`, and variables
- ✅ Apply `for` expressions to real-world data transformation problems

---

## 🔑 Key Concept: `for` vs `for_each`

These are **completely different** features that are often confused:

| Feature | `for_each` | `for` expression |
|---------|-----------|-----------------|
| **Purpose** | Create multiple resources | Transform a collection |
| **Used in** | Resource/module blocks | Anywhere an expression is valid |
| **Output** | Multiple resource instances | A new list or map |
| **Example** | `for_each = var.servers` | `[for s in var.servers : upper(s)]` |

```hcl
# for_each — creates multiple resources
resource "local_file" "configs" {
  for_each = var.environments          # Creates one file per environment
  content  = "env = ${each.key}"
  filename = "${each.key}.conf"
}

# for expression — transforms data
locals {
  upper_envs = [for env in var.environments : upper(env)]  # Returns a list
}
```

---

## 📝 Syntax

### List Output

```hcl
[for <item> in <collection> : <expression>]
```

### Map Output

```hcl
{for <key>, <value> in <collection> : <new_key> => <new_value>}
```

### With Filter

```hcl
[for <item> in <collection> : <expression> if <condition>]
{for <key>, <value> in <collection> : <new_key> => <new_value> if <condition>}
```

---

## 📚 Examples

### 1. Iterating Over a List → New List

```hcl
variable "server_names" {
  type    = list(string)
  default = ["web", "api", "db"]
}

locals {
  # Transform each name to uppercase
  upper_names = [for name in var.server_names : upper(name)]
  # Result: ["WEB", "API", "DB"]

  # Add a prefix to each name
  prefixed_names = [for name in var.server_names : "prod-${name}"]
  # Result: ["prod-web", "prod-api", "prod-db"]

  # Get the length of each name
  name_lengths = [for name in var.server_names : length(name)]
  # Result: [3, 3, 2]
}
```

### 2. Iterating Over a List → Map

```hcl
variable "server_names" {
  type    = list(string)
  default = ["web", "api", "db"]
}

locals {
  # Create a map of name => length
  name_to_length = {for name in var.server_names : name => length(name)}
  # Result: {"web" = 3, "api" = 3, "db" = 2}

  # Create a map of name => uppercase name
  name_to_upper = {for name in var.server_names : name => upper(name)}
  # Result: {"web" = "WEB", "api" = "API", "db" = "DB"}
}
```

### 3. Iterating Over a Map

```hcl
variable "server_ports" {
  type = map(number)
  default = {
    web = 80
    api = 8080
    db  = 5432
  }
}

locals {
  # Swap keys and values
  port_to_service = {for service, port in var.server_ports : port => service}
  # Result: {80 = "web", 8080 = "api", 5432 = "db"}

  # Add 1000 to each port
  high_ports = {for service, port in var.server_ports : service => port + 1000}
  # Result: {"web" = 1080, "api" = 9080, "db" = 6432}

  # Create formatted strings
  port_strings = [for service, port in var.server_ports : "${service}:${port}"]
  # Result: ["web:80", "api:8080", "db:5432"]
}
```

### 4. Filtering with `if`

```hcl
variable "servers" {
  type = list(object({
    name    = string
    enabled = bool
    env     = string
  }))
  default = [
    { name = "web-1",  enabled = true,  env = "prod" },
    { name = "web-2",  enabled = false, env = "prod" },
    { name = "api-1",  enabled = true,  env = "prod" },
    { name = "test-1", enabled = true,  env = "dev"  },
  ]
}

locals {
  # Only enabled servers
  enabled_servers = [for s in var.servers : s.name if s.enabled]
  # Result: ["web-1", "api-1", "test-1"]

  # Only prod servers that are enabled
  prod_servers = [for s in var.servers : s.name if s.enabled && s.env == "prod"]
  # Result: ["web-1", "api-1"]

  # Map of enabled servers: name => env
  enabled_map = {for s in var.servers : s.name => s.env if s.enabled}
  # Result: {"web-1" = "prod", "api-1" = "prod", "test-1" = "dev"}
}
```

### 5. Real-World: Building Tag Maps

```hcl
variable "base_tags" {
  type = map(string)
  default = {
    project     = "hashi-training"
    owner       = "platform-team"
    cost_center = "engineering"
  }
}

variable "environment" {
  type    = string
  default = "prod"
}

locals {
  # Add environment prefix to all tag keys
  prefixed_tags = {
    for key, value in var.base_tags : "${var.environment}_${key}" => value
  }
  # Result: {"prod_project" = "hashi-training", "prod_owner" = "platform-team", ...}

  # Convert all tag values to uppercase
  upper_tags = {for k, v in var.base_tags : k => upper(v)}
  # Result: {"project" = "HASHI-TRAINING", "owner" = "PLATFORM-TEAM", ...}

  # Merge base tags with environment tag
  all_tags = merge(var.base_tags, {environment = var.environment})
  # Result: {"project" = "hashi-training", ..., "environment" = "prod"}
}
```

### 6. Real-World: Flattening Nested Data

```hcl
variable "environments" {
  type = map(list(string))
  default = {
    prod    = ["web-1", "web-2", "api-1"]
    staging = ["web-1", "api-1"]
    dev     = ["web-1"]
  }
}

locals {
  # Create a flat list of all server names with their environment
  all_servers = flatten([
    for env, servers in var.environments : [
      for server in servers : {
        name        = server
        environment = env
        full_name   = "${env}-${server}"
      }
    ]
  ])
  # Result: [
  #   {name="web-1", environment="prod",    full_name="prod-web-1"},
  #   {name="web-2", environment="prod",    full_name="prod-web-2"},
  #   ...
  # ]

  # Create a map keyed by full_name for use with for_each
  servers_map = {
    for server in local.all_servers : server.full_name => server
  }
}
```

### 7. Using `for` in Outputs

```hcl
resource "local_file" "configs" {
  for_each = toset(["dev", "staging", "prod"])
  content  = "environment = ${each.key}"
  filename = "${path.module}/${each.key}.conf"
}

# Output just the filenames as a list
output "config_files" {
  value = [for f in local_file.configs : f.filename]
}

# Output a map of environment => filename
output "config_map" {
  value = {for env, f in local_file.configs : env => f.filename}
}
```

---

## 🔬 Using `terraform console` to Test `for` Expressions

The `terraform console` command is perfect for testing `for` expressions interactively before using them in your code:

```bash
terraform console
```

```hcl
# Test in console:
> [for i in range(5) : "server-${i}"]
[
  "server-0",
  "server-1",
  "server-2",
  "server-3",
  "server-4",
]

> {for k, v in {"a" = 1, "b" = 2} : v => k}
{
  "1" = "a"
  "2" = "b"
}

> [for x in [1, 2, 3, 4, 5] : x * 2 if x > 2]
[
  6,
  8,
  10,
]
```

> 💡 **Tip**: Always test complex `for` expressions in `terraform console` before adding them to your configuration. See [TF-104 Section 5](../../TF-104-state-cli/5-terraform-console/README.md) for a full guide on using the console.

---

## ⚠️ Common Pitfalls

### Pitfall 1: Duplicate Keys in Map Output

```hcl
# ❌ This will error if two items produce the same key
locals {
  bad_map = {for s in var.servers : s.env => s.name}
  # Error if multiple servers have the same env!
}

# ✅ Use groupingby or ensure unique keys
locals {
  # Use the full name as key (guaranteed unique)
  good_map = {for s in var.servers : s.name => s.env}
}
```

### Pitfall 2: Confusing `for` with `for_each`

```hcl
# ❌ Wrong: trying to use for expression as for_each value directly
resource "local_file" "bad" {
  for_each = [for env in var.envs : env]  # Error! for_each needs a map or set
  ...
}

# ✅ Correct: convert list to set for for_each
resource "local_file" "good" {
  for_each = toset([for env in var.envs : env])
  ...
}

# ✅ Or even simpler:
resource "local_file" "better" {
  for_each = toset(var.envs)
  ...
}
```

### Pitfall 3: Nested `for` Expressions Without `flatten`

```hcl
# ❌ This produces a list of lists, not a flat list
locals {
  nested = [for env in var.envs : [for s in var.servers : "${env}-${s}"]]
  # Result: [["dev-web", "dev-api"], ["prod-web", "prod-api"]]
}

# ✅ Use flatten() to get a flat list
locals {
  flat = flatten([for env in var.envs : [for s in var.servers : "${env}-${s}"]])
  # Result: ["dev-web", "dev-api", "prod-web", "prod-api"]
}
```

---

## 🧪 Hands-On Lab

### Lab: Data Transformation with `for` Expressions

```bash
mkdir tf102-for-expressions
cd tf102-for-expressions
```

Create `main.tf`:

```hcl
terraform {
  required_version = ">= 1.14"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "servers" {
  type = list(object({
    name    = string
    role    = string
    enabled = bool
  }))
  default = [
    { name = "web-01",  role = "frontend", enabled = true  },
    { name = "web-02",  role = "frontend", enabled = false },
    { name = "api-01",  role = "backend",  enabled = true  },
    { name = "db-01",   role = "database", enabled = true  },
    { name = "cache-01",role = "cache",    enabled = false },
  ]
}

locals {
  # 1. All server names
  all_names = [for s in var.servers : s.name]

  # 2. Only enabled servers
  enabled_names = [for s in var.servers : s.name if s.enabled]

  # 3. Map of name => role (all servers)
  name_to_role = {for s in var.servers : s.name => s.role}

  # 4. Map of name => role (enabled only)
  enabled_map = {for s in var.servers : s.name => s.role if s.enabled}

  # 5. Uppercase all names
  upper_names = [for s in var.servers : upper(s.name)]

  # 6. Group by role (using for_each later)
  by_role = {
    for s in var.servers : s.name => s
    if s.enabled
  }
}

# Create a summary file using for expressions in templatefile
resource "local_file" "summary" {
  content  = <<-EOT
    Server Summary
    ==============
    Total servers: ${length(var.servers)}
    Enabled servers: ${length(local.enabled_names)}
    
    Enabled servers:
    ${join("\n", [for name in local.enabled_names : "  - ${name}"])}
    
    Role assignments:
    ${join("\n", [for name, role in local.enabled_map : "  ${name}: ${role}"])}
  EOT
  filename = "${path.module}/server-summary.txt"
}
```

Create `outputs.tf`:

```hcl
output "all_names" {
  description = "All server names"
  value       = local.all_names
}

output "enabled_names" {
  description = "Only enabled server names"
  value       = local.enabled_names
}

output "name_to_role" {
  description = "Map of server name to role"
  value       = local.name_to_role
}

output "enabled_map" {
  description = "Map of enabled server name to role"
  value       = local.enabled_map
}
```

Run the lab:

```bash
terraform init
terraform apply -auto-approve
terraform output
cat server-summary.txt
terraform destroy -auto-approve
```

---

## ✅ Checkpoint Quiz

**Question 1**: What does a `for` expression with `[...]` syntax produce?
- A) A map
- B) A list
- C) Multiple resources
- D) A set

<details>
<summary>Answer</summary>
**B) A list** — Square brackets `[for ... : ...]` produce a list (tuple). Curly braces `{for ... : ... => ...}` produce a map (object).
</details>

---

**Question 2**: How do you filter items in a `for` expression?
- A) Using `where` clause
- B) Using `filter` function
- C) Using `if` clause
- D) Using `when` clause

<details>
<summary>Answer</summary>
**C) Using `if` clause** — Example: `[for s in var.servers : s.name if s.enabled]`
</details>

---

**Question 3**: What is the difference between `for_each` and a `for` expression?
- A) They are the same thing
- B) `for_each` creates multiple resources; `for` transforms data
- C) `for` creates multiple resources; `for_each` transforms data
- D) `for_each` only works with maps

<details>
<summary>Answer</summary>
**B) `for_each` creates multiple resources; `for` transforms data** — `for_each` is a meta-argument on resource/module blocks that creates multiple instances. A `for` expression is used anywhere an expression is valid to transform a collection into a new collection.
</details>

---

**Question 4**: What function do you need when using nested `for` expressions to get a flat list?
- A) `concat()`
- B) `merge()`
- C) `flatten()`
- D) `tolist()`

<details>
<summary>Answer</summary>
**C) `flatten()`** — Nested `for` expressions produce lists of lists. `flatten()` collapses them into a single flat list.
</details>

---

## 📚 Key Takeaways

| Concept | Syntax | Output |
|---------|--------|--------|
| List from list | `[for item in list : expr]` | List |
| Map from list | `{for item in list : key => value}` | Map |
| List from map | `[for k, v in map : expr]` | List |
| Map from map | `{for k, v in map : new_k => new_v}` | Map |
| With filter | `[for item in list : expr if condition]` | Filtered list/map |
| Nested (flat) | `flatten([for x in a : [for y in b : ...]])` | Flat list |

---

## 🔗 Next Steps

- **Next Section**: This is the final section of TF-102
- **Next Course**: [TF-103: Infrastructure Resources](../../TF-103-infrastructure/README.md)
- **Related**: [TF-104 Section 5: terraform console](../../TF-104-state-cli/5-terraform-console/README.md) — test `for` expressions interactively

---

## 📖 Additional Resources

- [For Expressions — Terraform Documentation](https://developer.hashicorp.com/terraform/language/expressions/for)
- [flatten() function](https://developer.hashicorp.com/terraform/language/functions/flatten)
- [Type Constraints](https://developer.hashicorp.com/terraform/language/expressions/type-constraints)
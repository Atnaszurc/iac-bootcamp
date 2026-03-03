# TF-306 Section 1: String Functions

**Course**: TF-306 Terraform Functions Deep Dive  
**Section**: 1 of 4  
**Duration**: 20 minutes  
**Prerequisites**: TF-102 (Variables, Loops & Functions)  
**Terraform Version**: 1.14+

---

## 📋 Overview

String functions are the most commonly used functions in Terraform. They let you transform, format, validate, and manipulate string values — essential for generating resource names, constructing URLs, parsing configuration, and creating readable outputs.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Use `format()` and `formatlist()` for string templating
- ✅ Apply `regex()` and `regexall()` for pattern matching
- ✅ Use `replace()` and `substr()` for string manipulation
- ✅ Split and join strings with `split()` and `join()`
- ✅ Apply `trim()`, `trimprefix()`, `trimsuffix()` for cleanup
- ✅ Use `upper()`, `lower()`, `title()` for case conversion
- ✅ Combine functions for real-world naming patterns

---

## 📚 `format()` and `formatlist()`

### `format(spec, values...)`

Works like `printf` — inserts values into a format string:

```hcl
locals {
  # Basic formatting
  vm_name    = format("vm-%s-%03d", var.environment, var.index)
  # → "vm-prod-001"

  # Padding and alignment
  padded_id  = format("%05d", 42)
  # → "00042"

  # Multiple values
  dns_name   = format("%s.%s.example.com", var.service, var.environment)
  # → "api.prod.example.com"
}
```

### `formatlist(spec, list)`

Applies `format()` to each element of a list:

```hcl
locals {
  servers = ["web", "api", "db"]

  # Generate hostnames for each server
  hostnames = formatlist("%s.prod.example.com", local.servers)
  # → ["web.prod.example.com", "api.prod.example.com", "db.prod.example.com"]

  # Generate numbered names
  vm_names = formatlist("vm-%s-%02d", local.servers, [1, 2, 3])
  # → ["vm-web-01", "vm-api-02", "vm-db-03"]
}
```

---

## 📚 `regex()` and `regexall()`

### `regex(pattern, string)`

Returns the first match of a regex pattern. Errors if no match:

```hcl
locals {
  version_string = "terraform-1.9.5-linux-amd64"

  # Extract version number
  version = regex("[0-9]+\\.[0-9]+\\.[0-9]+", local.version_string)
  # → "1.9.5"

  # Extract with capture groups — returns a list
  parts = regex("([a-z]+)-([0-9.]+)-([a-z]+)", local.version_string)
  # → ["terraform", "1.9.5", "linux"]
}
```

### `regexall(pattern, string)`

Returns ALL matches as a list (never errors — returns empty list if no match):

```hcl
locals {
  config_text = "server1=10.0.0.1 server2=10.0.0.2 server3=10.0.0.3"

  # Find all IP addresses
  ip_addresses = regexall("[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+", local.config_text)
  # → ["10.0.0.1", "10.0.0.2", "10.0.0.3"]

  # Check if pattern exists (length > 0 means match found)
  has_ips = length(regexall("[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+", local.config_text)) > 0
  # → true
}
```

---

## 📚 `replace()`

### `replace(string, search, replacement)`

Replaces all occurrences of `search` in `string`:

```hcl
locals {
  raw_name = "My App Server (Production)"

  # Replace spaces with hyphens for DNS-safe names
  dns_safe = replace(local.raw_name, " ", "-")
  # → "My-App-Server-(Production)"

  # Remove parentheses
  clean_name = replace(replace(local.raw_name, "(", ""), ")", "")
  # → "My App Server Production"

  # Replace with regex (prefix with /)
  slug = lower(replace(local.raw_name, "/[^a-zA-Z0-9]/", "-"))
  # → "my-app-server--production-"
}
```

---

## 📚 `split()` and `join()`

### `split(separator, string)` → list

```hcl
locals {
  csv_tags = "env=prod,team=platform,cost-center=engineering"

  # Split into list
  tag_list = split(",", local.csv_tags)
  # → ["env=prod", "team=platform", "cost-center=engineering"]

  # Split a CIDR to get the prefix
  cidr       = "10.0.0.0/24"
  cidr_parts = split("/", local.cidr)
  prefix     = cidr_parts[0]  # → "10.0.0.0"
  mask       = cidr_parts[1]  # → "24"
}
```

### `join(separator, list)` → string

```hcl
locals {
  packages = ["nginx", "curl", "wget", "git"]

  # Join for shell command
  install_cmd = "apt-get install -y ${join(" ", local.packages)}"
  # → "apt-get install -y nginx curl wget git"

  # Join for comma-separated list
  package_csv = join(", ", local.packages)
  # → "nginx, curl, wget, git"

  # Join for DNS search domains
  domains      = ["prod.example.com", "internal.example.com"]
  search_path  = join(" ", local.domains)
  # → "prod.example.com internal.example.com"
}
```

---

## 📚 `trim()`, `trimprefix()`, `trimsuffix()`

```hcl
locals {
  messy_input = "  hello world  "
  prefixed    = "env-production"
  suffixed    = "server.example.com."

  # Remove leading/trailing whitespace
  clean = trim(local.messy_input, " ")
  # → "hello world"

  # Remove specific characters from both ends
  trimmed = trim("***important***", "*")
  # → "important"

  # Remove a prefix
  env_value = trimprefix(local.prefixed, "env-")
  # → "production"

  # Remove a suffix (trailing dot from DNS)
  hostname = trimsuffix(local.suffixed, ".")
  # → "server.example.com"
}
```

---

## 📚 Case Conversion

```hcl
locals {
  mixed_case = "Hello World"

  lower_case = lower(local.mixed_case)   # → "hello world"
  upper_case = upper(local.mixed_case)   # → "HELLO WORLD"
  title_case = title("hello world")      # → "Hello World"
}
```

---

## 📚 `substr()`

```hcl
locals {
  long_name = "my-very-long-resource-name-that-exceeds-limits"

  # Extract first 20 characters (offset=0, length=20)
  short_name = substr(local.long_name, 0, 20)
  # → "my-very-long-resourc"

  # Extract last 10 characters (negative offset counts from end)
  suffix = substr(local.long_name, -10, -1)
  # → "eeds-limits"
}
```

---

## 📚 Real-World Pattern: Resource Naming

Combining string functions for consistent, compliant resource names:

```hcl
variable "project"     { default = "myapp" }
variable "environment" { default = "production" }
variable "region"      { default = "westeurope" }
variable "component"   { default = "web server" }

locals {
  # Normalize: lowercase, replace spaces/special chars with hyphens
  safe_component = lower(replace(var.component, "/[^a-z0-9]/", "-"))

  # Build base name
  base_name = format("%s-%s-%s-%s",
    var.project,
    var.environment,
    var.region,
    local.safe_component
  )
  # → "myapp-production-westeurope-web-server"

  # Truncate to 63 chars (common DNS/Kubernetes limit)
  resource_name = substr(local.base_name, 0, min(63, length(local.base_name)))
}
```

---

## 🧪 Hands-On Lab

Try these in `terraform console`:

```hcl
# 1. Format a resource name
> format("vm-%s-%03d", "prod", 5)
"vm-prod-005"

# 2. Extract version from a string
> regex("[0-9]+\\.[0-9]+\\.[0-9]+", "terraform-1.9.5-linux")
"1.9.5"

# 3. Split a CIDR
> split("/", "10.0.0.0/24")
tolist(["10.0.0.0", "24"])

# 4. Join a list
> join(", ", ["nginx", "curl", "wget"])
"nginx, curl, wget"

# 5. Clean up a name
> lower(replace("My App Server", " ", "-"))
"my-app-server"

# 6. Remove a prefix
> trimprefix("env-production", "env-")
"production"
```

---

## ✅ Checkpoint Quiz

**Question 1**: What does `regexall()` return when there are no matches?
- A) An error
- B) `null`
- C) An empty list `[]`
- D) `false`

<details>
<summary>Answer</summary>
**C) An empty list `[]`** — Unlike `regex()` which errors on no match, `regexall()` always returns a list (empty if no matches). This makes it safe to use without `try()`.
</details>

---

**Question 2**: What is the result of `join("-", split(".", "a.b.c"))`?
- A) `"a.b.c"`
- B) `"a-b-c"`
- C) `["a", "b", "c"]`
- D) An error

<details>
<summary>Answer</summary>
**B) `"a-b-c"`** — `split(".", "a.b.c")` produces `["a", "b", "c"]`, then `join("-", ...)` combines them with hyphens.
</details>

---

## 📚 Key Takeaways

| Function | Purpose | Example |
|----------|---------|---------|
| `format()` | Printf-style string formatting | `format("vm-%s-%03d", env, n)` |
| `formatlist()` | Apply format to each list element | `formatlist("%s.example.com", names)` |
| `regex()` | First regex match (errors if none) | `regex("[0-9]+", "v1.2")` |
| `regexall()` | All regex matches (empty list if none) | `regexall("[0-9]+", text)` |
| `replace()` | Replace substring or regex pattern | `replace(name, " ", "-")` |
| `split()` | String → list by separator | `split(",", "a,b,c")` |
| `join()` | List → string with separator | `join(", ", list)` |
| `trim()` | Remove chars from both ends | `trim("  hello  ", " ")` |
| `trimprefix()` | Remove prefix | `trimprefix("env-prod", "env-")` |
| `trimsuffix()` | Remove suffix | `trimsuffix("name.", ".")` |
| `lower/upper/title` | Case conversion | `lower("Hello")` → `"hello"` |
| `substr()` | Extract substring | `substr(name, 0, 20)` |

---

## 🔗 Next Steps

- **Next**: [Section 2: Collection Functions](../2-collection-functions/README.md)
- **Back to**: [TF-306 Course Overview](../README.md)
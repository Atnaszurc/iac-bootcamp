# TF-306: Terraform Functions Deep Dive

**Course Level**: 300 (Advanced)  
**Duration**: 1.5 hours  
**Prerequisites**: TF-102 (Variables, Loops & Functions), TF-201 (Module Design)  
**Terraform Version**: 1.14+

---

## 📋 Course Overview

Terraform's built-in function library is one of its most powerful features — yet most practitioners only use a handful of functions. This course provides a systematic deep dive into four essential function categories, with real-world patterns and working examples for each.

You will move beyond basic `upper()` and `lower()` calls to master complex string manipulation, collection transformation, file-based configuration, and data encoding — the building blocks of production-grade Terraform code.

---

## 🎯 Learning Objectives

By the end of this course, you will be able to:

- ✅ Apply advanced string functions for naming conventions and text processing
- ✅ Transform collections with `flatten()`, `merge()`, `setproduct()`, and `zipmap()`
- ✅ Load external configuration using `file()`, `templatefile()`, and `fileset()`
- ✅ Convert data between JSON, YAML, and Base64 formats
- ✅ Combine multiple functions to solve real infrastructure problems
- ✅ Use `terraform console` to test functions interactively
- ✅ Use `templatestring()` to render templates from string values (1.9+)
- ✅ Use `element()` with negative indices to access list items from the end (1.10+)
- ✅ Use `ephemeralasnull()` to safely use ephemeral values in non-ephemeral contexts (1.10+)

---

## 📚 Course Modules

### Section 1: String Functions (20 min)
**Directory**: `1-string-functions/`

Master text manipulation for resource naming, validation, and output formatting.

| Function | Purpose |
|----------|---------|
| `format()` / `formatlist()` | Printf-style string formatting |
| `regex()` / `regexall()` | Pattern matching and extraction |
| `replace()` | String substitution |
| `split()` / `join()` | String ↔ list conversion |
| `trim()` / `trimprefix()` / `trimsuffix()` | Whitespace and prefix/suffix removal |
| `upper()` / `lower()` / `title()` | Case conversion |
| `substr()` | Substring extraction |
| `templatestring()` ⭐ **New 1.9** | Render a template from a string value (vs file path) |

**Key Pattern**: Consistent resource naming across environments using `format()` and `lower()`.

---

### Section 2: Collection Functions (20 min)
**Directory**: `2-collection-functions/`

Transform lists, maps, and sets for dynamic resource creation.

| Function | Purpose |
|----------|---------|
| `flatten()` | Collapse nested lists into a single list |
| `merge()` | Combine multiple maps |
| `setproduct()` | Cartesian product of sets |
| `zipmap()` | Create map from keys and values lists |
| `distinct()` | Remove duplicate values |
| `compact()` | Remove null/empty values |
| `concat()` | Combine multiple lists |
| `keys()` / `values()` / `lookup()` | Map operations |
| `element()` with negative indices ⭐ **New 1.10** | Access list items from the end (`element(list, -1)` = last item) |
| `ephemeralasnull()` ⭐ **New 1.10** | Convert ephemeral value to null for non-ephemeral contexts |

**Key Pattern**: Using `setproduct()` + `zipmap()` to generate all environment/region combinations for multi-region deployments.

---

### Section 3: Filesystem Functions (20 min)
**Directory**: `3-filesystem-functions/`

Load external files and render templates for cloud-init, scripts, and configuration.

| Function | Purpose |
|----------|---------|
| `file()` | Read file contents as string |
| `templatefile()` | Render `.tftpl` template with variables |
| `fileset()` | Discover files matching a glob pattern |
| `filebase64()` | Read file as Base64-encoded string |
| `path.module` | Directory of current `.tf` file |

**Key Pattern**: Using `templatefile()` with `%{ for }` loops to generate cloud-init configs dynamically per VM role.

---

### Section 4: Encoding Functions (20 min)
**Directory**: `4-encoding-functions/`

Convert data between formats for APIs, cloud-init, and cross-module data passing.

| Function | Purpose |
|----------|---------|
| `jsonencode()` | HCL → JSON string |
| `jsondecode()` | JSON string → HCL |
| `yamlencode()` | HCL → YAML string |
| `yamldecode()` | YAML string → HCL |
| `base64encode()` | String → Base64 |
| `base64decode()` | Base64 → string |
| `tostring()` / `tonumber()` / `tobool()` | Type conversion |
| `toset()` / `tolist()` / `tomap()` | Collection type conversion |

**Key Pattern**: Using `jsonencode()` with `for` expressions to generate IAM policies dynamically from a list of resource names.

---

## 🗂️ Directory Structure

```
TF-306-functions/
├── README.md                          # This file
├── 1-string-functions/
│   ├── README.md                      # String functions reference + examples
│   └── example/
│       └── main.tf                    # Working example (local provider)
├── 2-collection-functions/
│   ├── README.md                      # Collection functions reference + examples
│   └── example/
│       └── main.tf                    # Working example (local provider)
├── 3-filesystem-functions/
│   ├── README.md                      # Filesystem functions reference + examples
│   └── example/
│       └── main.tf                    # Working example (local provider)
└── 4-encoding-functions/
    ├── README.md                      # Encoding functions reference + examples
    └── example/
        └── main.tf                    # Working example (local provider)
```

---

## 🚀 Quick Start

All examples use the `hashicorp/local` provider — no cloud credentials required.

```bash
# Section 1: String Functions
cd 1-string-functions/example
terraform init
terraform apply -auto-approve
cat output/string-functions-summary.txt

# Section 2: Collection Functions
cd ../../2-collection-functions/example
terraform init
terraform apply -auto-approve
cat output/collection-functions-summary.txt

# Section 3: Filesystem Functions
cd ../../3-filesystem-functions/example
terraform init
terraform apply -auto-approve
cat output/filesystem-functions-summary.txt

# Section 4: Encoding Functions
cd ../../4-encoding-functions/example
terraform init
terraform apply -auto-approve
cat output/encoding-functions-summary.txt
```

---

## 🧪 Interactive Testing with `terraform console`

Test any function interactively before using it in code:

```bash
cd 1-string-functions/example
terraform init
terraform console
```

```hcl
# String functions
> format("%-10s | %s", "web-01", "production")
"web-01     | production"

> join(", ", ["nginx", "curl", "git"])
"nginx, curl, git"

> regex("[a-z]+", "web-server-01")
"web"

# Collection functions
> flatten([["a", "b"], ["c", "d"]])
tolist(["a", "b", "c", "d"])

> merge({a = 1}, {b = 2}, {c = 3})
{a = 1, b = 2, c = 3}

> zipmap(["a", "b", "c"], [1, 2, 3])
{a = 1, b = 2, c = 3}

# Encoding functions
> jsonencode({name = "test", count = 3})
"{\"count\":3,\"name\":\"test\"}"

> base64encode("Hello, Terraform!")
"SGVsbG8sIFRlcnJhZm9ybSE="

> yamlencode({packages = ["nginx", "curl"]})
"packages:\n- nginx\n- curl\n"
```

---

## 💡 Function Combination Patterns

### Pattern 1: Dynamic Resource Naming

```hcl
locals {
  # Consistent naming: {env}-{region}-{service}-{index}
  vm_names = [
    for i in range(var.vm_count) :
    format("%s-%s-%s-%02d",
      lower(var.environment),
      lower(var.region),
      lower(var.service_name),
      i + 1
    )
  ]
}
```

### Pattern 2: Config Directory Loader

```hcl
locals {
  # Load all YAML files from a directory into a map
  configs = {
    for filename in fileset("${path.module}/configs", "*.yaml") :
    trimsuffix(filename, ".yaml") => yamldecode(
      file("${path.module}/configs/${filename}")
    )
  }
}
```

### Pattern 3: Dynamic IAM Policy

```hcl
locals {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for bucket in var.buckets : {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::${bucket}/*"
      }
    ]
  })
}
```

### Pattern 4: Multi-Environment Deployment Matrix

```hcl
locals {
  # All combinations of environments × regions
  deployments = {
    for pair in setproduct(var.environments, var.regions) :
    "${pair[0]}-${pair[1]}" => {
      environment = pair[0]
      region      = pair[1]
    }
  }
}
```

---

## 📊 Function Quick Reference

### String Functions

| Function | Signature | Example |
|----------|-----------|---------|
| `format` | `format(spec, values...)` | `format("%s-%02d", "web", 1)` → `"web-01"` |
| `formatlist` | `formatlist(spec, list)` | `formatlist("vm-%s", ["a","b"])` |
| `regex` | `regex(pattern, string)` | `regex("[0-9]+", "vm-42")` → `"42"` |
| `replace` | `replace(str, search, replace)` | `replace("a_b", "_", "-")` → `"a-b"` |
| `split` | `split(sep, str)` | `split(",", "a,b,c")` → `["a","b","c"]` |
| `join` | `join(sep, list)` | `join("-", ["a","b"])` → `"a-b"` |
| `trim` | `trim(str, chars)` | `trim("  hello  ", " ")` → `"hello"` |
| `substr` | `substr(str, offset, len)` | `substr("hello", 0, 3)` → `"hel"` |
| `templatestring` ⭐ 1.9 | `templatestring(tmpl, vars)` | `templatestring("Hello ${name}", {name="Bob"})` → `"Hello Bob"` |

### Collection Functions

| Function | Signature | Example |
|----------|-----------|---------|
| `flatten` | `flatten(list)` | `flatten([["a"],["b"]])` → `["a","b"]` |
| `merge` | `merge(maps...)` | `merge({a=1},{b=2})` → `{a=1,b=2}` |
| `setproduct` | `setproduct(sets...)` | `setproduct(["a"],["1","2"])` |
| `zipmap` | `zipmap(keys, values)` | `zipmap(["a"],["1"])` → `{a="1"}` |
| `distinct` | `distinct(list)` | `distinct(["a","a","b"])` → `["a","b"]` |
| `compact` | `compact(list)` | `compact(["a","","b"])` → `["a","b"]` |
| `concat` | `concat(lists...)` | `concat(["a"],["b"])` → `["a","b"]` |
| `lookup` | `lookup(map, key, default)` | `lookup({a=1},"b",0)` → `0` |
| `element` ⭐ 1.10 | `element(list, index)` | `element(["a","b","c"], -1)` → `"c"` |
| `ephemeralasnull` ⭐ 1.10 | `ephemeralasnull(value)` | `ephemeralasnull(var.secret)` → `null` |

### Filesystem Functions

| Function | Signature | Example |
|----------|-----------|---------|
| `file` | `file(path)` | `file("${path.module}/key.pub")` |
| `templatefile` | `templatefile(path, vars)` | `templatefile("tmpl.tftpl", {x=1})` |
| `fileset` | `fileset(base, pattern)` | `fileset(path.module, "*.yaml")` |
| `filebase64` | `filebase64(path)` | `filebase64("cert.crt")` |

### Encoding Functions

| Function | Signature | Example |
|----------|-----------|---------|
| `jsonencode` | `jsonencode(value)` | `jsonencode({a=1})` → `'{"a":1}'` |
| `jsondecode` | `jsondecode(str)` | `jsondecode('{"a":1}')` → `{a=1}` |
| `yamlencode` | `yamlencode(value)` | `yamlencode({a=1})` → `"a: 1\n"` |
| `yamldecode` | `yamldecode(str)` | `yamldecode("a: 1")` → `{a="1"}` |
| `base64encode` | `base64encode(str)` | `base64encode("hi")` → `"aGk="` |
| `base64decode` | `base64decode(str)` | `base64decode("aGk=")` → `"hi"` |
| `tostring` | `tostring(value)` | `tostring(42)` → `"42"` |
| `tonumber` | `tonumber(str)` | `tonumber("42")` → `42` |

---

## ✅ What You've Learned

After completing TF-306, you can:

- **String Functions**: Build consistent naming conventions, parse and validate strings, format output
- **Collection Functions**: Flatten nested structures, merge configurations, generate deployment matrices
- **Filesystem Functions**: Load external configs, render templates, discover files dynamically
- **Encoding Functions**: Convert between JSON/YAML/Base64, generate API payloads, handle type coercion
- **Combinations**: Chain multiple functions to solve complex real-world problems
- **New in 1.9**: `templatestring()` — render templates from string values (not just files)
- **New in 1.10**: `element()` negative indices — access list items from the end
- **New in 1.10**: `ephemeralasnull()` — safely use ephemeral values in non-ephemeral contexts

---

## 🔗 Navigation

- **Previous Course**: [TF-305: Workspaces & Remote State](../TF-305-workspaces-remote-state/README.md)
- **Back to**: [TF-300 Advanced Course Overview](../README.md)
- **Related**: [TF-102: Variables, Loops & Functions](../../TF-100-fundamentals/TF-102-variables-loops/README.md)
- **Related**: [TF-203: YAML-Driven Configuration](../../TF-200-modules/TF-203-yaml-config/README.md)
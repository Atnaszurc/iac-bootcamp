# TF-104 Section 5: `terraform console` — Interactive Learning Tool

**Course**: TF-104 State Management & CLI  
**Section**: 5 of 5  
**Duration**: 15 minutes  
**Prerequisites**: Sections 1-4 of TF-104

---

## 📋 Overview

`terraform console` opens an **interactive REPL** (Read-Eval-Print Loop) where you can evaluate Terraform expressions, test functions, and explore your state — all without modifying any infrastructure.

It's one of the most underused but most valuable tools for learning Terraform. Think of it as a calculator for your infrastructure code.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Launch and exit `terraform console`
- ✅ Evaluate expressions and functions interactively
- ✅ Test string, collection, and numeric functions
- ✅ Explore state values without running `terraform show`
- ✅ Debug complex `for` expressions before using them in code
- ✅ Test variable values and local expressions

---

## 🚀 Launching the Console

```bash
# From any Terraform working directory
terraform console

# The prompt appears:
>
```

To exit:
```bash
> exit
# or press Ctrl+C / Ctrl+D
```

> **Note**: `terraform console` reads your current state file and variable values. Run `terraform init` first if you haven't already.

> **New in Terraform 1.9**: `terraform console` now supports **multi-line input**. You can type or paste multi-line expressions and press Enter on a blank line to evaluate them (see [Multi-Line Input](#multi-line-input-terraform-19) below).

---

## 📝 Basic Usage

### Evaluating Simple Expressions

```hcl
> 1 + 1
2

> "hello" == "hello"
true

> "terraform" != "packer"
true
```

### String Functions

```hcl
> upper("hello world")
"HELLO WORLD"

> lower("TERRAFORM")
"terraform"

> title("infrastructure as code")
"Infrastructure As Code"

> length("terraform")
9

> replace("hello world", "world", "terraform")
"hello terraform"

> split(",", "web,api,db")
tolist([
  "web",
  "api",
  "db",
])

> join("-", ["web", "api", "db"])
"web-api-db"

> trimspace("  hello  ")
"hello"

> format("Hello, %s! You are %d years old.", "Alice", 30)
"Hello, Alice! You are 30 years old."
```

### Number Functions

```hcl
> max(3, 1, 4, 1, 5, 9, 2, 6)
9

> min(3, 1, 4, 1, 5, 9, 2, 6)
1

> abs(-42)
42

> ceil(1.2)
2

> floor(1.9)
1

> pow(2, 10)
1024
```

### Collection Functions

```hcl
> length(["a", "b", "c"])
3

> length({"x" = 1, "y" = 2})
2

> contains(["web", "api", "db"], "api")
true

> contains(["web", "api", "db"], "cache")
false

> toset(["a", "b", "a", "c"])
toset([
  "a",
  "b",
  "c",
])

> sort(["banana", "apple", "cherry"])
tolist([
  "apple",
  "banana",
  "cherry",
])

> reverse(["a", "b", "c"])
tolist([
  "c",
  "b",
  "a",
])

> flatten([["a", "b"], ["c", "d"]])
tolist([
  "a",
  "b",
  "c",
  "d",
])

> merge({"a" = 1}, {"b" = 2}, {"c" = 3})
{
  "a" = 1
  "b" = 2
  "c" = 3
}

> keys({"web" = 80, "api" = 8080})
tolist([
  "api",
  "web",
])

> values({"web" = 80, "api" = 8080})
tolist([
  80,
  8080,
])
```

### Type Conversion Functions

```hcl
> tostring(42)
"42"

> tonumber("42")
42

> tobool("true")
true

> tolist(toset(["c", "a", "b"]))
tolist([
  "a",
  "b",
  "c",
])
```

---

## 📝 Multi-Line Input (Terraform 1.9+)

Before Terraform 1.9, every expression had to fit on a single line. Starting in **1.9**, the console accepts multi-line input — press **Enter on a blank line** to evaluate:

```hcl
# Multi-line for expression — much easier to read and write
> [
    for i in range(5) :
    "server-${i}"
  ]
tolist([
  "server-0",
  "server-1",
  "server-2",
  "server-3",
  "server-4",
])

# Multi-line object literal
> {
    name    = "web"
    port    = 80
    enabled = true
  }
{
  "enabled" = true
  "name" = "web"
  "port" = 80
}

# Multi-line conditional
> (
    5 > 3
    ? "five is greater"
    : "three is greater"
  )
"five is greater"
```

**Before 1.9** (single-line only):
```hcl
> [for i in range(5) : "server-${i}"]
```

**After 1.9** (multi-line supported):
```hcl
> [
    for i in range(5) :
    "server-${i}"
  ]
```

Both forms still work — multi-line is just more readable for complex expressions.

---

## 🔬 Testing `for` Expressions

This is where `terraform console` really shines — test complex expressions before putting them in your code:

```hcl
# Test a list transformation
> [for i in range(5) : "server-${i}"]
tolist([
  "server-0",
  "server-1",
  "server-2",
  "server-3",
  "server-4",
])

# Test a map transformation
> {for k, v in {"web" = 80, "api" = 8080} : v => k}
{
  "80" = "web"
  "8080" = "api"
}

# Test filtering
> [for x in [1, 2, 3, 4, 5, 6] : x if x % 2 == 0]
tolist([
  2,
  4,
  6,
])

# Test nested for with flatten
> flatten([for env in ["dev", "prod"] : [for svc in ["web", "api"] : "${env}-${svc}"]])
tolist([
  "dev-web",
  "dev-api",
  "prod-web",
  "prod-api",
])
```

---

## 🌐 Networking Functions

Particularly useful when working with Libvirt networks:

```hcl
# Calculate subnets
> cidrsubnet("10.0.0.0/16", 8, 0)
"10.0.0.0/24"

> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"

> cidrsubnet("10.0.0.0/16", 8, 255)
"10.0.255.0/24"

# Get host addresses from a subnet
> cidrhost("10.0.1.0/24", 1)
"10.0.1.1"

> cidrhost("10.0.1.0/24", 10)
"10.0.1.10"

# Check if an IP is in a range
> cidrcontains("10.0.0.0/16", "10.0.1.5")
true

> cidrcontains("10.0.0.0/16", "192.168.1.1")
false

# Get network details
> cidrnetmask("10.0.0.0/24")
"255.255.255.0"
```

---

## 🔐 Encoding Functions

```hcl
# Base64 encoding
> base64encode("Hello, Terraform!")
"SGVsbG8sIFRlcnJhZm9ybSE="

> base64decode("SGVsbG8sIFRlcnJhZm9ybSE=")
"Hello, Terraform!"

# JSON encoding/decoding
> jsonencode({"name" = "web", "port" = 80})
"{\"name\":\"web\",\"port\":80}"

> jsondecode("{\"name\":\"web\",\"port\":80}")
{
  "name" = "web"
  "port" = 80
}

# SHA256 hash (useful for triggers)
> sha256("my-config-content")
"a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3"
```

---

## 📊 Exploring State Values

When you have an initialized Terraform project with state, you can explore resource values:

```bash
# First, apply some configuration to create state
terraform apply

# Then open console
terraform console
```

```hcl
# Access resource attributes from state
> local_file.hello.filename
"./hello.txt"

> local_file.hello.content
"Hello, Terraform!"

# Access outputs
> output.all_files
tolist([
  "./hello.txt",
  "./info.txt",
])

# Access variables (if defined)
> var.environment
"dev"

# Access locals
> local.upper_names
tolist([
  "WEB",
  "API",
  "DB",
])
```

---

## 🔧 Conditional Expressions

```hcl
# Ternary operator
> true ? "yes" : "no"
"yes"

> false ? "yes" : "no"
"no"

> 5 > 3 ? "five is greater" : "three is greater"
"five is greater"

# Null coalescing pattern
> null != null ? null : "default"
"default"

> "actual-value" != null ? "actual-value" : "default"
"actual-value"
```

---

## 📅 Date/Time Functions

```hcl
# Current timestamp (RFC 3339 format)
> timestamp()
"2024-01-15T10:30:00Z"

# Format a timestamp
> formatdate("YYYY-MM-DD", timestamp())
"2024-01-15"

> formatdate("DD MMM YYYY hh:mm:ss", timestamp())
"15 Jan 2024 10:30:00"

# Time offset
> timeadd(timestamp(), "24h")
"2024-01-16T10:30:00Z"

> timeadd(timestamp(), "-1h")
"2024-01-15T09:30:00Z"
```

---

## 💡 Practical Workflows

### Workflow 1: Debug a Complex Expression

You're writing a `for` expression and it's not working as expected. Use the console to test it step by step:

```bash
terraform console
```

```hcl
# Step 1: Test with simple data
> [for s in ["web", "api", "db"] : upper(s)]
tolist(["WEB", "API", "DB"])

# Step 2: Add the filter
> [for s in ["web", "api", "db"] : upper(s) if length(s) > 2]
tolist(["WEB", "API"])

# Step 3: Test with your actual variable
> [for s in var.server_names : upper(s) if length(s) > 2]
# ... see actual results with real data
```

### Workflow 2: Verify CIDR Calculations

Before deploying network infrastructure, verify your subnet math:

```hcl
> cidrsubnet("192.168.0.0/16", 8, 0)
"192.168.0.0/24"

> cidrsubnet("192.168.0.0/16", 8, 1)
"192.168.1.0/24"

# Verify no overlap
> cidrcontains("192.168.0.0/24", "192.168.1.1")
false
```

### Workflow 3: Test String Formatting

```hcl
# Test your naming convention before applying
> format("%s-%s-%03d", "prod", "web", 1)
"prod-web-001"

> format("%s-%s-%03d", "prod", "web", 42)
"prod-web-042"
```

---

## ✅ Checkpoint Quiz

**Question 1**: What does `terraform console` allow you to do?
- A) Apply infrastructure changes interactively
- B) Evaluate Terraform expressions and functions interactively
- C) Edit Terraform state files
- D) Connect to remote VMs

<details>
<summary>Answer</summary>
**B) Evaluate Terraform expressions and functions interactively** — `terraform console` is a REPL for testing expressions, functions, and exploring state values. It does NOT modify infrastructure.
</details>

---

**Question 2**: Which function would you use to test if a list contains a specific value?
- A) `includes()`
- B) `has()`
- C) `contains()`
- D) `in()`

<details>
<summary>Answer</summary>
**C) `contains()`** — Example: `contains(["web", "api", "db"], "api")` returns `true`.
</details>

---

**Question 3**: What does `cidrsubnet("10.0.0.0/16", 8, 2)` return?
- A) `"10.0.0.0/8"`
- B) `"10.0.2.0/24"`
- C) `"10.2.0.0/16"`
- D) `"10.0.0.2/32"`

<details>
<summary>Answer</summary>
**B) `"10.0.2.0/24"`** — `cidrsubnet` takes a base CIDR, adds `newbits` (8) to the prefix length (16+8=24), and uses `netnum` (2) as the subnet number.
</details>

---

## 📚 Key Takeaways

| Use Case | Example |
|----------|---------|
| Test string functions | `upper("hello")` → `"HELLO"` |
| Test collection functions | `contains(["a","b"], "a")` → `true` |
| Debug `for` expressions | `[for i in range(3) : "vm-${i}"]` |
| Multi-line input (1.9+) | Press Enter on blank line to evaluate |
| Verify CIDR math | `cidrsubnet("10.0.0.0/16", 8, 1)` |
| Explore state values | `local_file.hello.filename` |
| Test conditionals | `5 > 3 ? "yes" : "no"` |

---

## 🔗 Next Steps

- **This is the final section of TF-104** — you've completed TF-100 Fundamentals!
- **Next Course**: [TF-200: Modules & Patterns](../../TF-200-modules/README.md)
- **Related**: [TF-102 Section 5: for Expressions](../../TF-102-variables-loops/5-for-expressions/README.md) — practice testing `for` expressions in the console

---

## 📖 Additional Resources

- [terraform console — Terraform Documentation](https://developer.hashicorp.com/terraform/cli/commands/console)
- [Built-in Functions Reference](https://developer.hashicorp.com/terraform/language/functions)
- [Expressions Reference](https://developer.hashicorp.com/terraform/language/expressions)
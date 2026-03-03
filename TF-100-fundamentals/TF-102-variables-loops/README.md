# TF-102: Variables, Loops & Functions

**Course**: TF-100 Terraform Fundamentals  
**Module**: TF-102  
**Duration**: 1.5 hours  
**Prerequisites**: TF-101 (Introduction to IaC & Terraform Basics)  
**Difficulty**: Beginner

---

## 📋 Overview

This course teaches you how to make Terraform configurations dynamic, reusable, and maintainable using variables, loops, and functions. You'll learn to parameterize your infrastructure, create multiple resources efficiently, and transform data using Terraform's built-in functions.

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ **Define** variables with different types (string, number, bool, list, map, object)
- ✅ **Validate** variable inputs using modern validation syntax
- ✅ **Implement** loops using `count` and `for_each` meta-arguments
- ✅ **Choose** between count and for_each appropriately
- ✅ **Create** dynamic blocks for nested configurations
- ✅ **Use** Terraform built-in functions for data transformation
- ✅ **Read** variables from multiple sources (CLI, files, environment)
- ✅ **Build** variable-driven, reusable configurations
- ✅ **Apply** best practices for variable management

---

## 📚 Course Structure

This course is organized into **5 progressive sections**. Complete them in order for the best learning experience.

### Section 1: Variables 📦
**Directory**: [`1-variables/`](./1-variables/)  
**Duration**: 25 minutes

**Topics Covered**:
- Variable types (primitive, collection, structural)
- Variable definitions and defaults
- Variable validation with modern syntax
- Using variables in resources
- Variable best practices

**What You'll Learn**:
- How to define variables with proper types
- How to validate user inputs
- How to use variables throughout your configuration
- When to use different variable types

**[→ Start Section 1: Variables](./1-variables/README.md)**

---

### Section 2: Loops 🔁
**Directory**: [`2-loops/`](./2-loops/)  
**Duration**: 30 minutes

**Topics Covered**:
- `count` meta-argument for simple duplication
- `for_each` meta-argument for named resources
- When to use count vs for_each
- Creating multiple resources dynamically
- Iteration patterns and best practices

**What You'll Learn**:
- How to create multiple resources with count
- How to create named resources with for_each
- Why for_each is usually better than count
- How to avoid common pitfalls with loops

**[→ Start Section 2: Loops](./2-loops/README.md)**

---

### Section 3: Environment Variables 🌍
**Directory**: [`3-env-vars/`](./3-env-vars/)  
**Duration**: 20 minutes

**Topics Covered**:
- Reading variables from environment (TF_VAR_*)
- Using .tfvars files
- Variable precedence and override order
- CLI variable flags (-var, -var-file)
- Managing variables across environments

**What You'll Learn**:
- How to set variables from different sources
- Understanding variable precedence rules
- How to manage dev/staging/prod configurations
- Best practices for variable organization

**[→ Start Section 3: Environment Variables](./3-env-vars/README.md)**

---

### Section 4: Functions 🔧
**Directory**: [`4-functions/`](./4-functions/)  
**Duration**: 25 minutes

**Topics Covered**:
- String functions (upper, lower, join, split, replace)
- Collection functions (length, merge, concat, contains)
- Type conversion functions (tostring, tonumber, tolist)
- File functions (file, templatefile, fileexists)
- Encoding functions (jsonencode, yamlencode)
- Date/time functions (timestamp, formatdate)

**What You'll Learn**:
- How to transform strings and data
- How to work with lists and maps
- How to read and template files
- How to encode/decode JSON and YAML
- Common function patterns and use cases

**[→ Start Section 4: Functions](./4-functions/README.md)**

---

### Section 5: `for` Expressions 🔄
**Directory**: [`5-for-expressions/`](./5-for-expressions/)
**Duration**: 25 minutes

**Topics Covered**:
- `for` expressions vs `for_each` meta-argument (key distinction)
- List output: `[for item in collection : expression]`
- Map output: `{for key, value in collection : new_key => new_value}`
- Filtering with `if` clause
- Nested `for` expressions with `flatten()`
- Real-world patterns: tag maps, data transformation, flattening nested data

**What You'll Learn**:
- How to transform lists and maps into new collections
- How to filter collections inline
- When to use `for` expressions vs other approaches
- How to test expressions with `terraform console`

**[→ Start Section 5: for Expressions](./5-for-expressions/README.md)**

---

## 🚀 Quick Start

### Option 1: Follow the Course Path (Recommended)

Complete each section in order:

```bash
# 1. Start with Variables
cd 1-variables/
cat README.md
cd example/
terraform init
terraform apply

# 2. Move to Loops
cd ../2-loops/
cat README.md
cd example/
terraform init
terraform apply

# 3. Learn Environment Variables
cd ../3-env-vars/
cat README.md
cd example/
terraform init
terraform apply

# 4. Master Functions
cd ../4-functions/
cat README.md
cd example/
terraform init
terraform apply
```

### Option 2: Jump to a Specific Topic

If you're already familiar with some topics, jump directly to what you need:

- **Need to learn variables?** → [`1-variables/`](./1-variables/)
- **Want to create multiple resources?** → [`2-loops/`](./2-loops/)
- **Managing different environments?** → [`3-env-vars/`](./3-env-vars/)
- **Need to transform data?** → [`4-functions/`](./4-functions/)
- **Need to transform collections inline?** → [`5-for-expressions/`](./5-for-expressions/)

---

## 📖 Key Concepts Summary

### Variables

Variables make your configurations flexible and reusable:

```hcl
variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

resource "local_file" "config" {
  content  = "Environment: ${var.environment}"
  filename = "${path.module}/config.txt"
}
```

**Learn more**: [Section 1: Variables](./1-variables/README.md)

---

### Loops

Create multiple resources efficiently:

```hcl
# Using for_each (recommended)
variable "servers" {
  type    = set(string)
  default = ["web", "api", "db"]
}

resource "local_file" "server" {
  for_each = var.servers
  content  = "Server: ${each.key}"
  filename = "${path.module}/${each.key}.txt"
}
```

**Learn more**: [Section 2: Loops](./2-loops/README.md)

---

### Environment Variables

Manage configurations across environments:

```bash
# Set via environment
export TF_VAR_environment="production"
export TF_VAR_instance_count=10

# Or use tfvars file
terraform apply -var-file="production.tfvars"

# Or CLI flags
terraform apply -var="environment=prod"
```

**Learn more**: [Section 3: Environment Variables](./3-env-vars/README.md)

---

### Functions

Transform and manipulate data:

```hcl
locals {
  # String functions
  app_name_upper = upper("my-app")           # "MY-APP"
  app_name_slug  = lower(replace("My App", " ", "-"))  # "my-app"
  
  # Collection functions
  combined = concat(["a", "b"], ["c", "d"])  # ["a", "b", "c", "d"]
  merged   = merge({a = 1}, {b = 2})         # {a = 1, b = 2}
  
  # Type conversion
  port_number = tonumber("8080")             # 8080
  
  # Encoding
  json_config = jsonencode({app = "myapp"})  # {"app":"myapp"}
}
```

**Learn more**: [Section 4: Functions](./4-functions/README.md)

---

## 🎓 Learning Path

### Recommended Order

1. **Start Here**: [Section 1 - Variables](./1-variables/README.md)
   - Foundation for everything else
   - Learn variable types and validation
   - Practice with examples

2. **Then**: [Section 2 - Loops](./2-loops/README.md)
   - Build on variable knowledge
   - Learn to create multiple resources
   - Understand count vs for_each

3. **Next**: [Section 3 - Environment Variables](./3-env-vars/README.md)
   - Learn to manage configurations
   - Understand variable precedence
   - Practice with different environments

4. **Finally**: [Section 4 - Functions](./4-functions/README.md)
   - Master data transformation
   - Learn common function patterns
   - Apply functions to real scenarios

### Time Commitment

- **Minimum**: 1.5 hours (reading + basic examples)
- **Recommended**: 3 hours (reading + all examples + experimentation)
- **Mastery**: 5+ hours (reading + examples + building your own configurations)

---

## 🧪 Hands-On Practice

Each section includes:

- ✅ **Detailed README** - Concepts explained with examples
- ✅ **Working Code** - Ready-to-run Terraform configurations in `example/` directories
- ✅ **Practical Exercises** - Hands-on tasks to reinforce learning
- ✅ **Real-World Scenarios** - Examples you'll use in production

### Practice Projects

After completing all sections, try these projects:

1. **Multi-Environment Setup**
   - Create dev/staging/prod configurations
   - Use variables and tfvars files
   - Practice variable precedence

2. **Dynamic Infrastructure**
   - Create multiple VMs with for_each
   - Use variables to control count
   - Apply functions for naming

3. **Configuration Generator**
   - Use templatefile() to generate configs
   - Transform data with functions
   - Validate inputs with validation blocks

---

## ✅ Checkpoint Quiz

Test your understanding after completing all sections:

### Question 1: Variable Types
**Which variable type ensures no duplicate values?**
- A) `list(string)`
- B) `set(string)`
- C) `map(string)`
- D) `tuple([string])`

<details>
<summary>Show Answer</summary>

**B) `set(string)`** - Sets automatically remove duplicates and are ideal for collections of unique values.
</details>

### Question 2: Loops
**When should you prefer for_each over count?**
- A) When creating a fixed number of resources
- B) When resources have names or identities
- C) When you need simple duplication
- D) Never, count is always better

<details>
<summary>Show Answer</summary>

**B) When resources have names or identities** - for_each uses keys instead of indices, making configurations more stable when adding/removing resources.
</details>

### Question 3: Variable Precedence
**Which has the HIGHEST precedence?**
- A) terraform.tfvars file
- B) Environment variables (TF_VAR_*)
- C) -var command-line flag
- D) Variable defaults

<details>
<summary>Show Answer</summary>

**C) -var command-line flag** - CLI flags have the highest precedence and override all other sources.
</details>

### Question 4: Functions
**Which function combines two lists?**
- A) `merge()`
- B) `concat()`
- C) `join()`
- D) `combine()`

<details>
<summary>Show Answer</summary>

**B) `concat()`** - concat() combines multiple lists. merge() is for maps, join() converts lists to strings.
</details>

**More quizzes available in each section!**

---

## 📋 Prerequisites

Before starting this course, you should:

- ✅ Complete [TF-101: Introduction to IaC & Terraform Basics](../TF-101-intro-basics/README.md)
- ✅ Have Terraform installed (v1.14+)
- ✅ Understand basic HCL syntax
- ✅ Know how to run terraform init/plan/apply
- ✅ Have a text editor or IDE ready

---

## 🎯 What You'll Build

By the end of this course, you'll be able to build configurations like this:

```hcl
# variables.tf
variable "environments" {
  type = map(object({
    instance_count = number
    instance_size  = string
    enable_backup  = bool
  }))
  default = {
    dev = {
      instance_count = 2
      instance_size  = "small"
      enable_backup  = false
    }
    prod = {
      instance_count = 5
      instance_size  = "large"
      enable_backup  = true
    }
  }
}

# main.tf
resource "example_instance" "servers" {
  for_each = var.environments
  
  name  = "${each.key}-server"
  count = each.value.instance_count
  size  = each.value.instance_size
  
  dynamic "backup" {
    for_each = each.value.enable_backup ? [1] : []
    content {
      enabled = true
      schedule = "daily"
    }
  }
  
  tags = merge(
    local.common_tags,
    {
      Environment = upper(each.key)
      Name        = format("%s-server-%02d", each.key, count.index + 1)
    }
  )
}
```

**Impressive, right?** Let's get started!

---

## 🔗 Additional Resources

### Official Documentation
- [Terraform Variables](https://developer.hashicorp.com/terraform/language/values/variables)
- [Terraform Expressions](https://developer.hashicorp.com/terraform/language/expressions)
- [Terraform Functions](https://developer.hashicorp.com/terraform/language/functions)
- [Meta-Arguments](https://developer.hashicorp.com/terraform/language/meta-arguments/count)

### Community Resources
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Terraform Registry](https://registry.terraform.io/)
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)

### Next Steps
After completing TF-102, continue to:
- **[TF-103: Infrastructure Resources](../TF-103-infrastructure/README.md)** - Create networks, security groups, and VMs
- **[TF-104: State Management & CLI](../TF-104-state-cli/README.md)** - Master state and CLI commands

---

## 💡 Tips for Success

1. **Complete sections in order** - Each builds on the previous
2. **Run all examples** - Hands-on practice is essential
3. **Experiment** - Modify examples to see what happens
4. **Take notes** - Document patterns you find useful
5. **Ask questions** - Use the troubleshooting sections
6. **Practice regularly** - Consistency beats cramming

---

## 🚦 Getting Started

Ready to begin? Start with Section 1:

**[→ Begin with Variables](./1-variables/README.md)**

Or jump to a specific section:
- [Section 1: Variables](./1-variables/README.md)
- [Section 2: Loops](./2-loops/README.md)
- [Section 3: Environment Variables](./3-env-vars/README.md)
- [Section 4: Functions](./4-functions/README.md)

---

## 📊 Progress Tracking

Use this checklist to track your progress:

- [ ] **Section 1: Variables** - Variable types, validation, usage
- [ ] **Section 2: Loops** - count, for_each, iteration patterns
- [ ] **Section 3: Environment Variables** - Variable sources, precedence
- [ ] **Section 4: Functions** - String, collection, type, file functions
- [ ] **Checkpoint Quiz** - Test your understanding
- [ ] **Practice Projects** - Build real configurations

---

**Course**: TF-100 Terraform Fundamentals  
**Module**: TF-102  
**Version**: 1.0  
**Last Updated**: 2026-02-26

**Ready to make your Terraform configurations dynamic and reusable? Let's go!** 🚀
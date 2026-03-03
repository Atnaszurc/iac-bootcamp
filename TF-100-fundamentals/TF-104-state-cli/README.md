# TF-104: State Management & CLI

**Course Level**: 100 (Beginner)  
**Duration**: 1 hour  
**Prerequisites**: TF-103 (Infrastructure Resources)

---

## 📋 Overview

This course covers essential Terraform operational concepts including CLI commands, state management, an introduction to modules, and debugging techniques. You'll learn how to effectively work with Terraform in day-to-day operations and troubleshoot common issues.

**This is the final course in the TF-100 Fundamentals series!** After completing TF-104, you'll have a solid foundation in Terraform and be ready for intermediate topics in TF-200.

---

## 🎯 Learning Objectives

By the end of this course, you will be able to:

- ✅ Use all essential Terraform CLI commands effectively
- ✅ Understand Terraform state and its critical importance
- ✅ Manage state files safely and securely
- ✅ Manipulate state when necessary (safely)
- ✅ Create basic modules for code reusability
- ✅ Debug Terraform configurations effectively
- ✅ Apply best practices for Terraform operations
- ✅ Troubleshoot common issues independently
- ✅ Use logging and validation tools
- ✅ Understand state backends and locking

---

## 📚 Course Structure

This course is organized into **5 comprehensive sections** covering operational aspects of Terraform:

### 1. CLI Commands 🖥️
**Directory**: [`1-cli/`](./1-cli/)  
**Duration**: 15 minutes

**What You'll Learn**:
- Complete Terraform CLI workflow
- Essential commands (init, plan, apply, destroy)
- Code formatting and validation
- Output management
- Advanced CLI flags and options
- Command chaining and automation

**Key Commands Covered**:
- `terraform init` - Initialize working directory
- `terraform fmt` - Format code consistently
- `terraform validate` - Validate configuration syntax
- `terraform plan` - Preview infrastructure changes
- `terraform apply` - Apply changes to infrastructure
- `terraform destroy` - Destroy infrastructure
- `terraform output` - View output values
- `terraform show` - Inspect state or plan files
- `terraform modules -json` - List modules (1.10+)
- `terraform query` - Query existing infrastructure (1.14+)
- `terraform stacks` - Manage Terraform Stacks (1.13+, HCP only)

**Hands-On**: Practice the complete Terraform workflow with real examples

---

### 2. State Management 📊
**Directory**: [`2-state/`](./2-state/)  
**Duration**: 20 minutes

**What You'll Learn**:
- What is Terraform state and why it's critical
- State file structure (terraform.tfstate)
- State locking mechanisms
- Remote state backends (S3, Azure Storage, etc.)
- State security best practices
- State manipulation commands
- Backup and recovery strategies
- Handling state drift

**Critical Concepts**:
- **State File Contents**: Resource IDs, attributes, dependencies, outputs
- **State Locking**: Prevents concurrent modifications
- **Remote State**: Enables team collaboration
- **State Security**: Contains sensitive data (passwords, keys)

**State Commands Covered**:
- `terraform state list` - List all resources
- `terraform state show` - Show resource details
- `terraform state mv` - Move resources in state
- `terraform state rm` - Remove resources from state
- `terraform state pull` - Download remote state
- `terraform state push` - Upload state (dangerous!)

**Hands-On**: Practice safe state manipulation techniques

---

### 3. Introduction to Modules 📦
**Directory**: [`3-modules-intro/`](./3-modules-intro/)  
**Duration**: 15 minutes

**What You'll Learn**:
- What are Terraform modules?
- Why use modules for code organization
- Basic module structure and conventions
- Module inputs (variables)
- Module outputs
- Calling modules from root configuration
- Module benefits for reusability
- When to create modules vs. when to keep code flat

**Module Structure**:
```
my-module/
├── main.tf       # Resources
├── variables.tf  # Input variables
├── outputs.tf    # Output values
└── README.md     # Documentation
```

**Key Concepts**:
- **Root Module**: Your main Terraform configuration
- **Child Modules**: Reusable components called by root
- **Module Sources**: Local paths, Git repos, Terraform Registry
- **Module Versioning**: Pin versions for stability

**Hands-On**: Create and use your first Terraform module

---

### 4. Debugging & Troubleshooting 🔍
**Directory**: [`4-debugging/`](./4-debugging/)  
**Duration**: 10 minutes

**What You'll Learn**:
- Common Terraform error messages and meanings
- Reading and interpreting Terraform logs
- Using TF_LOG environment variable
- Debugging strategies and workflows
- Validation techniques
- Plan analysis for catching issues early
- Systematic troubleshooting approaches

**Debugging Tools**:
- **TF_LOG**: Set log level (TRACE, DEBUG, INFO, WARN, ERROR)
- **TF_LOG_PATH**: Save logs to file
- **terraform validate**: Check syntax
- **terraform fmt -check**: Verify formatting
- **terraform plan**: Preview changes before applying

**Common Error Categories**:
- **Syntax Errors**: Missing quotes, invalid blocks
- **Resource Errors**: Already exists, insufficient permissions
- **State Errors**: Lock conflicts, drift, missing resources
- **Provider Errors**: Authentication, API limits

**Hands-On**: Debug real-world Terraform issues

---

### 5. `terraform console` — Interactive REPL 🖥️
**Directory**: [`5-terraform-console/`](./5-terraform-console/)
**Duration**: 15 minutes

**What You'll Learn**:
- Launching and using `terraform console`
- Testing string, collection, and numeric functions interactively
- Debugging complex `for` expressions before using them in code
- Exploring state values without running `terraform show`
- Verifying CIDR calculations for network planning
- Testing conditional expressions
- **Multi-line input** (Terraform 1.9+) — type expressions across multiple lines

**Key Commands**:
- `terraform console` — Open the interactive REPL
- `Ctrl+C` or `exit` — Exit the console

**Hands-On**: Use the console to test functions and debug expressions

---

## 🚀 Recommended Learning Path

Follow this sequence for optimal learning:

1. **Start with CLI Commands** (1-cli/)
   - Master the essential Terraform workflow
   - Practice each command with examples
   - Understand command flags and options

2. **Deep Dive into State** (2-state/)
   - Critical for safe Terraform operations
   - Learn state manipulation techniques
   - Understand remote state and locking

3. **Explore Modules** (3-modules-intro/)
   - Introduction to code organization
   - Create reusable components
   - Understand module composition

4. **Master Debugging** (4-debugging/)
   - Troubleshoot issues effectively
   - Use logging and validation tools
   - Develop systematic debugging workflows

5. **Use terraform console** (5-terraform-console/)
   - Test functions and expressions interactively
   - Debug complex `for` expressions
   - Explore state values without modifying infrastructure

---

## 💻 Hands-On Labs

### Lab 1: Complete CLI Workflow
**Duration**: 15 minutes  
**Difficulty**: Beginner

**Objective**: Practice the complete Terraform workflow from initialization to destruction.

**Tasks**:
1. Initialize a new Terraform project
2. Format and validate the configuration
3. Plan infrastructure changes
4. Apply changes and verify outputs
5. Make modifications and re-apply
6. Destroy infrastructure cleanly

**Skills Practiced**:
- CLI command sequence
- Reading plan output
- Understanding apply process
- Clean resource destruction

---

### Lab 2: State Manipulation
**Duration**: 20 minutes  
**Difficulty**: Intermediate

**Objective**: Safely manipulate Terraform state to handle real-world scenarios.

**Scenarios**:
1. **Rename a resource** without destroying it
2. **Remove a resource** from state (manual management)
3. **Import existing infrastructure** into state
4. **Recover from state corruption** using backups

**Skills Practiced**:
- State list and show commands
- State mv for renaming
- State rm for removal
- State backup and recovery

**⚠️ Warning**: State manipulation is powerful but dangerous. Always backup first!

---

### Lab 3: Module Creation
**Duration**: 20 minutes  
**Difficulty**: Intermediate

**Objective**: Create a reusable module and use it in multiple configurations.

**Tasks**:
1. Extract common infrastructure into a module
2. Define module inputs (variables)
3. Define module outputs
4. Call the module from root configuration
5. Use the module multiple times with different inputs

**Skills Practiced**:
- Module structure and organization
- Variable and output design
- Module composition
- Code reusability

---

## 📝 Checkpoint Quiz

Test your understanding of state management and CLI operations:

### Question 1: CLI Workflow
**What is the correct order of Terraform commands for a new project?**

A) `apply` → `init` → `plan` → `validate`  
B) `init` → `validate` → `plan` → `apply`  
C) `plan` → `init` → `validate` → `apply`  
D) `validate` → `init` → `plan` → `apply`

<details>
<summary>Show Answer</summary>

**Answer: B** - `init` → `validate` → `plan` → `apply`

**Explanation**: 
1. `init` downloads providers and modules
2. `validate` checks syntax
3. `plan` previews changes
4. `apply` executes changes

`fmt` is optional but recommended before `validate`.
</details>

---

### Question 2: State File Security
**Why should Terraform state files be protected?**

A) They contain large amounts of data  
B) They contain sensitive information like passwords and keys  
C) They are difficult to recreate  
D) They slow down Terraform operations

<details>
<summary>Show Answer</summary>

**Answer: B** - They contain sensitive information like passwords and keys

**Explanation**: State files store all resource attributes, including sensitive data like database passwords, API keys, and private keys. They should be:
- Encrypted at rest
- Access-controlled
- Never committed to version control
- Stored in secure remote backends
</details>

---

### Question 3: State Locking
**What is the purpose of state locking?**

A) To prevent unauthorized access to state files  
B) To prevent concurrent modifications by multiple users  
C) To encrypt state file contents  
D) To backup state files automatically

<details>
<summary>Show Answer</summary>

**Answer: B** - To prevent concurrent modifications by multiple users

**Explanation**: State locking prevents multiple Terraform processes from modifying state simultaneously, which could cause corruption. Remote backends like S3 with DynamoDB provide automatic locking.
</details>

---

### Question 4: Module Benefits
**What is the PRIMARY benefit of using Terraform modules?**

A) Faster execution time  
B) Smaller state files  
C) Code reusability and organization  
D) Automatic error handling

<details>
<summary>Show Answer</summary>

**Answer: C** - Code reusability and organization

**Explanation**: Modules allow you to:
- Reuse common infrastructure patterns
- Organize complex configurations
- Share code across teams
- Enforce standards and best practices
- Reduce duplication
</details>

---

### Question 5: State Manipulation
**When should you use `terraform state rm`?**

A) To delete resources from infrastructure  
B) To remove resources from state without destroying them  
C) To fix syntax errors  
D) To reset Terraform completely

<details>
<summary>Show Answer</summary>

**Answer: B** - To remove resources from state without destroying them

**Explanation**: `terraform state rm` removes resources from state tracking but doesn't destroy the actual infrastructure. Use cases:
- Transitioning to manual management
- Moving resources to different state files
- Removing resources that no longer exist

Always backup state before using this command!
</details>

---

### Question 6: Debugging
**Which environment variable enables detailed Terraform logging?**

A) `TF_DEBUG=true`  
B) `TF_LOG=DEBUG`  
C) `TERRAFORM_VERBOSE=1`  
D) `TF_TRACE=on`

<details>
<summary>Show Answer</summary>

**Answer: B** - `TF_LOG=DEBUG`

**Explanation**: TF_LOG accepts these values:
- `TRACE` - Most detailed
- `DEBUG` - Detailed debugging info
- `INFO` - General information
- `WARN` - Warnings only
- `ERROR` - Errors only

Use `TF_LOG_PATH` to save logs to a file.
</details>

---

## 🔧 Essential CLI Workflow

The standard Terraform workflow you'll use daily:

```bash
# 1. Initialize (download providers, modules)
terraform init

# 2. Format code (optional but recommended)
terraform fmt

# 3. Validate configuration
terraform validate

# 4. Preview changes
terraform plan

# 5. Apply changes
terraform apply

# 6. View outputs
terraform output

# 7. Destroy when done (optional)
terraform destroy
```

### PowerShell Example (Windows)
```powershell
# Set working directory
cd C:\terraform\my-project

# Initialize and apply
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

# View outputs
terraform output -json | ConvertFrom-Json
```

---

## 📊 State Management Best Practices

### Critical Rules ⚠️

1. **Never edit state files manually**
   - Use Terraform commands only
   - Manual edits can corrupt state
   - State corruption can destroy infrastructure

2. **Always use remote state for teams**
   - Prevents conflicts between team members
   - Enables collaboration
   - Provides automatic locking
   - Examples: S3 + DynamoDB, Azure Storage, Terraform Cloud

3. **Backup state files regularly**
   - Terraform creates `.backup` files automatically
   - Store backups securely and separately
   - Test recovery procedures periodically
   - Keep multiple backup versions

4. **Protect state files from unauthorized access**
   - Contains sensitive data (passwords, keys, IPs)
   - Use encryption at rest
   - Restrict access with IAM/RBAC
   - Never commit to version control

5. **Use state locking**
   - Prevents concurrent modifications
   - Enabled automatically with most remote backends
   - Critical for team environments

### State File Contents

State files contain:
- ✅ Resource IDs and unique identifiers
- ✅ Resource attributes and properties
- ✅ Resource dependencies and relationships
- ✅ Provider configurations
- ✅ Output values
- ⚠️ **Sensitive data** (passwords, keys, tokens)

### Remote State Backends

**Popular Options**:
- **S3 + DynamoDB** (AWS) - Most common
- **Azure Storage** (Azure) - Native Azure integration
- **Google Cloud Storage** (GCP) - Native GCP integration
- **Terraform Cloud** - HashiCorp's managed service
- **Consul** - For HashiCorp stack integration

**Example S3 Backend**:
```hcl
# Modern S3 backend with native state locking (Terraform 1.11+)
terraform {
  backend "s3" {
    bucket       = "my-terraform-state"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true  # S3 native locking (1.11+) — replaces DynamoDB

    # DEPRECATED: dynamodb_table = "terraform-locks"
    # DynamoDB locking is deprecated in 1.11 — use use_lockfile = true instead
  }
}
```

> **Note**: The `dynamodb_table` argument for S3 state locking is deprecated in Terraform 1.11. Use `use_lockfile = true` for S3 native locking instead. See **TF-305** for a full deep dive on remote backends.

---

## 📦 Module Basics

### When to Create Modules

Create modules when you:
- ✅ Reuse the same infrastructure pattern multiple times
- ✅ Want to share configurations across teams
- ✅ Need to enforce organizational standards
- ✅ Have complex configurations that need organization
- ✅ Want to version and distribute infrastructure patterns

### Module Structure

```
my-module/
├── main.tf       # Resources and data sources
├── variables.tf  # Input variables
├── outputs.tf    # Output values
├── versions.tf   # Provider version constraints
└── README.md     # Documentation
```

### Using Modules

```hcl
# Call a local module
module "network" {
  source = "./modules/network"
  
  network_name = "my-network"
  cidr_block   = "10.0.0.0/16"
}

# Call a registry module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

# Use module outputs
resource "libvirt_domain" "vm" {
  name   = "my-vm"
  network_interface {
    network_id = module.network.network_id
  }
}
```

### Module Best Practices

1. **Keep modules focused** - One purpose per module
2. **Document inputs and outputs** - Clear README
3. **Use semantic versioning** - For published modules
4. **Validate inputs** - Use variable validation
5. **Provide examples** - Show how to use the module
6. **Test modules** - Use Terraform test framework

---

## 🔍 Debugging Strategies

### 1. Enable Detailed Logging

```bash
# Linux/macOS
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Windows PowerShell
$env:TF_LOG="DEBUG"
$env:TF_LOG_PATH="terraform.log"

# Run Terraform
terraform apply

# Review logs
cat terraform.log  # Linux/macOS
Get-Content terraform.log  # PowerShell
```

### 2. Validate Configuration

```bash
# Check syntax
terraform validate

# Format code
terraform fmt -check
terraform fmt -recursive

# Plan with detailed output
terraform plan -out=tfplan
terraform show tfplan
terraform show -json tfplan | jq
```

### 3. Common Error Patterns

**Syntax Errors**:
- Missing quotes around strings
- Incorrect block structure or nesting
- Invalid resource or variable names
- Typos in resource types

**Resource Errors**:
- Resource already exists (import it)
- Insufficient permissions (check IAM/RBAC)
- Invalid configuration (check provider docs)
- API rate limits (add retry logic)

**State Errors**:
- State lock conflicts (wait or force-unlock)
- State drift (refresh and reconcile)
- Missing resources (import or remove from state)
- Corrupted state (restore from backup)

**Provider Errors**:
- Authentication failures (check credentials)
- API version mismatches (update provider)
- Network connectivity issues (check firewall)
- Provider bugs (check GitHub issues)

---

## 🛠️ Troubleshooting Workflow

Follow this systematic approach when debugging:

### Step 1: Read the Error Message Carefully
- Terraform errors are usually descriptive
- Note the resource type and name
- Note the line number in the error
- Look for the root cause, not just symptoms

### Step 2: Check the Documentation
- Provider documentation (terraform.io)
- Resource-specific requirements
- Known issues and limitations
- Example configurations

### Step 3: Validate Incrementally
- Comment out sections of code
- Add resources one at a time
- Isolate the problematic resource
- Test in a separate configuration

### Step 4: Use Plan Before Apply
- Always review changes before applying
- Understand what will be created/modified/destroyed
- Check for unexpected changes
- Catch issues early in the workflow

### Step 5: Enable Logging
- Use TF_LOG for detailed output
- Review logs for API calls and responses
- Look for patterns in errors
- Save logs for later analysis

### Step 6: Search for Solutions
- Check Terraform GitHub issues
- Search provider-specific forums
- Review Stack Overflow
- Ask in HashiCorp community forums

---

## 📖 Common Commands Reference

### Initialization
```bash
terraform init                    # Initialize directory
terraform init -upgrade           # Upgrade providers to latest
terraform init -reconfigure       # Reconfigure backend
terraform init -migrate-state     # Migrate state to new backend
terraform init -json              # Machine-readable JSON output (1.9+)
```

### Planning
```bash
terraform plan                    # Show execution plan
terraform plan -out=tfplan        # Save plan to file
terraform plan -destroy           # Plan destruction
terraform plan -target=resource   # Plan specific resource
terraform plan -refresh-only      # Plan refresh only
# ⚠️ DEPRECATED (1.10+): terraform plan -state=custom.tfstate
```

### Applying
```bash
terraform apply                   # Apply changes (with prompt)
terraform apply -auto-approve     # Apply without prompt
terraform apply tfplan            # Apply saved plan
terraform apply -target=resource  # Apply specific resource
# ⚠️ DEPRECATED (1.10+): terraform apply -state=custom.tfstate
```

### State Management
```bash
terraform state list              # List resources in state
terraform state show <resource>   # Show resource details
terraform state mv <src> <dst>    # Move resource in state
terraform state rm <resource>     # Remove resource from state
terraform state pull              # Download remote state
terraform state push              # Upload state (dangerous!)
terraform state replace-provider  # Replace provider in state
```

### Outputs
```bash
terraform output                  # Show all outputs
terraform output <name>           # Show specific output
terraform output -json            # Output as JSON
terraform output -raw <name>      # Raw output (no quotes)
```

### Workspace Management
```bash
terraform workspace list          # List workspaces
terraform workspace new <name>    # Create workspace
terraform workspace select <name> # Switch workspace
terraform workspace delete <name> # Delete workspace
```

### Module Inspection (1.10+)
```bash
terraform modules -json           # List all modules as JSON (1.10+)
```

### Query (1.14+)
```bash
terraform query                              # Query existing infrastructure
terraform query -generate-config-out=out.tf  # Generate import config from results
```

### Stacks (1.13+ — HCP Terraform only)
```bash
terraform stacks validate         # Validate stack configuration
terraform stacks plan             # Plan stack deployment
terraform stacks apply            # Apply stack deployment
```

### Cleanup
```bash
terraform destroy                 # Destroy all resources
terraform destroy -target=<res>   # Destroy specific resource
terraform destroy -auto-approve   # Destroy without prompt
```

### Formatting and Validation
```bash
terraform fmt                     # Format current directory
terraform fmt -recursive          # Format recursively
terraform fmt -check              # Check if formatted
terraform validate                # Validate configuration
```

---

## 🎓 Prerequisites

Before starting this course, ensure you have:

- ✅ Terraform installed (v1.0+)
- ✅ Completed TF-101 (Introduction to IaC & Terraform Basics)
- ✅ Completed TF-102 (Variables, Loops & Functions)
- ✅ Completed TF-103 (Infrastructure Resources)
- ✅ Basic understanding of infrastructure resources
- ✅ Text editor or IDE (VS Code recommended)
- ✅ Command-line familiarity

---

## 🚀 Getting Started

### Quick Start

1. **Navigate to the first section**:
   ```bash
   cd 1-cli/
   ```

2. **Read the README.md** for CLI concepts

3. **Practice each command** with the examples in `example/`

4. **Progress through sections 2-4** in order

### What's Included

Each section includes:
- 📖 Detailed README with concepts and examples
- 💻 Working Terraform code in `example/` directory
- 🎯 Practical exercises to reinforce learning
- 🔧 Real-world scenarios and solutions
- ⚠️ Common pitfalls and how to avoid them

---

## 📚 Additional Resources

### Official Documentation
- [Terraform CLI Documentation](https://developer.hashicorp.com/terraform/cli)
- [Terraform State Documentation](https://developer.hashicorp.com/terraform/language/state)
- [Terraform Modules Documentation](https://developer.hashicorp.com/terraform/language/modules)
- [Terraform Debugging Guide](https://developer.hashicorp.com/terraform/internals/debugging)

### Community Resources
- [Terraform Registry](https://registry.terraform.io/) - Public modules
- [Terraform GitHub](https://github.com/hashicorp/terraform) - Source code and issues
- [HashiCorp Learn](https://learn.hashicorp.com/terraform) - Official tutorials
- [Terraform Community Forum](https://discuss.hashicorp.com/c/terraform-core) - Get help

### Books and Guides
- "Terraform: Up & Running" by Yevgeniy Brikman
- "Terraform Best Practices" (online guide)
- HashiCorp's official certification study guide

---

## 🎉 Congratulations!

After completing TF-104, you've finished the **Terraform Fundamentals (TF-100) series**! 

### What You've Accomplished

You now have a solid foundation in:
- ✅ Infrastructure as Code concepts
- ✅ Terraform syntax and language features
- ✅ Variables, loops, and functions
- ✅ Infrastructure resource management
- ✅ State management and CLI operations
- ✅ Basic module creation
- ✅ Debugging and troubleshooting

### Next Steps

**Continue Your Learning Journey**:

1. **TF-200: Terraform Modules & Patterns** (Recommended Next)
   - Deep dive into module design
   - Advanced module patterns
   - YAML-driven configuration
   - Import and migration strategies

2. **PKR-100: Packer Fundamentals** (Parallel Track)
   - Learn to build machine images
   - Integrate with Terraform
   - Automate image creation

3. **Cloud Modules** (Optional - After TF-200)
   - **AWS-200**: Apply skills to AWS
   - **AZ-200**: Apply skills to Azure
   - **MC-300**: Multi-cloud patterns

### Keep Practicing!

The best way to master Terraform is through practice:
- Build real infrastructure projects
- Contribute to open-source modules
- Experiment with different providers
- Join the Terraform community

---

## 📞 Need Help?

- **Documentation**: Check the section READMEs in subdirectories
- **Issues**: Review common errors in the debugging section
- **Community**: Ask in HashiCorp forums or Stack Overflow
- **Practice**: Work through the hands-on labs multiple times

---

**Ready to become a Terraform expert?** Start with section 1-cli/ and work your way through! 🚀

---

*This course completes the TF-100 Fundamentals series. You're now ready for intermediate topics in TF-200!*

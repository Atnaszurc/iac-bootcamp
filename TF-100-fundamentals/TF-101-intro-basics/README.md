# TF-101: Introduction to IaC & Terraform Basics

**Course**: TF-100 Terraform Fundamentals  
**Module**: TF-101  
**Duration**: 1.5 hours  
**Prerequisites**: None  
**Difficulty**: Beginner

---

## 📋 Table of Contents

1. [Learning Objectives](#learning-objectives)
2. [What is Infrastructure as Code (IaC)?](#what-is-infrastructure-as-code-iac)
3. [What is Terraform?](#what-is-terraform)
4. [Terraform Providers](#terraform-providers)
5. [Your First Terraform Configuration](#your-first-terraform-configuration)
6. [Hands-On Labs](#hands-on-labs)
7. [Checkpoint Quiz](#checkpoint-quiz)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Additional Resources](#additional-resources)
10. [Section 4: null_resource vs terraform_data & Provisioners](./4-null-resource-terraform-data/README.md)

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ **Explain** what Infrastructure as Code (IaC) is and why it matters
- ✅ **Describe** Terraform's role in the IaC ecosystem
- ✅ **Understand** the declarative vs imperative approach
- ✅ **Identify** Terraform's core components (providers, resources, state)
- ✅ **Write** your first Terraform configuration
- ✅ **Execute** basic Terraform commands (init, plan, apply, destroy)
- ✅ **Create** simple resources using the local provider
- ✅ **Troubleshoot** common beginner issues

---

## 🏗️ What is Infrastructure as Code (IaC)?

### Definition

**Infrastructure as Code (IaC)** is the practice of managing and provisioning infrastructure through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools.

### The Traditional Way (Manual)

Before IaC, infrastructure was managed manually:

```
1. Log into server console
2. Click through GUI menus
3. Fill out forms
4. Click "Create"
5. Document what you did (maybe)
6. Repeat for each environment
```

**Problems**:
- ❌ Time-consuming and error-prone
- ❌ Inconsistent across environments
- ❌ Hard to replicate
- ❌ No version control
- ❌ Difficult to audit
- ❌ Knowledge locked in people's heads

### The IaC Way (Automated)

With IaC, infrastructure is defined in code:

```hcl
# infrastructure.tf
resource "server" "web" {
  name   = "web-server-01"
  size   = "medium"
  region = "us-east-1"
}
```

**Benefits**:
- ✅ **Version Control**: Track changes with Git
- ✅ **Reproducibility**: Same code = same infrastructure
- ✅ **Consistency**: No configuration drift
- ✅ **Automation**: Deploy with one command
- ✅ **Documentation**: Code is the documentation
- ✅ **Collaboration**: Team can review and contribute
- ✅ **Testing**: Test infrastructure before deployment
- ✅ **Disaster Recovery**: Rebuild infrastructure quickly

### Real-World Examples

#### Example 1: E-Commerce Website

**Manual Approach** (Days):
1. Create 3 web servers manually
2. Configure load balancer through GUI
3. Set up database with wizard
4. Configure networking via console
5. Repeat for staging environment
6. Document everything (if you remember)

**IaC Approach** (Minutes):
```hcl
# main.tf
module "web_tier" {
  source = "./modules/web"
  count  = 3
}

module "database" {
  source = "./modules/database"
}

module "load_balancer" {
  source  = "./modules/lb"
  servers = module.web_tier[*].id
}
```

Run: `terraform apply`  
Result: Entire infrastructure deployed consistently

#### Example 2: Development Environments

**Problem**: Each developer needs their own environment

**IaC Solution**:
```hcl
# dev-environment.tf
module "dev_env" {
  source = "./modules/environment"
  
  developer = var.developer_name
  resources = {
    vm_count = 2
    storage  = "10GB"
    network  = "isolated"
  }
}
```

Each developer runs: `terraform apply -var="developer_name=alice"`  
Result: Identical environments for everyone

### Declarative vs Imperative

**Imperative** (How to do it):
```bash
# Step-by-step instructions
1. Create network
2. Wait for network to be ready
3. Create subnet in network
4. Create VM in subnet
5. If VM fails, rollback subnet
6. If subnet fails, rollback network
```

**Declarative** (What you want):
```hcl
# Desired end state
resource "network" "main" {
  name = "my-network"
}

resource "subnet" "main" {
  network = network.main.id
  cidr    = "10.0.1.0/24"
}

resource "vm" "main" {
  subnet = subnet.main.id
}
```

Terraform figures out the "how" automatically!

### IaC Tools Comparison

| Tool | Type | Language | Best For |
|------|------|----------|----------|
| **Terraform** | Declarative | HCL | Multi-cloud, infrastructure |
| Ansible | Imperative | YAML | Configuration management |
| CloudFormation | Declarative | JSON/YAML | AWS only |
| Pulumi | Declarative | Real languages | Developers who prefer code |
| Chef | Imperative | Ruby | Configuration management |
| Puppet | Declarative | Puppet DSL | Configuration management |

---

## 🚀 What is Terraform?

### Overview

**Terraform** is an open-source Infrastructure as Code tool created by HashiCorp that allows you to define, provision, and manage infrastructure across multiple cloud providers and services using a declarative configuration language.

### Current Version Information

- **Latest Stable**: Terraform 1.14+ (as of 2024)
- **Language**: HCL (HashiCorp Configuration Language)
- **License**: Business Source License (BSL) 1.1
- **Company**: HashiCorp
- **First Release**: 2014
- **Written In**: Go

### Key Features

#### 1. **Multi-Cloud Support**
```hcl
# Same syntax for different providers
resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t2.micro"
}

resource "azurerm_virtual_machine" "web" {
  name     = "web-vm"
  vm_size  = "Standard_B1s"
}

resource "google_compute_instance" "web" {
  name         = "web-instance"
  machine_type = "e2-micro"
}
```

#### 2. **Declarative Syntax**
You describe the desired state, Terraform handles the rest:
```hcl
resource "libvirt_domain" "vm" {
  name   = "my-vm"
  memory = "2048"
  vcpu   = 2
}
```

#### 3. **State Management**
Terraform tracks what it created:
```
terraform.tfstate
├── Resources created
├── Current configuration
└── Dependencies
```

#### 4. **Plan Before Apply**
Preview changes before making them:
```bash
$ terraform plan
Plan: 3 to add, 1 to change, 0 to destroy
```

#### 5. **Resource Graph**
Terraform understands dependencies:
```hcl
resource "network" "main" { }

resource "subnet" "main" {
  network_id = network.main.id  # Depends on network
}

resource "vm" "main" {
  subnet_id = subnet.main.id    # Depends on subnet
}
```

Terraform creates them in the correct order automatically!

### Terraform Workflow

```
┌─────────────┐
│   Write     │  1. Write .tf files
│   Code      │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  terraform  │  2. Initialize working directory
│    init     │     Download providers
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  terraform  │  3. Preview changes
│    plan     │     See what will happen
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  terraform  │  4. Apply changes
│   apply     │     Create infrastructure
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  terraform  │  5. Destroy (when done)
│  destroy    │     Clean up resources
└─────────────┘
```

### Why Terraform?

**Advantages**:
- ✅ **Cloud-Agnostic**: Works with 3000+ providers
- ✅ **Large Community**: Extensive modules and examples
- ✅ **Mature**: 10+ years of development
- ✅ **State Management**: Tracks infrastructure changes
- ✅ **Plan Preview**: See changes before applying
- ✅ **Modular**: Reusable components
- ✅ **Open Source**: Free to use

**Considerations**:
- ⚠️ **State File**: Must be managed carefully
- ⚠️ **Learning Curve**: HCL syntax to learn
- ⚠️ **No Rollback**: Can't undo applied changes automatically
- ⚠️ **License Change**: BSL 1.1 (not pure open source anymore)

### Terraform vs OpenTofu

**Note**: This training focuses on **Terraform**, not OpenTofu.

| Aspect | Terraform | OpenTofu |
|--------|-----------|----------|
| License | BSL 1.1 | MPL 2.0 (Open Source) |
| Maintainer | HashiCorp | Linux Foundation |
| Compatibility | Official | Fork of Terraform 1.5 |
| Features | Latest features | Community-driven |

---

## 🔌 Terraform Providers

### What is a Provider?

A **provider** is a plugin that enables Terraform to interact with an API. Providers are responsible for understanding API interactions and exposing resources.

### Provider Architecture

```
┌──────────────────────────────────────┐
│         Terraform Core               │
│  (HCL Parser, State Manager, etc.)   │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│         Provider Plugin              │
│  (AWS, Azure, Libvirt, etc.)         │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│         Target API                   │
│  (Cloud Provider, Service, etc.)     │
└──────────────────────────────────────┘
```

### Popular Providers

| Provider | Use Case | Resources |
|----------|----------|-----------|
| **aws** | Amazon Web Services | EC2, S3, RDS, VPC, etc. |
| **azurerm** | Microsoft Azure | VMs, Storage, Networks |
| **google** | Google Cloud Platform | Compute, Storage, etc. |
| **kubernetes** | Kubernetes clusters | Pods, Services, etc. |
| **docker** | Docker containers | Containers, Images |
| **local** | Local files | Files, directories |
| **libvirt** | KVM/QEMU VMs | Domains, Networks, Volumes |

### Provider Configuration

#### Basic Provider Block

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "local" {
  # Provider-specific configuration (if needed)
}
```

#### Provider with Configuration

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Environment = "Training"
      ManagedBy   = "Terraform"
    }
  }
}
```

### The Libvirt Provider (Our Focus)

For this training, we'll primarily use the **Libvirt provider** to create local VMs:

```hcl
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}
```

**Why Libvirt?**
- ✅ **Free**: No cloud costs
- ✅ **Local**: Runs on your machine
- ✅ **Fast**: Quick feedback loop
- ✅ **Realistic**: Real VMs, not simulations
- ✅ **Transferable**: Concepts apply to any provider

### Provider Versioning

**Semantic Versioning**: `MAJOR.MINOR.PATCH`

```hcl
# Exact version
version = "2.5.1"

# Minimum version
version = ">= 2.5.0"

# Version range
version = ">= 2.5.0, < 3.0.0"

# Pessimistic constraint (recommended)
version = "~> 2.5"  # Allows 2.5.x, but not 3.0
```

**Best Practice**: Use pessimistic constraints (`~>`) to allow patch updates but prevent breaking changes.

---

## 📝 Your First Terraform Configuration

### Terraform File Structure

```
project/
├── main.tf           # Main configuration
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── terraform.tfvars  # Variable values
└── .terraform/       # Provider plugins (auto-generated)
```

For beginners, start with just `main.tf`.

### Basic Terraform Blocks

#### 1. Terraform Block (Configuration)

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
```

**Purpose**: Configure Terraform behavior and required providers

#### 2. Provider Block (Provider Configuration)

```hcl
provider "local" {
  # Provider-specific settings
}
```

**Purpose**: Configure the provider plugin

#### 3. Resource Block (Infrastructure)

```hcl
resource "local_file" "example" {
  content  = "Hello, Terraform!"
  filename = "${path.module}/hello.txt"
}
```

**Purpose**: Define infrastructure resources to create

### Resource Block Anatomy

```hcl
resource "PROVIDER_TYPE" "NAME" {
  argument1 = "value1"
  argument2 = "value2"
  
  nested_block {
    nested_arg = "value"
  }
}
```

- **PROVIDER**: Provider name (e.g., `local`, `aws`, `libvirt`)
- **TYPE**: Resource type (e.g., `file`, `instance`, `domain`)
- **NAME**: Unique name for this resource in your config
- **Arguments**: Resource-specific settings

### Example: Creating Local Files

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "local" {}

resource "local_file" "hello" {
  content  = "Hello, Terraform!"
  filename = "${path.module}/hello.txt"
}

resource "local_file" "config" {
  content  = <<-EOT
    # Configuration File
    app_name = "my-app"
    version  = "1.0.0"
  EOT
  filename = "${path.module}/config.txt"
}
```

### Special Expressions

#### `${path.module}`

Returns the filesystem path of the current module:

```hcl
filename = "${path.module}/hello.txt"
# Creates file in the same directory as your .tf file
```

#### Heredoc Syntax (`<<-EOT`)

For multi-line strings:

```hcl
content = <<-EOT
  Line 1
  Line 2
  Line 3
EOT
```

---

## 🧪 Hands-On Labs

### Lab 1: Hello World with local_file

**Objective**: Create your first Terraform configuration and resource

**Duration**: 15 minutes

#### Step 1: Create Project Directory

```bash
# Create and enter project directory
mkdir ~/terraform-hello-world
cd ~/terraform-hello-world
```

**PowerShell**:
```powershell
New-Item -ItemType Directory -Path "$HOME\terraform-hello-world"
cd "$HOME\terraform-hello-world"
```

#### Step 2: Create main.tf

Create a file named `main.tf` with the following content:

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

provider "local" {}

resource "local_file" "hello" {
  content  = "Hello, Terraform! This is my first infrastructure as code."
  filename = "${path.module}/hello.txt"
}

resource "local_file" "info" {
  content  = <<-EOT
    Terraform Training
    ==================
    Course: TF-101
    Topic: Introduction to IaC
    Date: ${timestamp()}
  EOT
  filename = "${path.module}/info.txt"
}
```

#### Step 3: Initialize Terraform

```bash
terraform init
```

**Expected Output**:
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/local versions matching "~> 2.5"...
- Installing hashicorp/local v2.5.1...
- Installed hashicorp/local v2.5.1

Terraform has been successfully initialized!
```

**What happened?**
- Downloaded the `local` provider plugin
- Created `.terraform/` directory
- Created `.terraform.lock.hcl` file

#### Step 4: Preview Changes

```bash
terraform plan
```

**Expected Output**:
```
Terraform will perform the following actions:

  # local_file.hello will be created
  + resource "local_file" "hello" {
      + content  = "Hello, Terraform! This is my first infrastructure as code."
      + filename = "./hello.txt"
      + id       = (known after apply)
    }

  # local_file.info will be created
  + resource "local_file" "info" {
      + content  = <<-EOT
            Terraform Training
            ==================
            Course: TF-101
            Topic: Introduction to IaC
            Date: 2024-02-26T12:00:00Z
        EOT
      + filename = "./info.txt"
      + id       = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

**What does this mean?**
- `+` means "will be created"
- `2 to add` means 2 new resources
- `0 to change` means no existing resources modified
- `0 to destroy` means no resources deleted

#### Step 5: Apply Changes

```bash
terraform apply
```

You'll be prompted to confirm:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Type `yes` and press Enter.

**Expected Output**:
```
local_file.hello: Creating...
local_file.info: Creating...
local_file.hello: Creation complete after 0s [id=...]
local_file.info: Creation complete after 0s [id=...]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

#### Step 6: Verify Files Created

```bash
ls -la
cat hello.txt
cat info.txt
```

**PowerShell**:
```powershell
Get-ChildItem
Get-Content hello.txt
Get-Content info.txt
```

You should see:
- `hello.txt` with your message
- `info.txt` with training information
- `terraform.tfstate` (Terraform's state file)

#### Step 7: Inspect State

```bash
terraform show
```

This displays the current state of your infrastructure.

#### Step 8: Destroy Resources

```bash
terraform destroy
```

Confirm with `yes`.

**Expected Output**:
```
local_file.hello: Destroying... [id=...]
local_file.info: Destroying... [id=...]
local_file.hello: Destruction complete after 0s
local_file.info: Destruction complete after 0s

Destroy complete! Resources: 2 destroyed.
```

Verify files are deleted:
```bash
ls -la
# hello.txt and info.txt should be gone
```

**🎉 Congratulations!** You've completed your first Terraform workflow!

---

### Lab 2: Understanding terraform_data

**Objective**: Learn about the special `terraform_data` resource

**Duration**: 10 minutes

#### What is terraform_data?

`terraform_data` is a built-in resource that:
- Stores arbitrary values
- Triggers provisioners
- Manages lifecycle without creating actual infrastructure

#### Example: Using terraform_data

Create `terraform-data-example.tf`:

```hcl
terraform {
  required_version = ">= 1.14"
}

resource "terraform_data" "example" {
  input = "Hello from terraform_data!"
  
  provisioner "local-exec" {
    command = "echo '${self.input}' > output.txt"
  }
}

output "data_value" {
  value = terraform_data.example.input
}
```

Run the workflow:
```bash
terraform init
terraform apply
cat output.txt
```

#### When to Use terraform_data

**Good Use Cases**:
- Triggering actions based on input changes
- Storing computed values
- Managing lifecycle of non-infrastructure resources

**Not Recommended For**:
- Creating actual infrastructure (use proper resources)
- Complex provisioning (use configuration management tools)

---

### Lab 3: Multiple Resources with Dependencies

**Objective**: Create resources that depend on each other

**Duration**: 15 minutes

Create `dependencies.tf`:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "local" {}

# First resource: Create a directory
resource "local_file" "directory_marker" {
  content  = "This directory contains Terraform-managed files"
  filename = "${path.module}/managed/README.txt"
}

# Second resource: Create a file in that directory
resource "local_file" "app_config" {
  content  = <<-EOT
    app_name = "my-application"
    version  = "1.0.0"
    environment = "development"
  EOT
  filename = "${path.module}/managed/app-config.txt"
  
  # Explicit dependency
  depends_on = [local_file.directory_marker]
}

# Third resource: Create another file referencing the first
resource "local_file" "summary" {
  content  = "Total files managed: 3"
  filename = "${path.module}/managed/summary.txt"
  
  depends_on = [
    local_file.directory_marker,
    local_file.app_config
  ]
}
```

Run:
```bash
terraform init
terraform apply
```

**Observe**: Terraform creates resources in the correct order!

---

## ✅ Checkpoint Quiz

Test your understanding of the concepts covered in this module.

### Question 1: IaC Fundamentals

**What is the primary benefit of Infrastructure as Code?**

A) It makes infrastructure faster  
B) It makes infrastructure cheaper  
C) It makes infrastructure reproducible and version-controlled  
D) It eliminates the need for infrastructure engineers

<details>
<summary>Click to reveal answer</summary>

**Answer: C**

IaC's primary benefit is reproducibility and version control. While it can lead to faster deployments and potentially cost savings, the core value is in treating infrastructure like software code that can be versioned, reviewed, and consistently deployed.
</details>

### Question 2: Declarative vs Imperative

**Which statement best describes Terraform's approach?**

A) Imperative - you specify step-by-step instructions  
B) Declarative - you specify the desired end state  
C) Procedural - you write functions to create infrastructure  
D) Object-oriented - you create classes for infrastructure

<details>
<summary>Click to reveal answer</summary>

**Answer: B**

Terraform uses a declarative approach. You describe what you want (the desired state), and Terraform figures out how to achieve it. You don't write step-by-step instructions.
</details>

### Question 3: Terraform Workflow

**What is the correct order of Terraform commands for a typical workflow?**

A) apply → init → plan → destroy  
B) init → apply → plan → destroy  
C) init → plan → apply → destroy  
D) plan → init → apply → destroy

<details>
<summary>Click to reveal answer</summary>

**Answer: C**

The correct workflow is:
1. `init` - Initialize and download providers
2. `plan` - Preview changes
3. `apply` - Create/modify infrastructure
4. `destroy` - Clean up (when done)
</details>

### Question 4: Providers

**What is a Terraform provider?**

A) A company that hosts Terraform  
B) A plugin that enables Terraform to interact with an API  
C) A person who writes Terraform code  
D) A cloud service that runs Terraform

<details>
<summary>Click to reveal answer</summary>

**Answer: B**

A provider is a plugin that enables Terraform to interact with APIs. Providers are responsible for understanding API interactions and exposing resources that can be managed with Terraform.
</details>

### Question 5: Resource Blocks

**In the resource block `resource "local_file" "example" {}`, what does "example" represent?**

A) The provider name  
B) The resource type  
C) The local name for this resource in your configuration  
D) The filename to create

<details>
<summary>Click to reveal answer</summary>

**Answer: C**

"example" is the local name you give to this resource in your configuration. It's used to reference this resource elsewhere in your code. The provider is "local" and the type is "file".
</details>

### Question 6: State Management

**What is the purpose of the terraform.tfstate file?**

A) To store your Terraform configuration  
B) To track what infrastructure Terraform has created  
C) To store provider credentials  
D) To cache downloaded providers

<details>
<summary>Click to reveal answer</summary>

**Answer: B**

The state file tracks what infrastructure Terraform has created and its current configuration. This allows Terraform to know what exists and what needs to be changed on subsequent runs.
</details>

### Question 7: Best Practices

**Which of the following is a best practice when using provisioners?**

A) Use provisioners for all infrastructure creation  
B) Avoid provisioners when possible; use purpose-built resources instead  
C) Always use local-exec provisioners  
D) Provisioners should be your first choice for any task

<details>
<summary>Click to reveal answer</summary>

**Answer: B**

Provisioners should be avoided when possible. They make configurations less portable, harder to maintain, and can break Terraform's idempotency. Use purpose-built resources or configuration management tools instead.
</details>

### Question 8: Version Constraints

**What does the version constraint `~> 2.5` mean?**

A) Exactly version 2.5  
B) Version 2.5 or higher  
C) Version 2.5.x (allows patch updates, not minor updates)  
D) Any version between 2.0 and 2.9

<details>
<summary>Click to reveal answer</summary>

**Answer: C**

The `~>` operator is a pessimistic constraint. `~> 2.5` means "2.5.x" - it allows patch version updates (2.5.0, 2.5.1, 2.5.2, etc.) but not minor version updates (2.6.0 would not be allowed).
</details>

---

## 🔧 Troubleshooting Guide

Common issues beginners encounter and how to solve them.

### Issue 1: "terraform: command not found"

**Symptom**:
```bash
$ terraform version
bash: terraform: command not found
```

**Cause**: Terraform is not installed or not in your PATH.

**Solution**:

**Linux/macOS**:
```bash
# Check if Terraform is installed
which terraform

# If not installed, install it
# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Windows**:
```powershell
# Install with Chocolatey
choco install terraform

# Or download from https://www.terraform.io/downloads
```

---

### Issue 2: "Error: Failed to query available provider packages"

**Symptom**:
```
Error: Failed to query available provider packages

Could not retrieve the list of available versions for provider
hashicorp/local: no available releases match the given constraints
```

**Cause**: Network issues or incorrect provider source.

**Solution**:

1. **Check internet connection**:
```bash
ping registry.terraform.io
```

2. **Verify provider source**:
```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"  # Correct format
      version = "~> 2.5"
    }
  }
}
```

3. **Clear provider cache**:
```bash
rm -rf .terraform
terraform init
```

---

### Issue 3: "Error: Inconsistent dependency lock file"

**Symptom**:
```
Error: Inconsistent dependency lock file

The following dependency selections recorded in the lock file are
inconsistent with the current configuration:
  - provider registry.terraform.io/hashicorp/local
```

**Cause**: Provider version changed or lock file is outdated.

**Solution**:

```bash
# Update lock file
terraform init -upgrade

# Or delete and recreate
rm .terraform.lock.hcl
terraform init
```

---

### Issue 4: "Error: Reference to undeclared resource"

**Symptom**:
```
Error: Reference to undeclared resource

A managed resource "local_file" "example" has not been declared in the
root module.
```

**Cause**: Typo in resource name or resource doesn't exist.

**Solution**:

Check your resource names match:
```hcl
# Declaration
resource "local_file" "example" {
  content  = "Hello"
  filename = "hello.txt"
}

# Reference (must match exactly)
output "file_id" {
  value = local_file.example.id  # Must be "example", not "exmaple"
}
```

---

### Issue 5: "Error: Unsupported argument"

**Symptom**:
```
Error: Unsupported argument

An argument named "contents" is not expected here. Did you mean "content"?
```

**Cause**: Typo in argument name.

**Solution**:

Check the provider documentation for correct argument names:
```hcl
# Wrong
resource "local_file" "example" {
  contents = "Hello"  # Wrong: "contents"
  filename = "hello.txt"
}

# Correct
resource "local_file" "example" {
  content = "Hello"   # Correct: "content"
  filename = "hello.txt"
}
```

---

### Issue 6: "Error: Missing required argument"

**Symptom**:
```
Error: Missing required argument

The argument "filename" is required, but no definition was found.
```

**Cause**: Required argument not provided.

**Solution**:

Add all required arguments:
```hcl
resource "local_file" "example" {
  content  = "Hello"
  filename = "hello.txt"  # Required!
}
```

Check provider documentation for required vs optional arguments.

---

### Issue 7: Permission Denied

**Symptom**:
```
Error: Error creating file: open /etc/config.txt: permission denied
```

**Cause**: Trying to write to a protected location.

**Solution**:

1. **Use a writable location**:
```hcl
# Instead of /etc/config.txt
filename = "${path.module}/config.txt"
```

2. **Or run with appropriate permissions** (not recommended for learning):
```bash
sudo terraform apply
```

---

### Issue 8: "Error: Invalid character"

**Symptom**:
```
Error: Invalid character

This character is not used within the language.
```

**Cause**: Syntax error in HCL code.

**Solution**:

Common syntax issues:
```hcl
# Wrong: Missing quotes
resource "local_file" "example" {
  content = Hello  # Wrong
}

# Correct: Use quotes for strings
resource "local_file" "example" {
  content = "Hello"  # Correct
}

# Wrong: Missing equals sign
resource "local_file" "example" {
  content "Hello"  # Wrong
}

# Correct: Use equals sign
resource "local_file" "example" {
  content = "Hello"  # Correct
}
```

---

### Issue 9: State File Locked

**Symptom**:
```
Error: Error acquiring the state lock

Error message: resource temporarily unavailable
Lock Info:
  ID:        abc123...
  Operation: OperationTypeApply
  Who:       user@hostname
```

**Cause**: Another Terraform process is running or crashed.

**Solution**:

1. **Wait for other process to finish**
2. **If process crashed, force unlock**:
```bash
terraform force-unlock abc123
```

⚠️ **Warning**: Only force unlock if you're sure no other process is running!

---

### Issue 10: "No changes. Your infrastructure matches the configuration."

**Symptom**:
```
No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

**Cause**: This is not an error! Your infrastructure is already in the desired state.

**Solution**: No action needed. This means Terraform is working correctly.

---

### General Troubleshooting Tips

1. **Read error messages carefully** - They usually tell you exactly what's wrong
2. **Check syntax** - Use `terraform fmt` to format code and catch syntax errors
3. **Validate configuration** - Use `terraform validate` before applying
4. **Check provider documentation** - Verify argument names and types
5. **Start simple** - If stuck, create a minimal example that works, then add complexity
6. **Use version control** - Commit working code so you can revert if needed
7. **Check Terraform version** - Some features require specific versions

---

## 📚 Additional Resources

### Official Documentation

- **Terraform Documentation**: https://www.terraform.io/docs
- **Terraform Registry**: https://registry.terraform.io/
- **HCL Syntax**: https://www.terraform.io/language/syntax
- **Local Provider**: https://registry.terraform.io/providers/hashicorp/local/latest/docs

### Learning Resources

- **HashiCorp Learn**: https://learn.hashicorp.com/terraform
- **Terraform Best Practices**: https://www.terraform-best-practices.com/
- **Terraform Style Guide**: https://www.terraform.io/language/syntax/style

### Community

- **Terraform Discuss**: https://discuss.hashicorp.com/c/terraform-core
- **Terraform GitHub**: https://github.com/hashicorp/terraform
- **Stack Overflow**: Tag `terraform`

### Next Steps

After completing TF-101, continue to:
- **[TF-102: Variables, Loops & Functions](../TF-102-variables-loops/README.md)**
- **[TF-103: Infrastructure Resources](../TF-103-infrastructure/README.md)**
- **[TF-104: State Management & CLI](../TF-104-state-cli/README.md)**

---

## 🎓 Summary

In this module, you learned:

✅ **Infrastructure as Code (IaC)** - Managing infrastructure through code
✅ **Terraform Basics** - Declarative IaC tool for multi-cloud
✅ **Providers** - Plugins that enable Terraform to interact with APIs
✅ **Resources** - Infrastructure components defined in code
✅ **Terraform Workflow** - init → plan → apply → destroy
✅ **Hands-On Practice** - Created your first Terraform configurations
✅ **Troubleshooting** - Common issues and solutions
✅ **`terraform_data` vs `null_resource`** - Modern vs legacy patterns for side effects
✅ **Provisioners** - When and how to use `local-exec` (and when not to)

**You're now ready to move on to TF-102: Variables, Loops & Functions!**

---

### 📂 Additional Sections in TF-101

| Section | Topic | Directory |
|---------|-------|-----------|
| Section 4 | `null_resource` vs `terraform_data` & Provisioners | [`4-null-resource-terraform-data/`](./4-null-resource-terraform-data/) |

---

**Course**: TF-100 Terraform Fundamentals
**Module**: TF-101
**Version**: 1.1
**Last Updated**: 2026-02-28

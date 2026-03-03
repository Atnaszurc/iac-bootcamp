# TF-305 Section 3: Remote State Sharing

**Course**: TF-305 Workspaces & Remote State  
**Section**: 3 of 4  
**Duration**: 20 minutes  
**Prerequisites**: Section 2 (Remote Backends)  
**Terraform Version**: Any

---

## 📋 Overview

Large infrastructure is typically split across multiple Terraform configurations — networking in one, compute in another, databases in a third. The `terraform_remote_state` data source allows one configuration to read the **outputs** of another, enabling loose coupling between infrastructure layers.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Use `terraform_remote_state` to read outputs from another configuration
- ✅ Design a layered infrastructure architecture
- ✅ Understand what to expose via remote state vs module outputs
- ✅ Identify when remote state coupling becomes a problem
- ✅ Apply best practices for remote state sharing

---

## 🔑 The Pattern: Layered Infrastructure

```
Layer 1: Networking (networking/)
├── Creates: VPC, subnets, security groups
└── Outputs: network_id, subnet_ids, security_group_id
         ↓ (consumed via terraform_remote_state)
Layer 2: Compute (compute/)
├── Reads: network_id, subnet_ids from networking
├── Creates: VMs, load balancers
└── Outputs: vm_ips, lb_dns_name
         ↓ (consumed via terraform_remote_state)
Layer 3: Application (application/)
├── Reads: lb_dns_name from compute
└── Creates: DNS records, monitoring
```

---

## 📚 `terraform_remote_state` Data Source

### Producer Configuration (networking/)

```hcl
# networking/main.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "networking.terraform.tfstate"
  }
}

resource "libvirt_network" "main" {
  name      = "main-network"
  mode      = "nat"
  addresses = ["10.0.0.0/24"]
}
```

```hcl
# networking/outputs.tf — these are what consumers can read
output "network_id" {
  description = "ID of the main network"
  value       = libvirt_network.main.id
}

output "network_name" {
  description = "Name of the main network"
  value       = libvirt_network.main.name
}

output "network_cidr" {
  description = "CIDR block of the main network"
  value       = "10.0.0.0/24"
}
```

### Consumer Configuration (compute/)

```hcl
# compute/main.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "compute.terraform.tfstate"
  }
}

# Read outputs from the networking configuration
data "terraform_remote_state" "networking" {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "networking.terraform.tfstate"
  }
}

# Use the network ID from the networking configuration
resource "libvirt_domain" "app" {
  name   = "app-server"
  memory = 1024

  network_interface {
    network_id = data.terraform_remote_state.networking.outputs.network_id
  }
}
```

---

## 📚 Local Example (Using Local Backend)

For learning purposes, you can use the local backend to practice remote state sharing without cloud infrastructure:

### Producer (`networking/`)

```hcl
# networking/main.tf
terraform {
  backend "local" {
    path = "../shared-state/networking.tfstate"
  }
}

resource "local_file" "network_config" {
  content  = "network_id = net-001\ncidr = 10.0.0.0/24"
  filename = "${path.module}/network.conf"
}

output "network_id" {
  value = "net-001"
}

output "network_cidr" {
  value = "10.0.0.0/24"
}
```

### Consumer (`compute/`)

```hcl
# compute/main.tf
terraform {
  backend "local" {
    path = "../shared-state/compute.tfstate"
  }
}

data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "../shared-state/networking.tfstate"
  }
}

resource "local_file" "vm_config" {
  content = <<-EOT
    # VM Configuration
    network_id   = ${data.terraform_remote_state.networking.outputs.network_id}
    network_cidr = ${data.terraform_remote_state.networking.outputs.network_cidr}
    vm_name      = app-server
  EOT
  filename = "${path.module}/vm.conf"
}
```

---

## 📚 What to Expose via Remote State

### ✅ Good Candidates for Remote State Outputs

```hcl
# IDs and names that other configs need to reference
output "network_id"       { value = libvirt_network.main.id }
output "security_group_id" { value = libvirt_network.main.id }
output "subnet_ids"       { value = [for s in libvirt_network.subnets : s.id] }

# Connection strings (mark sensitive if they contain secrets)
output "db_endpoint"      { value = "db.internal:5432" }
output "lb_dns_name"      { value = "lb.example.com" }
```

### ❌ Bad Candidates for Remote State Outputs

```hcl
# Don't expose internal implementation details
output "all_resource_arns" { value = ... }  # Too much coupling

# Don't expose sensitive values via remote state
output "db_password" {
  value     = var.db_password
  sensitive = true
  # ❌ Even with sensitive=true, the value is in state — use a secrets manager instead
}
```

---

## ⚠️ When Remote State Coupling Becomes a Problem

```
❌ TIGHT COUPLING ANTI-PATTERN:
Application config reads 15 outputs from networking
Application config reads 8 outputs from compute
Application config reads 12 outputs from database
→ Changing any upstream config can break the application config
→ Hard to test in isolation
→ Deployment order becomes critical

✅ LOOSE COUPLING BEST PRACTICE:
- Expose only what consumers actually need
- Use stable, well-defined output contracts
- Consider modules for tightly related resources
- Document what each output is for
```

---

## 🧪 Hands-On Lab

### Lab: Remote State Sharing with Local Backend

```bash
mkdir tf305-remote-state
cd tf305-remote-state
mkdir networking compute shared-state
```

**Step 1**: Create `networking/main.tf`:

```hcl
terraform {
  required_version = ">= 1.14"
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
  backend "local" {
    path = "../shared-state/networking.tfstate"
  }
}

resource "local_file" "network_config" {
  content  = "network_id = net-001\ncidr = 10.0.0.0/24"
  filename = "${path.module}/network.conf"
}

output "network_id"   { value = "net-001" }
output "network_cidr" { value = "10.0.0.0/24" }
```

**Step 2**: Apply networking:

```bash
cd networking
terraform init
terraform apply -auto-approve
cd ..
```

**Step 3**: Create `compute/main.tf`:

```hcl
terraform {
  required_version = ">= 1.14"
  required_providers {
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
  backend "local" {
    path = "../shared-state/compute.tfstate"
  }
}

data "terraform_remote_state" "networking" {
  backend = "local"
  config  = { path = "../shared-state/networking.tfstate" }
}

resource "local_file" "vm_config" {
  content = <<-EOT
    network_id   = ${data.terraform_remote_state.networking.outputs.network_id}
    network_cidr = ${data.terraform_remote_state.networking.outputs.network_cidr}
    vm_name      = app-server
  EOT
  filename = "${path.module}/vm.conf"
}
```

**Step 4**: Apply compute:

```bash
cd compute
terraform init
terraform apply -auto-approve
cat vm.conf  # Shows values from networking state
```

---

## ✅ Checkpoint Quiz

**Question 1**: What does `terraform_remote_state` allow you to do?
- A) Copy state from one backend to another
- B) Read the outputs of another Terraform configuration
- C) Merge two state files together
- D) Run Terraform in another directory

<details>
<summary>Answer</summary>
**B) Read the outputs of another Terraform configuration** — `terraform_remote_state` is a data source that reads the `outputs` block from another configuration's state file. Only outputs are accessible — not the full resource details.
</details>

---

**Question 2**: What is the recommended alternative to `terraform_remote_state` for tightly related resources?
- A) Copy-paste the resource definitions
- B) Use Terraform modules
- C) Use environment variables
- D) Use `depends_on` across configurations

<details>
<summary>Answer</summary>
**B) Use Terraform modules** — If resources are tightly related and always deployed together, they should be in the same configuration or module. `terraform_remote_state` is for loosely coupled, independently deployed infrastructure layers.
</details>

---

## 📚 Key Takeaways

| Concept | Detail |
|---------|--------|
| `terraform_remote_state` | Data source that reads outputs from another config's state |
| Only outputs are accessible | Cannot read resource attributes directly |
| Layered architecture | Networking → Compute → Application |
| Loose coupling | Expose only what consumers need |
| Alternative | Use modules for tightly related resources |

---

## 🔗 Next Steps

- **Next**: [Section 4: HCP Terraform State](../4-hcp-terraform-state/README.md) — the recommended state backend
- **Previous**: [Section 2: Remote Backends](../2-remote-backends/README.md)
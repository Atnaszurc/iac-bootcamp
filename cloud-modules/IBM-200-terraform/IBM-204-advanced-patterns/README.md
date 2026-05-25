# IBM-204: IBM Cloud Advanced Patterns

**Course**: IBM-200 IBM Cloud with Terraform  
**Module**: IBM-204  
**Duration**: 2 hours  
**Prerequisites**: IBM-201, IBM-202, IBM-203  
**Difficulty**: Advanced

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Architecture Overview](#architecture-overview)
4. [Multi-Tier Application Pattern](#multi-tier-application-pattern)
5. [Load Balancer Configuration](#load-balancer-configuration)
6. [Data Sources and Dependencies](#data-sources-and-dependencies)
7. [Module Composition](#module-composition)
8. [Terraform Workspaces](#terraform-workspaces)
9. [Remote State Management](#remote-state-management)
10. [Best Practices](#best-practices)
11. [Hands-On Labs](#hands-on-labs)
12. [Troubleshooting](#troubleshooting)
13. [Checkpoint Quiz](#checkpoint-quiz)
14. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This advanced course integrates all concepts from IBM-201, IBM-202, and IBM-203 into a production-ready, multi-tier application architecture. You'll learn how to compose infrastructure modules, manage dependencies, and apply enterprise patterns.

### What You'll Build

A complete 3-tier web application infrastructure:
- **Web Tier**: Load balancer + web servers across multiple zones
- **Application Tier**: Application servers with auto-scaling capability
- **Data Tier**: Database instances with encrypted storage
- **Supporting Services**: Key Protect, COS, monitoring, and logging

### Course Structure

```text
IBM-204-advanced-patterns/
├── README.md                          # This file
└── example/
    ├── main.tf                        # Integrated multi-tier architecture
    ├── variables.tf                   # Input variables
    ├── outputs.tf                     # Comprehensive outputs
    └── tests/
        └── basic.tftest.hcl           # Terraform tests with mocked provider data
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Design Multi-Tier Architectures**
   - Plan VPC architecture for production workloads
   - Design subnet layouts across availability zones
   - Implement proper network segmentation

2. **Implement Load Balancing**
   - Configure IBM Cloud Application Load Balancer
   - Set up backend pools and health checks
   - Distribute traffic across zones

3. **Manage Complex Dependencies**
   - Use `depends_on` effectively
   - Leverage data sources for existing resources
   - Handle circular dependencies

4. **Apply Enterprise Patterns**
   - Implement defense-in-depth security
   - Use encryption at rest and in transit
   - Enable comprehensive monitoring

5. **Compose Infrastructure Modules**
   - Break infrastructure into reusable components
   - Manage module dependencies
   - Version and test modules

---

## 🏗️ Architecture Overview

### High-Level Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                         IBM Cloud VPC                            │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Public Subnet (Zone 1)                   │ │
│  │  ┌──────────────┐         ┌──────────────┐                 │ │
│  │  │ Load Balancer│────────▶│  Web Server  │                 │ │
│  │  │   (Public)   │         │   (Private)  │                 │ │
│  │  └──────────────┘         └──────────────┘                 │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Private Subnet (Zone 1)                   │ │
│  │  ┌──────────────┐         ┌──────────────┐                 │ │
│  │  │  App Server  │────────▶│   Database   │                 │ │
│  │  │              │         │  (Encrypted) │                 │ │
│  │  └──────────────┘         └──────────────┘                 │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Public Subnet (Zone 2)                   │ │
│  │  ┌──────────────┐         ┌──────────────┐                 │ │
│  │  │ Load Balancer│────────▶│  Web Server  │                 │ │
│  │  │   (Backup)   │         │   (Private)  │                 │ │
│  │  └──────────────┘         └──────────────┘                 │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Private Subnet (Zone 2)                   │ │
│  │  ┌──────────────┐         ┌──────────────┐                 │ │
│  │  │  App Server  │────────▶│   Database   │                 │ │
│  │  │              │         │  (Replica)   │                 │ │
│  │  └──────────────┘         └──────────────┘                 │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

External Services:
├── IBM Key Protect (Encryption Keys)
├── Cloud Object Storage (Backups, Logs)
└── Activity Tracker (Audit Logs)
```

### Network Architecture

```text
VPC: 10.240.0.0/16

Zone 1:
├── Public Subnet:  10.240.0.0/24  (Web Tier)
└── Private Subnet: 10.240.1.0/24  (App + DB Tier)

Zone 2:
├── Public Subnet:  10.240.2.0/24  (Web Tier)
└── Private Subnet: 10.240.3.0/24  (App + DB Tier)

Zone 3 (Reserved):
├── Public Subnet:  10.240.4.0/24  (Future)
└── Private Subnet: 10.240.5.0/24  (Future)
```

### Security Architecture

```text
Security Groups:
├── Load Balancer SG
│   ├── Inbound: 80, 443 from 0.0.0.0/0
│   └── Outbound: All
├── Web Tier SG
│   ├── Inbound: 80, 443 from LB SG
│   ├── Inbound: 22 from Bastion SG
│   └── Outbound: All
├── App Tier SG
│   ├── Inbound: 8080 from Web SG
│   ├── Inbound: 22 from Bastion SG
│   └── Outbound: All
└── Database Tier SG
    ├── Inbound: 5432 from App SG
    ├── Inbound: 22 from Bastion SG
    └── Outbound: All
```

---

## 🌐 Multi-Tier Application Pattern

### Tier Separation

**Why separate tiers?**
- **Security**: Limit blast radius of compromises
- **Scalability**: Scale tiers independently
- **Maintainability**: Update tiers without affecting others
- **Compliance**: Meet regulatory requirements

### Web Tier

**Purpose**: Handle HTTP/HTTPS traffic, serve static content, SSL termination

**Components**:
- Load balancer (public-facing)
- Web server instances (private)
- Public subnets with internet gateway
- Security group allowing 80/443

**Best Practices**:
- Use at least 2 zones for high availability
- Keep web servers in private subnets behind load balancer
- Use auto-scaling for traffic spikes
- Implement health checks

### Application Tier

**Purpose**: Business logic, API endpoints, application processing

**Components**:
- Application server instances
- Private subnets (no direct internet access)
- Security group allowing traffic from web tier only

**Best Practices**:
- Deploy across multiple zones
- Use private networking only
- Implement connection pooling to database
- Enable application-level monitoring

### Data Tier

**Purpose**: Persistent data storage, database services

**Components**:
- Database instances
- Private subnets (most restricted)
- Security group allowing traffic from app tier only
- Encrypted volumes with Key Protect

**Best Practices**:
- Use encrypted storage
- Implement regular backups to COS
- Deploy read replicas across zones
- Restrict network access tightly

---

## ⚖️ Load Balancer Configuration

### IBM Cloud Application Load Balancer

The Application Load Balancer (ALB) provides:
- **Layer 7 routing**: HTTP/HTTPS traffic distribution
- **SSL termination**: Offload SSL processing from backends
- **Health checks**: Automatic unhealthy instance removal
- **Multi-zone**: Distribute across availability zones

### Load Balancer Components

```hcl
# Load Balancer
resource "ibm_is_lb" "web_lb" {
  name    = "web-load-balancer"
  subnets = [subnet_zone1_id, subnet_zone2_id]
  type    = "public"  # or "private"
}

# Backend Pool
resource "ibm_is_lb_pool" "web_pool" {
  lb                 = ibm_is_lb.web_lb.id
  name               = "web-backend-pool"
  protocol           = "http"
  algorithm          = "round_robin"
  health_delay       = 5
  health_retries     = 2
  health_timeout     = 2
  health_type        = "http"
  health_monitor_url = "/health"
}

# Pool Members
resource "ibm_is_lb_pool_member" "web_member_1" {
  lb             = ibm_is_lb.web_lb.id
  pool           = ibm_is_lb_pool.web_pool.id
  port           = 80
  target_address = instance_1_private_ip
}

# Listener
resource "ibm_is_lb_listener" "web_listener" {
  lb           = ibm_is_lb.web_lb.id
  port         = 80
  protocol     = "http"
  default_pool = ibm_is_lb_pool.web_pool.id
}
```

### Health Check Configuration

**Critical for production**:
- **health_delay**: Seconds between health checks (5-10 recommended)
- **health_retries**: Failed checks before marking unhealthy (2-3 recommended)
- **health_timeout**: Seconds to wait for response (2-5 recommended)
- **health_monitor_url**: Endpoint to check (e.g., `/health`, `/ping`)

### Load Balancing Algorithms

| Algorithm | Use Case |
|-----------|----------|
| **round_robin** | Equal distribution, stateless apps |
| **weighted_round_robin** | Unequal capacity instances |
| **least_connections** | Long-lived connections |

---

## 📊 Data Sources and Dependencies

### Using Data Sources

Data sources query existing infrastructure:

```hcl
# Query existing VPC
data "ibm_is_vpc" "existing_vpc" {
  name = "production-vpc"
}

# Query existing subnet
data "ibm_is_subnet" "existing_subnet" {
  name = "production-subnet-zone1"
}

# Use in new resources
resource "ibm_is_instance" "app_server" {
  vpc    = data.ibm_is_vpc.existing_vpc.id
  subnet = data.ibm_is_subnet.existing_subnet.id
}
```

### Managing Dependencies

**Implicit dependencies** (automatic):
```hcl
resource "ibm_is_instance" "web" {
  subnet = ibm_is_subnet.public.id  # Implicit dependency
}
```

**Explicit dependencies** (when needed):
```hcl
resource "ibm_cos_bucket" "encrypted" {
  kms_key_crn = ibm_kp_key.root_key.id
  
  # Ensure authorization policy exists first
  depends_on = [ibm_iam_authorization_policy.cos_kp]
}
```

### Dependency Best Practices

1. **Prefer implicit dependencies**: Use resource references
2. **Use explicit `depends_on` sparingly**: Only when implicit doesn't work
3. **Avoid circular dependencies**: Redesign if encountered
4. **Document complex dependencies**: Explain why they exist

---

## 🧩 Module Composition

### Why Use Modules?

- **Reusability**: Write once, use many times
- **Maintainability**: Update in one place
- **Testing**: Test modules independently
- **Abstraction**: Hide complexity

### Module Structure

```text
modules/
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── compute/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── security/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### Using Modules

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name = "production-vpc"
  region   = "us-south"
}

module "web_tier" {
  source = "./modules/compute"
  
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_id
  tier      = "web"
}
```

### Module Versioning

```hcl
module "vpc" {
  source  = "git::https://github.com/org/terraform-ibm-vpc.git?ref=v1.2.0"
  # or
  source  = "app.terraform.io/org/vpc/ibm"
  version = "~> 1.2"
}
```

---

## 🔄 Terraform Workspaces

### What are Workspaces?

Workspaces allow multiple state files for the same configuration:
- **default**: Default workspace
- **dev**: Development environment
- **staging**: Staging environment
- **prod**: Production environment

### Using Workspaces

```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new dev

# Switch workspace
terraform workspace select dev

# Show current workspace
terraform workspace show
```

### Workspace-Aware Configuration

```hcl
locals {
  environment = terraform.workspace
  
  instance_count = {
    dev     = 1
    staging = 2
    prod    = 4
  }
  
  instance_profile = {
    dev     = "bx2-2x8"
    staging = "bx2-4x16"
    prod    = "bx2-8x32"
  }
}

resource "ibm_is_instance" "app" {
  count   = local.instance_count[local.environment]
  profile = local.instance_profile[local.environment]
}
```

---

## 💾 Remote State Management

### Why Remote State?

- **Collaboration**: Multiple team members
- **Locking**: Prevent concurrent modifications
- **Security**: Encrypted state storage
- **Backup**: Automatic state versioning

### IBM Cloud Object Storage Backend

```hcl
terraform {
  backend "s3" {
    bucket                      = "terraform-state-bucket"
    key                         = "production/terraform.tfstate"
    region                      = "us-south"
    endpoint                    = "s3.us-south.cloud-object-storage.appdomain.cloud"
    skip_credentials_validation = true
    skip_region_validation      = true
  }
}
```

### State Locking

IBM COS doesn't support native locking, but you can use:
- **Terraform Cloud**: Built-in locking
- **DynamoDB**: For AWS S3 backend
- **Consul**: Distributed locking

### State Best Practices

1. **Never commit state files**: Add to `.gitignore`
2. **Use remote state**: Don't rely on local state
3. **Enable versioning**: On state storage bucket
4. **Encrypt state**: Use encrypted storage
5. **Limit access**: Restrict who can modify state

---

## ✅ Best Practices

### 1. Infrastructure as Code Principles

```hcl
# Good: Declarative, idempotent
resource "ibm_is_instance" "web" {
  name    = "web-server-${count.index + 1}"
  count   = 2
  profile = "bx2-2x8"
}

# Bad: Imperative, not idempotent
# (Don't use provisioners for infrastructure)
```

### 2. Naming Conventions

```hcl
# Resource naming: {environment}-{tier}-{resource}-{zone}
resource "ibm_is_instance" "web_zone1" {
  name = "${var.environment}-web-server-zone1"
}

# Variable naming: descriptive and consistent
variable "web_tier_instance_count" {
  description = "Number of web tier instances per zone"
}
```

### 3. Tagging Strategy

```hcl
locals {
  common_tags = [
    "environment:${var.environment}",
    "project:${var.project_name}",
    "managed-by:terraform",
    "cost-center:${var.cost_center}",
    "owner:${var.owner_email}",
  ]
}
```

### 4. Security Hardening

```hcl
# Always encrypt sensitive data
resource "ibm_cos_bucket" "backups" {
  kms_key_crn = ibm_kp_key.root_key.id
}

# Use private networking
resource "ibm_is_instance" "app" {
  primary_network_interface {
    subnet = ibm_is_subnet.private.id  # Private subnet
  }
}

# Restrict security groups
resource "ibm_is_security_group_rule" "db_from_app_only" {
  remote = ibm_is_security_group.app_tier.id  # Not 0.0.0.0/0
}
```

### 5. High Availability

```hcl
# Deploy across multiple zones
resource "ibm_is_instance" "web" {
  count = length(var.zones)
  zone  = var.zones[count.index]
}

# Use load balancers
resource "ibm_is_lb" "web" {
  subnets = [
    ibm_is_subnet.zone1.id,
    ibm_is_subnet.zone2.id,
  ]
}
```

---

## 🔬 Hands-On Labs

### Lab 1: Deploy Multi-Tier Architecture (45 minutes)

**Objective**: Deploy a complete 3-tier application infrastructure.

**Tasks**:
1. Review the architecture in `main.tf`
2. Understand the network segmentation
3. Run `terraform init`
4. Run `terraform plan`
5. Review the resource dependency graph
6. Identify security group relationships

**Expected Outcome**:
- Understand multi-tier architecture design
- See how tiers are isolated
- Learn dependency management

---

### Lab 2: Configure Load Balancer (30 minutes)

**Objective**: Set up load balancer with health checks.

**Tasks**:
1. Review load balancer configuration
2. Examine backend pool setup
3. Review health check settings
4. Run `terraform plan`
5. Understand traffic flow

**Expected Outcome**:
- Configure load balancer components
- Set up health checks
- Understand traffic distribution

---

### Lab 3: Implement Workspaces (25 minutes)

**Objective**: Use workspaces for multiple environments.

**Tasks**:
1. Create dev, staging, and prod workspaces
2. Review workspace-aware configuration
3. Deploy to dev workspace
4. Compare configurations across workspaces

**Expected Outcome**:
- Manage multiple environments
- Use workspace-specific settings
- Understand state isolation

---

## 🐛 Troubleshooting

### 1. Circular Dependency

**Problem**: Terraform detects circular dependency

**Example**:
```
Error: Cycle: resource_a depends on resource_b, resource_b depends on resource_a
```

**Fix**: Break the cycle by:
- Using data sources
- Splitting into multiple applies
- Redesigning resource relationships

---

### 2. Load Balancer Health Check Failures

**Problem**: Instances marked unhealthy

**Check**:
```bash
ibmcloud is lb <lb-id>
ibmcloud is lb-pools <lb-id>
```

**Fix**:
- Verify health check endpoint exists
- Check security group allows health check traffic
- Adjust health check timing parameters
- Verify application is running

---

### 3. State Lock Timeout

**Problem**: State locked by another operation

**Check**:
```bash
terraform force-unlock <lock-id>
```

**Fix**:
- Wait for other operation to complete
- Force unlock if operation failed
- Check for zombie processes

---

### 4. Module Version Conflicts

**Problem**: Module version incompatibility

**Fix**:
```hcl
# Pin module versions
module "vpc" {
  source  = "..."
  version = "~> 1.2.0"  # Allow 1.2.x
}
```

---

### 5. Resource Quota Exceeded

**Problem**: IBM Cloud quota limits reached

**Check**:
```bash
ibmcloud resource quotas
```

**Fix**:
- Request quota increase
- Clean up unused resources
- Use smaller instance profiles

---

## 📝 Checkpoint Quiz

### Question 1: Multi-Tier Architecture
**Why separate application tiers into different subnets?**

A) To save IP addresses  
B) For security isolation and independent scaling  
C) To reduce costs  
D) It's required by IBM Cloud

<details>
<summary>Click to reveal answer</summary>

**Answer: B) For security isolation and independent scaling**

Tier separation provides security boundaries and allows independent scaling of each tier.
</details>

---

### Question 2: Load Balancer Health Checks
**What happens when a load balancer health check fails?**

A) The instance is deleted  
B) The instance is restarted  
C) Traffic is no longer sent to that instance  
D) An alert is sent but traffic continues

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Traffic is no longer sent to that instance**

Failed health checks cause the load balancer to stop routing traffic to that instance until it becomes healthy again.
</details>

---

### Question 3: Terraform Dependencies
**When should you use explicit `depends_on`?**

A) Always, for clarity  
B) Never, it's deprecated  
C) Only when implicit dependencies don't capture the relationship  
D) Only for security groups

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Only when implicit dependencies don't capture the relationship**

Use `depends_on` sparingly, only when Terraform can't automatically detect the dependency.
</details>

---

### Question 4: Terraform Workspaces
**What is the primary purpose of Terraform workspaces?**

A) To organize files  
B) To manage multiple environments with separate state  
C) To improve performance  
D) To enable collaboration

<details>
<summary>Click to reveal answer</summary>

**Answer: B) To manage multiple environments with separate state**

Workspaces allow you to maintain separate state files for different environments using the same configuration.
</details>

---

### Question 5: Remote State
**Why use remote state instead of local state?**

A) It's faster  
B) It's required by Terraform  
C) For collaboration, locking, and backup  
D) To reduce costs

<details>
<summary>Click to reveal answer</summary>

**Answer: C) For collaboration, locking, and backup**

Remote state enables team collaboration, prevents concurrent modifications, and provides automatic backup.
</details>

---

### Question 6: High Availability
**What is the minimum number of availability zones for high availability?**

A) 1  
B) 2  
C) 3  
D) 4

<details>
<summary>Click to reveal answer</summary>

**Answer: B) 2**

At minimum, deploy across 2 zones to survive a zone failure. 3 zones is recommended for production.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [IBM Cloud VPC Architecture](https://cloud.ibm.com/docs/vpc?topic=vpc-about-vpc)
- [IBM Cloud Load Balancer](https://cloud.ibm.com/docs/vpc?topic=vpc-load-balancers)
- [Terraform Modules](https://www.terraform.io/docs/language/modules/index.html)
- [Terraform Workspaces](https://www.terraform.io/docs/language/state/workspaces.html)

### Terraform Provider Documentation
- [ibm_is_lb Resource](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_lb)
- [ibm_is_lb_pool Resource](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_lb_pool)
- [ibm_is_lb_listener Resource](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_lb_listener)

### Reference Material in This Repository
- `documentation/terraform-provider-ibm/examples/ibm-is-ng/`
- `documentation/terraform-provider-ibm/examples/ibm-website-multi-region/`

### Previous Courses
- [IBM-201: Setup & Authentication](../IBM-201-setup-auth/README.md)
- [IBM-202: Compute & Networking](../IBM-202-compute-networking/README.md)
- [IBM-203: Security & Storage](../IBM-203-security-storage/README.md)

---

## 🎓 Course Completion

Congratulations! You've completed the IBM-200 series on IBM Cloud with Terraform.

### Skills Acquired
✅ IBM Cloud account and authentication setup  
✅ VPC networking and compute provisioning  
✅ Security groups and encryption configuration  
✅ Multi-tier architecture design  
✅ Load balancer configuration  
✅ Infrastructure module composition  
✅ Enterprise-grade Terraform patterns

### Next Steps
- Apply these patterns to real projects
- Explore IBM Cloud-specific services (Databases, Kubernetes, etc.)
- Learn Terraform Cloud for team collaboration
- Study GitOps workflows with Terraform

---

*Part of the [Hashi-Training](../../../README.md) curriculum - IBM-200: IBM Cloud with Terraform*
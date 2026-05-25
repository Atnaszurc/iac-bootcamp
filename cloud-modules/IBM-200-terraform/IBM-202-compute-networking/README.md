# IBM-202: IBM Cloud Compute & Networking

**Course**: IBM-200 IBM Cloud with Terraform  
**Module**: IBM-202  
**Duration**: 1.5 hours  
**Prerequisites**: IBM-201 (Setup & Authentication)  
**Difficulty**: Intermediate

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [IBM Cloud VPC Fundamentals](#ibm-cloud-vpc-fundamentals)
4. [VPC Networking Concepts](#vpc-networking-concepts)
5. [Virtual Server Instances](#virtual-server-instances)
6. [SSH Key Management](#ssh-key-management)
7. [Public Gateway and Floating IPs](#public-gateway-and-floating-ips)
8. [Best Practices](#best-practices)
9. [Hands-On Labs](#hands-on-labs)
10. [Troubleshooting](#troubleshooting)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course teaches you how to provision compute and networking resources in IBM Cloud using Terraform. You'll learn how to create Virtual Private Clouds (VPCs), subnets, and Virtual Server Instances (VSIs) following IBM Cloud best practices.

### What You'll Build

By the end of this course, you'll be able to:
- Create and configure IBM Cloud VPCs
- Design subnet architectures across availability zones
- Provision Virtual Server Instances
- Manage SSH keys for secure access
- Configure public gateways and floating IPs for internet connectivity

### Course Structure

```text
IBM-202-compute-networking/
├── README.md                          # This file
└── example/
    ├── main.tf                        # VPC, subnet, and VSI resources
    ├── variables.tf                   # Input variables
    └── tests/
        └── basic.tftest.hcl           # Terraform tests with mocked provider data
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Understand IBM Cloud VPC Architecture**
   - Explain VPC isolation and multi-tenancy
   - Understand availability zones and regions
   - Design subnet CIDR blocks

2. **Create VPC Infrastructure**
   - Provision VPCs with Terraform
   - Configure address prefixes
   - Create subnets across zones

3. **Deploy Virtual Server Instances**
   - Select appropriate instance profiles
   - Choose operating system images
   - Configure instance metadata

4. **Manage Network Connectivity**
   - Configure public gateways
   - Assign floating IPs
   - Understand private vs public networking

5. **Apply Security Best Practices**
   - Use SSH keys instead of passwords
   - Follow least-privilege networking
   - Implement proper resource tagging

---

## ☁️ IBM Cloud VPC Fundamentals

### What is IBM Cloud VPC?

IBM Cloud Virtual Private Cloud (VPC) is a software-defined network that provides:
- **Isolation**: Your own private cloud within IBM Cloud
- **Control**: Full control over IP addressing, routing, and network policies
- **Scalability**: Elastic compute and networking resources
- **Security**: Built-in security groups and network ACLs

### VPC Architecture

```text
IBM Cloud Region (e.g., us-south)
├── VPC
│   ├── Zone 1 (us-south-1)
│   │   └── Subnet 1 (10.240.0.0/24)
│   │       └── VSI instances
│   ├── Zone 2 (us-south-2)
│   │   └── Subnet 2 (10.240.1.0/24)
│   │       └── VSI instances
│   └── Zone 3 (us-south-3)
│       └── Subnet 3 (10.240.2.0/24)
│           └── VSI instances
└── Public Gateway (optional, for internet access)
```

### Key VPC Concepts

- **VPC**: Isolated virtual network in IBM Cloud
- **Subnet**: Segment of VPC IP address range in a specific zone
- **Zone**: Isolated data center within a region
- **Address Prefix**: CIDR block allocated to a zone
- **Public Gateway**: Enables outbound internet access for private instances

---

## 🌐 VPC Networking Concepts

### IP Addressing

IBM Cloud VPC uses private RFC 1918 address spaces:
- `10.0.0.0/8`
- `172.16.0.0/12`
- `192.168.0.0/16`

### Subnet Design Best Practices

1. **Plan CIDR blocks carefully** - they cannot be changed after creation
2. **Use /24 or larger** - provides 256 addresses (251 usable)
3. **Reserve space for growth** - plan for future expansion
4. **Align with zones** - one subnet per zone for high availability

### Example Subnet Layout

```hcl
# Zone 1: 10.240.0.0/24 (256 addresses)
# Zone 2: 10.240.1.0/24 (256 addresses)
# Zone 3: 10.240.2.0/24 (256 addresses)
```

### Availability Zones

IBM Cloud regions have multiple availability zones:
- **us-south**: us-south-1, us-south-2, us-south-3
- **eu-de**: eu-de-1, eu-de-2, eu-de-3
- **eu-gb**: eu-gb-1, eu-gb-2, eu-gb-3

Distribute resources across zones for high availability.

---

## 💻 Virtual Server Instances

### Instance Profiles

IBM Cloud offers various instance profiles:

| Profile Family | Use Case | Example |
|---------------|----------|---------|
| **Balanced** | General purpose | bx2-2x8 (2 vCPU, 8 GB RAM) |
| **Compute** | CPU-intensive | cx2-4x8 (4 vCPU, 8 GB RAM) |
| **Memory** | Memory-intensive | mx2-4x32 (4 vCPU, 32 GB RAM) |

### Profile Naming Convention

Format: `{family}{generation}-{vcpu}x{memory}`

Example: `bx2-2x8`
- `b` = Balanced
- `x2` = Generation 2
- `2` = 2 vCPUs
- `8` = 8 GB RAM

### Operating System Images

Common IBM Cloud images:
- **Ubuntu**: `ibm-ubuntu-22-04-minimal-amd64-*`
- **Red Hat**: `ibm-redhat-8-*-minimal-amd64-*`
- **CentOS**: `ibm-centos-stream-9-amd64-*`
- **Debian**: `ibm-debian-11-*-minimal-amd64-*`

Use data sources to find the latest image versions.

---

## 🔑 SSH Key Management

### Why SSH Keys?

SSH keys provide:
- **Security**: More secure than passwords
- **Automation**: Enable automated provisioning
- **Auditability**: Track key usage

### Creating SSH Keys

Generate a new SSH key pair:

```bash
ssh-keygen -t rsa -b 4096 -C "terraform-training" -f ~/.ssh/ibm_cloud_training
```

This creates:
- Private key: `~/.ssh/ibm_cloud_training`
- Public key: `~/.ssh/ibm_cloud_training.pub`

### Using SSH Keys in Terraform

```hcl
resource "ibm_is_ssh_key" "training_key" {
  name       = "training-ssh-key"
  public_key = file("~/.ssh/ibm_cloud_training.pub")
}

resource "ibm_is_instance" "vsi" {
  keys = [ibm_is_ssh_key.training_key.id]
  # ... other configuration
}
```

### Connecting to Instances

```bash
ssh -i ~/.ssh/ibm_cloud_training root@<floating-ip>
```

---

## 🌍 Public Gateway and Floating IPs

### Public Gateway

A public gateway enables:
- **Outbound internet access** for instances in private subnets
- **NAT functionality** - instances share the gateway's public IP
- **No inbound access** - instances remain private

```hcl
resource "ibm_is_public_gateway" "gateway" {
  name = "training-gateway"
  vpc  = ibm_is_vpc.vpc.id
  zone = "us-south-1"
}

resource "ibm_is_subnet" "subnet" {
  public_gateway = ibm_is_public_gateway.gateway.id
  # ... other configuration
}
```

### Floating IPs

A floating IP provides:
- **Direct public IP** assigned to an instance
- **Inbound and outbound** internet access
- **Static IP** that persists across instance restarts

```hcl
resource "ibm_is_floating_ip" "fip" {
  name   = "training-fip"
  target = ibm_is_instance.vsi.primary_network_interface[0].id
}
```

### When to Use Each

| Feature | Public Gateway | Floating IP |
|---------|---------------|-------------|
| Outbound internet | ✅ | ✅ |
| Inbound internet | ❌ | ✅ |
| Multiple instances | ✅ | ❌ (one per instance) |
| Cost | Lower | Higher |
| Use case | Private instances | Public-facing services |

---

## ✅ Best Practices

### 1. Use Multiple Availability Zones

Distribute resources across zones for high availability:

```hcl
# Good: Multi-zone deployment
resource "ibm_is_subnet" "subnet_zone1" {
  zone = "us-south-1"
}

resource "ibm_is_subnet" "subnet_zone2" {
  zone = "us-south-2"
}
```

### 2. Plan IP Address Space

Reserve CIDR blocks for future growth:

```hcl
# Good: Planned address space
# Zone 1: 10.240.0.0/24  (current)
# Zone 2: 10.240.1.0/24  (current)
# Zone 3: 10.240.2.0/24  (reserved for future)
# Zone 4: 10.240.3.0/24  (reserved for future)
```

### 3. Use Data Sources for Images

Don't hardcode image IDs - they change over time:

```hcl
# Good: Use data source
data "ibm_is_image" "ubuntu" {
  name = "ibm-ubuntu-22-04-minimal-amd64-3"
}

resource "ibm_is_instance" "vsi" {
  image = data.ibm_is_image.ubuntu.id
}
```

### 4. Tag Resources Consistently

Use tags for organization and cost tracking:

```hcl
resource "ibm_is_vpc" "vpc" {
  name = "training-vpc"
  tags = [
    "environment:dev",
    "project:iac-bootcamp",
    "managed-by:terraform"
  ]
}
```

### 5. Use Descriptive Names

Follow a naming convention:

```hcl
# Good: Descriptive names
resource "ibm_is_vpc" "training_vpc" {
  name = "${var.environment}-${var.project}-vpc"
}

resource "ibm_is_subnet" "web_subnet_zone1" {
  name = "${var.environment}-web-subnet-zone1"
}
```

---

## 🔬 Hands-On Labs

### Lab 1: Create a VPC and Subnet (20 minutes)

**Objective**: Provision a VPC with a subnet in a single availability zone.

**Tasks**:
1. Navigate to the `example/` directory
2. Review the VPC and subnet configuration in `main.tf`
3. Run `terraform init`
4. Run `terraform plan`
5. Review the planned resources
6. Identify the VPC CIDR block and subnet configuration

**Expected Outcome**:
- Understand VPC resource structure
- See how subnets are associated with zones
- Understand address prefix allocation

---

### Lab 2: Add SSH Key and VSI (30 minutes)

**Objective**: Add an SSH key and provision a Virtual Server Instance.

**Tasks**:
1. Generate an SSH key pair (if you don't have one)
2. Review the SSH key and VSI configuration
3. Run `terraform plan`
4. Examine the instance profile and image selection
5. Review the network interface configuration

**Expected Outcome**:
- Understand SSH key management
- See how VSIs are configured
- Understand instance profiles and images

---

### Lab 3: Configure Internet Access (25 minutes)

**Objective**: Add a public gateway and floating IP for internet connectivity.

**Tasks**:
1. Review the public gateway configuration
2. Review the floating IP configuration
3. Run `terraform plan`
4. Understand the difference between public gateway and floating IP
5. Identify which resources enable inbound vs outbound access

**Expected Outcome**:
- Understand public gateway functionality
- Understand floating IP assignment
- Know when to use each approach

---

## 🐛 Troubleshooting

### 1. Subnet CIDR Conflicts

**Problem**: Terraform fails with "CIDR block overlaps with existing subnet"

**Check**:
```bash
ibmcloud is subnets --vpc <vpc-id>
```

**Fix**: Use non-overlapping CIDR blocks:
```hcl
# Ensure subnets don't overlap
resource "ibm_is_subnet" "subnet1" {
  ipv4_cidr_block = "10.240.0.0/24"  # 10.240.0.0 - 10.240.0.255
}

resource "ibm_is_subnet" "subnet2" {
  ipv4_cidr_block = "10.240.1.0/24"  # 10.240.1.0 - 10.240.1.255
}
```

---

### 2. Image Not Found

**Problem**: Terraform fails with "Image not found"

**Check**: List available images:
```bash
ibmcloud is images --visibility public | grep ubuntu
```

**Fix**: Use a data source to find the latest image:
```hcl
data "ibm_is_image" "ubuntu" {
  name = "ibm-ubuntu-22-04-minimal-amd64-3"
}
```

---

### 3. SSH Key Already Exists

**Problem**: Terraform fails with "SSH key with this name already exists"

**Check**:
```bash
ibmcloud is keys
```

**Fix**: Either:
- Use a unique name
- Import the existing key into Terraform state
- Delete the existing key if not needed

---

### 4. Instance Profile Not Available

**Problem**: Terraform fails with "Instance profile not available in zone"

**Check**: List available profiles:
```bash
ibmcloud is instance-profiles
```

**Fix**: Use a profile available in your target zone:
```hcl
# Use a common profile like bx2-2x8
resource "ibm_is_instance" "vsi" {
  profile = "bx2-2x8"
}
```

---

### 5. Cannot Connect to Instance

**Problem**: SSH connection times out or is refused

**Check**:
1. Verify floating IP is assigned
2. Check security group rules (covered in IBM-203)
3. Verify SSH key was properly configured

**Fix**:
```bash
# Check floating IP
ibmcloud is floating-ips

# Test connectivity
ping <floating-ip>
ssh -v -i ~/.ssh/ibm_cloud_training root@<floating-ip>
```

---

## 📝 Checkpoint Quiz

### Question 1: VPC Isolation
**What does a VPC provide in IBM Cloud?**

A) Shared networking with other tenants  
B) Isolated virtual network within IBM Cloud  
C) Physical network hardware  
D) Only public IP addresses

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Isolated virtual network within IBM Cloud**

VPCs provide network isolation and control within IBM Cloud.
</details>

---

### Question 2: Availability Zones
**Why should you distribute resources across multiple availability zones?**

A) To reduce costs  
B) To improve performance  
C) To achieve high availability  
D) To simplify management

<details>
<summary>Click to reveal answer</summary>

**Answer: C) To achieve high availability**

Multiple zones protect against zone-level failures.
</details>

---

### Question 3: Instance Profiles
**What does the profile name "bx2-2x8" indicate?**

A) 2 vCPUs, 8 GB RAM, balanced profile  
B) 8 vCPUs, 2 GB RAM, balanced profile  
C) 2 zones, 8 instances  
D) 2 TB storage, 8 Gbps network

<details>
<summary>Click to reveal answer</summary>

**Answer: A) 2 vCPUs, 8 GB RAM, balanced profile**

Format: {family}{gen}-{vcpu}x{memory}
</details>

---

### Question 4: Public Gateway vs Floating IP
**What is the key difference between a public gateway and a floating IP?**

A) Public gateway is faster  
B) Floating IP allows inbound access, public gateway only outbound  
C) Public gateway is more expensive  
D) Floating IP requires a VPN

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Floating IP allows inbound access, public gateway only outbound**

Public gateways provide NAT for outbound traffic. Floating IPs provide direct public access.
</details>

---

### Question 5: SSH Keys
**Why are SSH keys preferred over passwords for VSI access?**

A) They are easier to remember  
B) They provide better security and enable automation  
C) They are required by IBM Cloud  
D) They are faster to type

<details>
<summary>Click to reveal answer</summary>

**Answer: B) They provide better security and enable automation**

SSH keys are more secure and enable automated provisioning workflows.
</details>

---

### Question 6: Subnet CIDR Planning
**What is a best practice for subnet CIDR block sizing?**

A) Always use /32 for maximum control  
B) Use /24 or larger to allow for growth  
C) Use /8 for all subnets  
D) CIDR size doesn't matter

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Use /24 or larger to allow for growth**

/24 provides 256 addresses (251 usable) which is suitable for most use cases.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [IBM Cloud VPC Documentation](https://cloud.ibm.com/docs/vpc)
- [IBM Cloud Virtual Server Instances](https://cloud.ibm.com/docs/vpc?topic=vpc-about-advanced-virtual-servers)
- [IBM Cloud VPC Networking](https://cloud.ibm.com/docs/vpc?topic=vpc-about-networking-for-vpc)

### Terraform Provider Documentation
- [ibm_is_vpc Resource](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_vpc)
- [ibm_is_subnet Resource](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_subnet)
- [ibm_is_instance Resource](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_instance)

### Reference Material in This Repository
- `documentation/terraform-provider-ibm/examples/ibm-is-ng/`
- `documentation/terraform-provider-ibm/examples/ibm-vsi/`

### Next Steps
- **Next Course**: [IBM-203: Security & Storage](../IBM-203-security-storage/README.md)
- **Previous Course**: [IBM-201: Setup & Authentication](../IBM-201-setup-auth/README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - IBM-200: IBM Cloud with Terraform*
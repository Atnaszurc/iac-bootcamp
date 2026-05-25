# IBM-203: IBM Cloud Security & Storage

**Course**: IBM-200 IBM Cloud with Terraform  
**Module**: IBM-203  
**Duration**: 1.5 hours  
**Prerequisites**: IBM-202 (Compute & Networking)  
**Difficulty**: Intermediate

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Security Groups](#security-groups)
4. [Network ACLs](#network-acls)
5. [IBM Key Protect](#ibm-key-protect)
6. [Cloud Object Storage](#cloud-object-storage)
7. [IAM Authorization Policies](#iam-authorization-policies)
8. [Best Practices](#best-practices)
9. [Hands-On Labs](#hands-on-labs)
10. [Troubleshooting](#troubleshooting)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course teaches you how to secure IBM Cloud infrastructure and manage storage using Terraform. You'll learn about security groups, network ACLs, encryption with Key Protect, and object storage with Cloud Object Storage (COS).

### What You'll Build

By the end of this course, you'll be able to:
- Configure security groups and rules for VPC resources
- Understand and apply network ACLs
- Create and manage encryption keys with IBM Key Protect
- Provision and configure Cloud Object Storage buckets
- Set up IAM authorization policies for service-to-service access
- Apply defense-in-depth security principles

### Course Structure

```text
IBM-203-security-storage/
├── README.md                          # This file
└── example/
    ├── main.tf                        # Security groups, Key Protect, and COS
    ├── variables.tf                   # Input variables
    └── tests/
        └── basic.tftest.hcl           # Terraform tests with mocked provider data
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Implement Network Security**
   - Create and configure security groups
   - Define security group rules for common protocols
   - Understand stateful vs stateless firewalls
   - Apply network ACLs for subnet-level security

2. **Manage Encryption Keys**
   - Provision IBM Key Protect instances
   - Create root keys for encryption
   - Understand key hierarchies and rotation
   - Apply encryption to storage services

3. **Configure Object Storage**
   - Create Cloud Object Storage instances
   - Configure buckets with encryption
   - Set up lifecycle policies
   - Enable activity tracking and monitoring

4. **Establish Service Authorization**
   - Create IAM authorization policies
   - Enable service-to-service access
   - Follow least-privilege principles

5. **Apply Security Best Practices**
   - Implement defense-in-depth
   - Use encryption at rest and in transit
   - Enable audit logging
   - Follow compliance requirements

---

## 🔒 Security Groups

### What are Security Groups?

Security groups are **stateful** virtual firewalls that control traffic to and from resources in your VPC:
- **Stateful**: Return traffic is automatically allowed
- **Instance-level**: Applied to network interfaces
- **Default deny**: All traffic denied unless explicitly allowed
- **Rule-based**: Define allow rules for specific protocols and ports

### Security Group Architecture

```text
VPC
├── Security Group: web-tier
│   ├── Inbound Rules
│   │   ├── Allow TCP 80 from 0.0.0.0/0 (HTTP)
│   │   ├── Allow TCP 443 from 0.0.0.0/0 (HTTPS)
│   │   └── Allow TCP 22 from 10.0.0.0/8 (SSH from internal)
│   └── Outbound Rules
│       └── Allow all (default)
└── Security Group: database-tier
    ├── Inbound Rules
    │   └── Allow TCP 5432 from web-tier SG (PostgreSQL)
    └── Outbound Rules
        └── Allow all (default)
```

### Common Security Group Rules

#### SSH Access (Port 22)
```hcl
resource "ibm_is_security_group_rule" "allow_ssh" {
  group     = ibm_is_security_group.example.id
  direction = "inbound"
  remote    = "10.0.0.0/8"  # Restrict to internal network
  
  tcp {
    port_min = 22
    port_max = 22
  }
}
```

#### HTTP/HTTPS Access (Ports 80, 443)
```hcl
resource "ibm_is_security_group_rule" "allow_http" {
  group     = ibm_is_security_group.example.id
  direction = "inbound"
  remote    = "0.0.0.0/0"  # Public access
  
  tcp {
    port_min = 80
    port_max = 80
  }
}
```

#### ICMP (Ping)
```hcl
resource "ibm_is_security_group_rule" "allow_ping" {
  group     = ibm_is_security_group.example.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  
  icmp {
    type = 8  # Echo request
    code = 0
  }
}
```

### Security Group Best Practices

1. **Principle of Least Privilege**: Only allow necessary traffic
2. **Use Security Group References**: Reference other security groups instead of CIDR blocks
3. **Separate Tiers**: Create different security groups for web, app, and database tiers
4. **Document Rules**: Add descriptions to explain why rules exist
5. **Regular Review**: Audit rules periodically and remove unused ones

---

## 🛡️ Network ACLs

### What are Network ACLs?

Network ACLs (Access Control Lists) are **stateless** firewalls that control traffic at the subnet level:
- **Stateless**: Return traffic must be explicitly allowed
- **Subnet-level**: Applied to entire subnets
- **Default allow**: IBM Cloud default ACL allows all traffic
- **Rule priority**: Rules evaluated in order by priority number

### Security Groups vs Network ACLs

| Feature | Security Groups | Network ACLs |
|---------|----------------|--------------|
| **Level** | Instance (NIC) | Subnet |
| **State** | Stateful | Stateless |
| **Default** | Deny all | Allow all |
| **Rules** | Allow only | Allow and Deny |
| **Use Case** | Primary security | Additional layer |

### When to Use Network ACLs

- **Compliance requirements**: Need subnet-level controls
- **Defense-in-depth**: Additional security layer
- **Broad restrictions**: Block entire IP ranges
- **Subnet isolation**: Prevent cross-subnet traffic

### Network ACL Example

```hcl
resource "ibm_is_network_acl" "example" {
  name = "example-acl"
  vpc  = ibm_is_vpc.example.id
  
  rules {
    name        = "allow-inbound-ssh"
    action      = "allow"
    source      = "10.0.0.0/8"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    tcp {
      port_min = 22
      port_max = 22
    }
  }
  
  rules {
    name        = "allow-outbound-all"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }
}
```

---

## 🔐 IBM Key Protect

### What is IBM Key Protect?

IBM Key Protect is a cloud-based key management service (KMS) that provides:
- **Encryption key management**: Create, import, and manage encryption keys
- **FIPS 140-2 Level 3**: Hardware security modules (HSMs)
- **Envelope encryption**: Protect data encryption keys with root keys
- **Key rotation**: Automatic or manual key rotation
- **Audit logging**: Track all key operations

### Key Protect Architecture

```text
IBM Key Protect Instance
├── Root Key (Customer Root Key - CRK)
│   ├── Used to encrypt Data Encryption Keys (DEKs)
│   ├── Never leaves the HSM
│   └── Can be rotated
└── Standard Key
    ├── Can be exported
    └── Used for application-level encryption
```

### Creating a Key Protect Instance

```hcl
resource "ibm_resource_instance" "kp_instance" {
  name     = "my-key-protect"
  service  = "kms"
  plan     = "tiered-pricing"
  location = "us-south"
}
```

### Creating a Root Key

```hcl
resource "ibm_kp_key" "root_key" {
  key_protect_id = ibm_resource_instance.kp_instance.guid
  key_name       = "my-root-key"
  standard_key   = false  # false = root key, true = standard key
  force_delete   = false  # Prevent accidental deletion
}
```

### Key Protect Best Practices

1. **Use Root Keys**: Always use root keys (not standard keys) for envelope encryption
2. **Enable Key Rotation**: Rotate keys regularly (annually recommended)
3. **Prevent Deletion**: Set `force_delete = false` for production keys
4. **Separate Instances**: Use different Key Protect instances per environment
5. **Monitor Access**: Enable activity tracking for all key operations

---

## 📦 Cloud Object Storage

### What is IBM Cloud Object Storage?

IBM Cloud Object Storage (COS) provides scalable, durable object storage:
- **Scalability**: Store unlimited data
- **Durability**: 99.999999999% (11 nines) durability
- **Storage Classes**: Standard, Vault, Cold Vault, Flex
- **Global or Regional**: Choose based on requirements
- **S3 Compatible**: Works with S3 APIs and tools

### Storage Classes

| Class | Use Case | Retrieval | Cost |
|-------|----------|-----------|------|
| **Standard** | Frequently accessed | Immediate | Higher storage, no retrieval |
| **Vault** | Monthly access | Immediate | Lower storage, retrieval fee |
| **Cold Vault** | Yearly access | Hours | Lowest storage, higher retrieval |
| **Flex** | Mixed workloads | Immediate | Dynamic pricing |

### Creating a COS Instance

```hcl
resource "ibm_resource_instance" "cos_instance" {
  name              = "my-cos-instance"
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
}
```

### Creating an Encrypted Bucket

```hcl
resource "ibm_cos_bucket" "encrypted_bucket" {
  bucket_name          = "my-encrypted-bucket"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = "us-south"
  storage_class        = "standard"
  
  # Encryption with Key Protect
  kms_key_crn = ibm_kp_key.root_key.id
  
  # Activity tracking
  activity_tracking {
    read_data_events     = true
    write_data_events    = true
    management_events    = true
  }
  
  # Metrics monitoring
  metrics_monitoring {
    usage_metrics_enabled   = true
    request_metrics_enabled = true
  }
}
```

### Bucket Lifecycle Policies

```hcl
resource "ibm_cos_bucket" "lifecycle_bucket" {
  bucket_name          = "my-lifecycle-bucket"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = "us-south"
  storage_class        = "standard"
  
  # Archive old objects
  archive_rule {
    rule_id = "archive-rule"
    enable  = true
    days    = 90
    type    = "Glacier"  # Move to Cold Vault after 90 days
  }
  
  # Delete very old objects
  expire_rule {
    rule_id = "expire-rule"
    enable  = true
    days    = 365
  }
}
```

### COS Best Practices

1. **Enable Encryption**: Always use Key Protect encryption for sensitive data
2. **Use Lifecycle Policies**: Automatically transition or delete old objects
3. **Enable Monitoring**: Track usage and access patterns
4. **Set Retention Policies**: Prevent accidental deletion of important data
5. **Use Versioning**: Enable object versioning for critical buckets
6. **Restrict Access**: Use IAM policies and bucket policies

---

## 🔑 IAM Authorization Policies

### What are IAM Authorization Policies?

IAM authorization policies grant one service permission to access another service:
- **Service-to-service**: Enable COS to use Key Protect keys
- **Least privilege**: Grant only necessary permissions
- **Account-level**: Apply across the account
- **Role-based**: Use predefined roles (Reader, Writer, Manager)

### COS to Key Protect Authorization

To use Key Protect encryption with COS, you must create an authorization policy:

```hcl
resource "ibm_iam_authorization_policy" "cos_kp_policy" {
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = ibm_resource_instance.cos_instance.guid
  target_service_name         = "kms"
  target_resource_instance_id = ibm_resource_instance.kp_instance.guid
  roles                       = ["Reader"]
}
```

### Common Authorization Scenarios

#### COS to Key Protect
```hcl
source_service_name = "cloud-object-storage"
target_service_name = "kms"
roles               = ["Reader"]
```

#### VPC to Key Protect (for encrypted volumes)
```hcl
source_service_name = "server-protect"
target_service_name = "kms"
roles               = ["Reader"]
```

### Authorization Policy Best Practices

1. **Create Before Resources**: Create authorization policies before encrypted resources
2. **Use Instance IDs**: Scope policies to specific instances when possible
3. **Minimum Roles**: Use Reader role for encryption (not Manager)
4. **Document Dependencies**: Note which resources depend on which policies
5. **Test Policies**: Verify policies work before creating dependent resources

---

## ✅ Best Practices

### 1. Defense-in-Depth

Use multiple security layers:

```hcl
# Layer 1: Network ACL (subnet-level)
resource "ibm_is_network_acl" "subnet_acl" {
  # Broad subnet restrictions
}

# Layer 2: Security Group (instance-level)
resource "ibm_is_security_group" "instance_sg" {
  # Specific instance rules
}

# Layer 3: Application-level security
# Implement in application code
```

### 2. Encrypt Everything

```hcl
# Encrypt COS buckets
resource "ibm_cos_bucket" "encrypted" {
  kms_key_crn = ibm_kp_key.root_key.id
}

# Encrypt VSI boot volumes (covered in IBM-204)
# Encrypt data volumes
# Use TLS for data in transit
```

### 3. Enable Audit Logging

```hcl
resource "ibm_cos_bucket" "audited" {
  activity_tracking {
    read_data_events     = true
    write_data_events    = true
    management_events    = true
  }
  
  metrics_monitoring {
    usage_metrics_enabled   = true
    request_metrics_enabled = true
  }
}
```

### 4. Use Descriptive Names

```hcl
# Good: Descriptive security group names
resource "ibm_is_security_group" "web_tier_sg" {
  name = "${var.environment}-web-tier-sg"
}

resource "ibm_is_security_group" "database_tier_sg" {
  name = "${var.environment}-database-tier-sg"
}
```

### 5. Document Security Rules

```hcl
resource "ibm_is_security_group_rule" "allow_ssh_from_bastion" {
  group     = ibm_is_security_group.app_tier.id
  direction = "inbound"
  remote    = ibm_is_security_group.bastion.id
  
  tcp {
    port_min = 22
    port_max = 22
  }
  
  # Document why this rule exists
  # Purpose: Allow SSH access from bastion host for administration
  # Owner: Platform Team
  # Review Date: 2026-12-31
}
```

---

## 🔬 Hands-On Labs

### Lab 1: Configure Security Groups (25 minutes)

**Objective**: Create security groups with rules for a web application.

**Tasks**:
1. Review the security group configuration in `main.tf`
2. Identify the web tier and database tier security groups
3. Run `terraform plan`
4. Examine the security group rules
5. Understand how security groups reference each other

**Expected Outcome**:
- Understand security group rule syntax
- See how to create layered security
- Learn security group referencing patterns

---

### Lab 2: Set Up Key Protect and Encryption (30 minutes)

**Objective**: Create a Key Protect instance and root key for encryption.

**Tasks**:
1. Review the Key Protect instance configuration
2. Review the root key creation
3. Review the IAM authorization policy
4. Run `terraform plan`
5. Understand the dependency order

**Expected Outcome**:
- Understand Key Protect provisioning
- Learn about root keys vs standard keys
- See how IAM authorization policies work

---

### Lab 3: Create Encrypted Storage (25 minutes)

**Objective**: Provision Cloud Object Storage with Key Protect encryption.

**Tasks**:
1. Review the COS instance configuration
2. Review the encrypted bucket configuration
3. Review lifecycle and monitoring settings
4. Run `terraform plan`
5. Identify the encryption key reference

**Expected Outcome**:
- Understand COS bucket configuration
- Learn about encryption at rest
- See activity tracking and monitoring setup

---

## 🐛 Troubleshooting

### 1. Security Group Rule Conflicts

**Problem**: Terraform fails with "Security group rule already exists"

**Check**: List existing rules:
```bash
ibmcloud is security-group <sg-id>
```

**Fix**: Either:
- Remove duplicate rules from Terraform
- Import existing rules into state
- Delete conflicting rules manually

---

### 2. Key Protect Authorization Missing

**Problem**: COS bucket creation fails with "Unauthorized to use encryption key"

**Check**: Verify authorization policy exists:
```bash
ibmcloud iam authorization-policies
```

**Fix**: Create authorization policy first:
```hcl
resource "ibm_iam_authorization_policy" "cos_kp" {
  source_service_name = "cloud-object-storage"
  target_service_name = "kms"
  roles               = ["Reader"]
}

# Use depends_on to ensure policy exists first
resource "ibm_cos_bucket" "encrypted" {
  depends_on  = [ibm_iam_authorization_policy.cos_kp]
  kms_key_crn = ibm_kp_key.root_key.id
}
```

---

### 3. Bucket Name Already Taken

**Problem**: COS bucket creation fails with "Bucket name already exists"

**Check**: Bucket names are globally unique across all IBM Cloud accounts

**Fix**: Use a unique bucket name:
```hcl
resource "ibm_cos_bucket" "example" {
  bucket_name = "${var.account_id}-${var.environment}-${var.bucket_purpose}"
}
```

---

### 4. Key Protect Key Deletion

**Problem**: Cannot delete Key Protect key that's in use

**Check**: List resources using the key:
```bash
ibmcloud kp key list-registrations <key-id>
```

**Fix**: Delete dependent resources first, then the key:
```hcl
# Set force_delete = true only for non-production
resource "ibm_kp_key" "root_key" {
  force_delete = var.environment == "dev" ? true : false
}
```

---

### 5. Security Group Not Applied

**Problem**: Instance created but security group rules not working

**Check**: Verify security group is attached to instance:
```bash
ibmcloud is instance <instance-id>
```

**Fix**: Attach security group to network interface:
```hcl
resource "ibm_is_instance" "example" {
  primary_network_interface {
    subnet          = ibm_is_subnet.example.id
    security_groups = [ibm_is_security_group.example.id]
  }
}
```

---

## 📝 Checkpoint Quiz

### Question 1: Security Groups vs Network ACLs
**What is the key difference between security groups and network ACLs?**

A) Security groups are faster  
B) Security groups are stateful, network ACLs are stateless  
C) Network ACLs are more secure  
D) Security groups cost more

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Security groups are stateful, network ACLs are stateless**

Security groups automatically allow return traffic (stateful), while network ACLs require explicit rules for both directions (stateless).
</details>

---

### Question 2: Key Protect Root Keys
**What is the purpose of a root key in IBM Key Protect?**

A) To encrypt user passwords  
B) To encrypt data encryption keys (envelope encryption)  
C) To encrypt network traffic  
D) To encrypt Terraform state

<details>
<summary>Click to reveal answer</summary>

**Answer: B) To encrypt data encryption keys (envelope encryption)**

Root keys are used for envelope encryption - they encrypt the data encryption keys that actually encrypt your data.
</details>

---

### Question 3: IAM Authorization Policy
**Why is an IAM authorization policy needed for COS encryption with Key Protect?**

A) To reduce costs  
B) To grant COS permission to use Key Protect keys  
C) To improve performance  
D) To enable versioning

<details>
<summary>Click to reveal answer</summary>

**Answer: B) To grant COS permission to use Key Protect keys**

The authorization policy grants the COS service permission to access and use keys from Key Protect for encryption.
</details>

---

### Question 4: COS Storage Classes
**Which COS storage class is best for frequently accessed data?**

A) Cold Vault  
B) Vault  
C) Standard  
D) Archive

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Standard**

Standard storage class is optimized for frequently accessed data with immediate retrieval and no retrieval fees.
</details>

---

### Question 5: Security Group Rules
**What does a security group rule with `remote = "0.0.0.0/0"` mean?**

A) Block all traffic  
B) Allow traffic from anywhere  
C) Allow traffic from the VPC only  
D) Allow traffic from the subnet only

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Allow traffic from anywhere**

`0.0.0.0/0` represents all IP addresses, so this rule allows traffic from any source.
</details>

---

### Question 6: Defense-in-Depth
**What does defense-in-depth mean in cloud security?**

A) Using only one strong security control  
B) Using multiple layers of security controls  
C) Encrypting data three times  
D) Using the deepest subnet

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Using multiple layers of security controls**

Defense-in-depth means using multiple security layers (network ACLs, security groups, encryption, etc.) so if one fails, others still provide protection.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [IBM Cloud Security Groups](https://cloud.ibm.com/docs/vpc?topic=vpc-using-security-groups)
- [IBM Key Protect](https://cloud.ibm.com/docs/key-protect)
- [IBM Cloud Object Storage](https://cloud.ibm.com/docs/cloud-object-storage)
- [IAM Authorization Policies](https://cloud.ibm.com/docs/account?topic=account-serviceauth)

### Terraform Provider Documentation
- [ibm_is_security_group Resource](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_security_group)
- [ibm_kp_key Resource](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/kp_key)
- [ibm_cos_bucket Resource](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket)

### Reference Material in This Repository
- `documentation/terraform-provider-ibm/examples/ibm-is-ng/` (security groups)
- `documentation/terraform-provider-ibm/examples/ibm-key-protect/`
- `documentation/terraform-provider-ibm/examples/ibm-cos-bucket/`

### Next Steps
- **Next Course**: [IBM-204: Advanced Patterns](../IBM-204-advanced-patterns/README.md)
- **Previous Course**: [IBM-202: Compute & Networking](../IBM-202-compute-networking/README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - IBM-200: IBM Cloud with Terraform*
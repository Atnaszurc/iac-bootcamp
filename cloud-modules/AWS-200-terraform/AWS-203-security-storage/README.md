# AWS-203: Security & Storage

**Course**: AWS-200 AWS with Terraform  
**Module**: AWS-203  
**Duration**: 2 hours  
**Prerequisites**: AWS-202 (Compute & Networking)  
**Difficulty**: Intermediate

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [S3 Storage](#s3-storage)
4. [EBS Volumes](#ebs-volumes)
5. [IAM Roles and Policies](#iam-roles-and-policies)
6. [Secrets Management](#secrets-management)
7. [Encryption](#encryption)
8. [Best Practices](#best-practices)
9. [Hands-On Labs](#hands-on-labs)
10. [Troubleshooting](#troubleshooting)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course teaches you how to implement AWS security and storage using Terraform. You'll configure S3 buckets, EBS volumes, IAM roles and policies, and implement encryption and secrets management following AWS security best practices.

### What You'll Build

By the end of this course, you'll be able to:
- Create and configure S3 buckets with proper security
- Manage EBS volumes for persistent storage
- Implement IAM roles and policies with least privilege
- Store and retrieve secrets using AWS Secrets Manager
- Enable encryption for data at rest and in transit

### Course Structure

```
AWS-203-security-storage/
├── README.md                          # This file
└── example/
    ├── s3.tf                          # S3 buckets
    ├── ebs.tf                         # EBS volumes
    ├── iam.tf                         # IAM roles and policies
    ├── secrets.tf                     # Secrets Manager
    ├── kms.tf                         # KMS encryption keys
    ├── variables.tf                   # Input variables
    ├── outputs.tf                     # Output values
    └── versions.tf                    # Version constraints
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Configure S3 Storage**
   - Create S3 buckets with versioning
   - Implement bucket policies
   - Configure lifecycle rules
   - Enable server-side encryption

2. **Manage EBS Volumes**
   - Create and attach EBS volumes
   - Configure volume types and sizes
   - Implement snapshots and backups

3. **Implement IAM Security**
   - Create IAM roles with least privilege
   - Write IAM policies
   - Use IAM instance profiles

4. **Manage Secrets**
   - Store secrets in AWS Secrets Manager
   - Retrieve secrets in Terraform
   - Rotate secrets automatically

5. **Enable Encryption**
   - Create KMS keys
   - Encrypt S3 buckets and EBS volumes
   - Implement encryption in transit

---

## 🪣 S3 Storage

### Basic S3 Bucket

```hcl
# s3.tf

resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.environment}-storage"
  
  tags = {
    Name        = "${var.project_name}-storage"
    Environment = var.environment
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}
```

### S3 Bucket Policy

```hcl
# Bucket policy - allow specific IAM role
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowTerraformRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.app_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Sid    = "AllowListBucket"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.app_role.arn
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.main.arn
      }
    ]
  })
}
```

### S3 Lifecycle Rules

```hcl
# Lifecycle rules for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    
    expiration {
      days = 365
    }
  }
  
  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

### Static Website Hosting

```hcl
# S3 static website
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  
  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "error.html"
  }
}

# Upload website files
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "website/index.html"
  content_type = "text/html"
  etag         = filemd5("website/index.html")
}
```

---

## 💾 EBS Volumes

### Creating EBS Volumes

```hcl
# ebs.tf

# EBS volume
resource "aws_ebs_volume" "data" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 50
  type              = "gp3"
  iops              = 3000
  throughput        = 125
  encrypted         = true
  kms_key_id        = aws_kms_key.ebs.arn
  
  tags = {
    Name = "${var.project_name}-data-volume"
  }
}

# Attach volume to instance
resource "aws_volume_attachment" "data" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.app.id
}
```

### EBS Volume Types

| Type | Use Case | IOPS | Throughput |
|------|----------|------|------------|
| `gp3` | General purpose (recommended) | Up to 16,000 | Up to 1,000 MB/s |
| `gp2` | General purpose (legacy) | Up to 16,000 | Up to 250 MB/s |
| `io2` | High performance databases | Up to 64,000 | Up to 1,000 MB/s |
| `st1` | Big data, log processing | N/A | Up to 500 MB/s |
| `sc1` | Cold storage, infrequent access | N/A | Up to 250 MB/s |

### EBS Snapshots

```hcl
# Create snapshot
resource "aws_ebs_snapshot" "data_backup" {
  volume_id   = aws_ebs_volume.data.id
  description = "Backup of data volume"
  
  tags = {
    Name      = "${var.project_name}-snapshot"
    CreatedBy = "Terraform"
  }
}

# Create volume from snapshot
resource "aws_ebs_volume" "restored" {
  availability_zone = data.aws_availability_zones.available.names[0]
  snapshot_id       = aws_ebs_snapshot.data_backup.id
  type              = "gp3"
  encrypted         = true
  
  tags = {
    Name = "${var.project_name}-restored-volume"
  }
}
```

### Root Volume Configuration

```hcl
resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    kms_key_id            = aws_kms_key.ebs.arn
    delete_on_termination = true
  }
  
  ebs_block_device {
    device_name           = "/dev/xvdf"
    volume_size           = 100
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = false
  }
}
```

---

## 🔐 IAM Roles and Policies

### Creating IAM Roles

```hcl
# iam.tf

# Application role
resource "aws_iam_role" "app_role" {
  name        = "${var.project_name}-app-role"
  description = "Role for application servers"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
  
  tags = {
    Name = "${var.project_name}-app-role"
  }
}

# Instance profile
resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.app_role.name
}
```

### Custom IAM Policies

```hcl
# S3 access policy
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-s3-access"
  description = "Allow access to application S3 bucket"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.main.arn
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# Attach AWS managed policy
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

### Secrets Manager Access Policy

```hcl
resource "aws_iam_policy" "secrets_access" {
  name = "${var.project_name}-secrets-access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = aws_secretsmanager_secret.db_password.arn
    }]
  })
}
```

---

## 🔑 Secrets Management

### AWS Secrets Manager

```hcl
# secrets.tf

# Create secret
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}/db/password"
  description             = "Database password for application"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.secrets.arn
  
  tags = {
    Name = "${var.project_name}-db-password"
  }
}

# Set secret value
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db.result
    host     = aws_db_instance.main.endpoint
    port     = 5432
    dbname   = var.db_name
  })
}

# Generate random password
resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
```

### Retrieving Secrets in Terraform

```hcl
# Read existing secret
data "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}/db/password"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

locals {
  db_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.db_password.secret_string
  )
}

# Use in resource
resource "aws_db_instance" "main" {
  username = local.db_credentials.username
  password = local.db_credentials.password
  # ...
}
```

### Secret Rotation

```hcl
# Enable automatic rotation
resource "aws_secretsmanager_secret_rotation" "db_password" {
  secret_id           = aws_secretsmanager_secret.db_password.id
  rotation_lambda_arn = aws_lambda_function.rotation.arn
  
  rotation_rules {
    automatically_after_days = 30
  }
}
```

---

## 🔒 Encryption

### KMS Keys

```hcl
# kms.tf

# KMS key for S3
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name = "${var.project_name}-s3-key"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# KMS key for EBS
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name = "${var.project_name}-ebs-key"
  }
}

# KMS key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name = "${var.project_name}-secrets-key"
  }
}
```

### KMS Key Policy

```hcl
resource "aws_kms_key" "main" {
  description = "Main KMS key"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Application Role"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.app_role.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}
```

---

## ✅ Best Practices

### 1. S3 Security Checklist

```hcl
# Always apply these to every S3 bucket:
resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true   # ✅
  block_public_policy     = true   # ✅
  ignore_public_acls      = true   # ✅
  restrict_public_buckets = true   # ✅
}
```

### 2. Encrypt Everything

```hcl
# S3: Server-side encryption
# EBS: Encrypted volumes
# RDS: Encrypted databases
# Secrets: KMS-encrypted secrets
```

### 3. IAM Least Privilege

```hcl
# ❌ Too permissive
resource "aws_iam_policy" "bad" {
  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

# ✅ Least privilege
resource "aws_iam_policy" "good" {
  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "${aws_s3_bucket.main.arn}/*"
    }]
  })
}
```

### 4. Enable CloudTrail

```hcl
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
}
```

### 5. Use Resource-Based Policies

```hcl
# Restrict S3 access to specific VPC endpoint
resource "aws_s3_bucket_policy" "vpc_only" {
  bucket = aws_s3_bucket.main.id
  
  policy = jsonencode({
    Statement = [{
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = ["${aws_s3_bucket.main.arn}", "${aws_s3_bucket.main.arn}/*"]
      Condition = {
        StringNotEquals = {
          "aws:SourceVpc" = aws_vpc.main.id
        }
      }
    }]
  })
}
```

---

## 🔬 Hands-On Labs

### Lab 1: Secure S3 Bucket (20 minutes)

**Objective**: Create a fully secured S3 bucket with encryption and versioning.

**Tasks**:
1. Create S3 bucket with unique name
2. Block all public access
3. Enable versioning
4. Create KMS key for encryption
5. Enable server-side encryption with KMS
6. Add lifecycle rules (30 days → IA, 90 days → Glacier)
7. Verify bucket configuration

**Expected Output**:
- S3 bucket with versioning enabled
- All public access blocked
- KMS encryption active
- Lifecycle rules configured

---

### Lab 2: IAM Role for EC2 (20 minutes)

**Objective**: Create an IAM role with least-privilege access for an EC2 instance.

**Tasks**:
1. Create IAM role for EC2
2. Create custom policy for S3 access (specific bucket only)
3. Attach SSM managed policy
4. Create instance profile
5. Launch EC2 instance with the role
6. Verify instance can access S3 but not other buckets

**Expected Output**:
- IAM role with minimal permissions
- EC2 instance using the role
- Instance can read/write to specific S3 bucket
- Instance accessible via SSM Session Manager

---

### Lab 3: Secrets Manager (20 minutes)

**Objective**: Store and retrieve database credentials using AWS Secrets Manager.

**Tasks**:
1. Create KMS key for secrets
2. Generate random password
3. Store credentials in Secrets Manager
4. Create IAM policy for secret access
5. Retrieve secret in Terraform
6. Use secret in RDS configuration

**Expected Output**:
- Secret stored in Secrets Manager
- KMS encryption enabled
- IAM policy restricts access to specific secret
- Secret value retrievable via data source

---

## 🐛 Troubleshooting

### Common Issues

#### 1. S3 Access Denied

**Problem**: `AccessDenied when calling the PutObject operation`

**Solutions**:
```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket my-bucket

# Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:role/my-role \
  --action-names s3:PutObject \
  --resource-arns arn:aws:s3:::my-bucket/*
```

#### 2. KMS Key Access Denied

**Problem**: `AccessDeniedException: User is not authorized to use KMS key`

**Solution**:
```hcl
# Add key policy allowing the role
resource "aws_kms_key" "main" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = { AWS = aws_iam_role.app_role.arn }
      Action = ["kms:Decrypt", "kms:GenerateDataKey"]
      Resource = "*"
    }]
  })
}
```

#### 3. Secret Not Found

**Problem**: `ResourceNotFoundException: Secrets Manager can't find the specified secret`

**Solution**:
```bash
# List secrets
aws secretsmanager list-secrets

# Check secret name
aws secretsmanager describe-secret --secret-id my-secret
```

---

## 📝 Checkpoint Quiz

### Question 1: S3 Security
**What should you always do when creating an S3 bucket?**

A) Make it public for easy access  
B) Block all public access  
C) Disable versioning to save costs  
D) Use default encryption only

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Block all public access**

Always apply `aws_s3_bucket_public_access_block` with all four settings set to `true` to prevent accidental public exposure of data.
</details>

---

### Question 2: EBS Volume Types
**Which EBS volume type is recommended for general-purpose workloads?**

A) io2 - for maximum IOPS  
B) st1 - for streaming workloads  
C) gp3 - general purpose SSD  
D) sc1 - cold storage

<details>
<summary>Click to reveal answer</summary>

**Answer: C) gp3 - general purpose SSD**

`gp3` is the recommended general-purpose SSD volume type. It offers better performance than `gp2` at the same or lower cost, with configurable IOPS and throughput.
</details>

---

### Question 3: IAM Policies
**What is the principle of least privilege in IAM?**

A) Grant all permissions to simplify management  
B) Grant only the minimum permissions required  
C) Use only AWS managed policies  
D) Deny all permissions by default

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Grant only the minimum permissions required**

Least privilege means granting only the permissions needed to perform the required tasks. This minimizes the blast radius if credentials are compromised.
</details>

---

### Question 4: KMS Key Rotation
**Why should you enable KMS key rotation?**

A) It's required by AWS  
B) Reduces costs  
C) Improves security by regularly changing encryption keys  
D) Increases performance

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Improves security by regularly changing encryption keys**

Key rotation reduces the risk of key compromise. AWS KMS automatically rotates the key material annually when enabled, without changing the key ID or ARN.
</details>

---

### Question 5: Secrets Manager vs Parameter Store
**When should you use AWS Secrets Manager over Parameter Store?**

A) For all configuration values  
B) When you need automatic secret rotation  
C) For storing AMI IDs  
D) For storing Terraform state

<details>
<summary>Click to reveal answer</summary>

**Answer: B) When you need automatic secret rotation**

Secrets Manager is designed for secrets that need rotation (database passwords, API keys). It supports automatic rotation via Lambda functions. Parameter Store is better for configuration values that don't need rotation.
</details>

---

### Question 6: S3 Lifecycle Rules
**What is the purpose of S3 lifecycle rules?**

A) Improve performance  
B) Automatically transition or delete objects to reduce costs  
C) Enable versioning  
D) Block public access

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Automatically transition or delete objects to reduce costs**

Lifecycle rules automatically move objects to cheaper storage classes (Standard-IA, Glacier) after a specified time, or delete them when they're no longer needed, reducing storage costs.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [S3 User Guide](https://docs.aws.amazon.com/s3/latest/userguide/)
- [EBS User Guide](https://docs.aws.amazon.com/ebs/latest/userguide/)
- [IAM User Guide](https://docs.aws.amazon.com/iam/latest/userguide/)
- [Secrets Manager User Guide](https://docs.aws.amazon.com/secretsmanager/latest/userguide/)
- [KMS Developer Guide](https://docs.aws.amazon.com/kms/latest/developerguide/)

### Next Steps
- **Next Course**: [AWS-204: Advanced Patterns](../AWS-204-advanced-patterns/README.md)
- **Previous Course**: [AWS-202: Compute & Networking](../AWS-202-compute-networking/README.md)

---

## ⚠️ AWS Provider v6 Compatibility

This module uses `hashicorp/aws ~> 6.0`. The resources covered in this course (S3, EBS, IAM, KMS, Secrets Manager) have **no breaking changes** in the AWS provider v6 upgrade.

### ✅ Resources Confirmed Compatible with v6

| Resource | Status | Notes |
|----------|--------|-------|
| `aws_s3_bucket` | ✅ No changes | All attributes unchanged |
| `aws_s3_bucket_versioning` | ✅ No changes | |
| `aws_s3_bucket_server_side_encryption_configuration` | ✅ No changes | |
| `aws_s3_bucket_public_access_block` | ✅ No changes | |
| `aws_s3_bucket_policy` | ✅ No changes | |
| `aws_s3_bucket_lifecycle_configuration` | ✅ No changes | |
| `aws_ebs_volume` | ✅ No changes | |
| `aws_volume_attachment` | ✅ No changes | |
| `aws_iam_role` | ✅ No changes | |
| `aws_iam_policy` | ✅ No changes | |
| `aws_iam_instance_profile` | ✅ No changes | |
| `aws_kms_key` | ✅ No changes | |
| `aws_secretsmanager_secret` | ✅ No changes | |

### 📋 General v6 Changes to Be Aware Of

Even though this module is unaffected, be aware of these v6 changes when working across modules:

- **`data "aws_region"` attribute rename**: `.name` → `.region` (affects AWS-201)
- **`aws_security_group` inline rules deprecated**: Use `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule` instead (affects AWS-202)
- **`aws_eip` `vpc` argument removed**: Use `domain = "vpc"` instead (affects AWS-202)

**Reference**: [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - AWS-200: AWS with Terraform*
---

## 🔄 AWS Provider v6 Changes

> **This module uses `hashicorp/aws ~> 6.0`** (upgraded from 5.x). The following breaking changes from the [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade) are relevant to this module:

### `aws_s3_bucket` — `bucket_region` attribute added

In v6, the `region` attribute on `aws_s3_bucket` is now used for [Enhanced Region Support](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/enhanced-region-support). Use `bucket_region` to get the bucket's region:

```hcl
# ❌ v5: used .region to get bucket region
output "bucket_region" {
  value = aws_s3_bucket.main.region  # now used for Enhanced Region Support in v6
}

# ✅ v6: use bucket_region
output "bucket_region" {
  value = aws_s3_bucket.main.bucket_region
}
```

The example in this module does not reference `aws_s3_bucket.region` so no change is needed.

### `aws_ebs_volume` — no breaking changes

EBS volumes have no breaking changes in v6. The `encrypted = true` pattern used in this module is unchanged.

### `aws_iam_*` resources — no breaking changes

IAM resources (`aws_iam_role`, `aws_iam_role_policy`, `aws_iam_instance_profile`) have no breaking changes in v6.

### Removed Services (not used in this module)

The following AWS services were removed in v6 and are **not used** in this module:
- `aws_opsworks_*` — OpsWorks Stacks reached End of Life
- `aws_simpledb_domain` — SimpleDB removed from AWS SDK v2
- `aws_worklink_*` — WorkLink support removed

**Reference**: [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade)
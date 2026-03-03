# AWS-204: Advanced AWS Patterns

**Course**: AWS-200 AWS with Terraform  
**Module**: AWS-204  
**Duration**: 1 hour  
**Prerequisites**: AWS-203 (Security & Storage)  
**Difficulty**: Intermediate-Advanced

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Auto Scaling](#auto-scaling)
4. [RDS Databases](#rds-databases)
5. [CloudFront CDN](#cloudfront-cdn)
6. [Multi-Region Patterns](#multi-region-patterns)
7. [Terraform Modules for AWS](#terraform-modules-for-aws)
8. [Best Practices](#best-practices)
9. [Hands-On Labs](#hands-on-labs)
10. [Troubleshooting](#troubleshooting)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course covers advanced AWS patterns using Terraform. You'll implement auto scaling groups, managed databases, CDN distribution, and multi-region deployments. You'll also learn to create reusable Terraform modules for AWS infrastructure.

### What You'll Build

By the end of this course, you'll be able to:
- Implement Auto Scaling Groups for dynamic capacity
- Deploy managed RDS databases
- Configure CloudFront for global content delivery
- Design multi-region architectures
- Create reusable AWS Terraform modules

### Course Structure

```
AWS-204-advanced-patterns/
├── README.md                          # This file
└── example/
    ├── autoscaling.tf                 # Auto Scaling Group
    ├── rds.tf                         # RDS database
    ├── cloudfront.tf                  # CloudFront distribution
    ├── modules/
    │   ├── vpc/                       # Reusable VPC module
    │   ├── ec2-cluster/               # EC2 cluster module
    │   └── rds/                       # RDS module
    ├── variables.tf                   # Input variables
    ├── outputs.tf                     # Output values
    └── versions.tf                    # Version constraints
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Implement Auto Scaling**
   - Create launch templates
   - Configure Auto Scaling Groups
   - Set scaling policies

2. **Deploy RDS Databases**
   - Create RDS instances and clusters
   - Configure Multi-AZ deployments
   - Implement read replicas

3. **Configure CloudFront**
   - Create distributions
   - Configure origins and behaviors
   - Implement caching strategies

4. **Design Multi-Region**
   - Deploy to multiple regions
   - Implement Route 53 routing
   - Handle cross-region replication

5. **Build Reusable Modules**
   - Create AWS-specific modules
   - Implement module composition
   - Share modules across projects

---

## 📈 Auto Scaling

> **⚠️ AWS Provider v6 Notes**:
> - `aws_instance.user_data` is now stored in **cleartext** (no longer hashed). Do not include passwords or sensitive data in `user_data` — it will be visible in state files and plan output. Use `user_data_base64` for pre-encoded content, or pass secrets via SSM Parameter Store / Secrets Manager.
> - `aws_launch_template`: `elastic_gpu_specifications` and `elastic_inference_accelerator` have been **removed** (both services reached end of life). Remove these blocks if present.
> - `aws_security_group` inline `ingress`/`egress` blocks are **deprecated** — use `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule` for new code.

### Launch Template

```hcl
# autoscaling.tf

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }
  
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF
  )
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-web"
      Project = var.project_name
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
}
```

### Auto Scaling Group

```hcl
resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }
}
```

### Scaling Policies

```hcl
# CPU-based scaling
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Scale up when CPU > 80%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

# Target tracking scaling (simpler)
resource "aws_autoscaling_policy" "target_tracking" {
  name                   = "${var.project_name}-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
```

---

## 🗄️ RDS Databases

### RDS Instance

```hcl
# rds.tf

# DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  
  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn
  
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  
  multi_az               = var.environment == "production"
  publicly_accessible    = false
  deletion_protection    = var.environment == "production"
  skip_final_snapshot    = var.environment != "production"
  
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  tags = {
    Name        = "${var.project_name}-db"
    Environment = var.environment
  }
}
```

### RDS Aurora Cluster

```hcl
# Aurora PostgreSQL cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${var.project_name}-aurora"
  
  engine         = "aurora-postgresql"
  engine_version = "15.4"
  
  database_name   = var.db_name
  master_username = var.db_username
  master_password = random_password.db.result
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn
  
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  
  deletion_protection = var.environment == "production"
  skip_final_snapshot = var.environment != "production"
  
  tags = {
    Name = "${var.project_name}-aurora"
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  count = var.environment == "production" ? 2 : 1
  
  identifier         = "${var.project_name}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version
}
```

---

## 🌐 CloudFront CDN

### CloudFront Distribution

```hcl
# cloudfront.tf

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"  # US, Canada, Europe
  
  # S3 origin
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.website.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }
  
  # ALB origin
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "ALB-${var.project_name}"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  # Default cache behavior (S3)
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website.id}"
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }
  
  # API cache behavior (ALB)
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ALB-${var.project_name}"
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type"]
      cookies {
        forward = "all"
      }
    }
    
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  tags = {
    Name = "${var.project_name}-cdn"
  }
}

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
```

---

## 🌍 Multi-Region Patterns

### Multi-Region Provider Configuration

```hcl
# Primary region
provider "aws" {
  region = "us-east-1"
  alias  = "primary"
}

# DR region
provider "aws" {
  region = "eu-west-1"
  alias  = "dr"
}
```

### Cross-Region S3 Replication

```hcl
# Primary bucket
resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "${var.project_name}-primary"
}

# DR bucket
resource "aws_s3_bucket" "dr" {
  provider = aws.dr
  bucket   = "${var.project_name}-dr"
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "main" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  role     = aws_iam_role.replication.arn
  
  rule {
    id     = "replicate-all"
    status = "Enabled"
    
    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "STANDARD_IA"
    }
  }
}
```

### Route 53 Failover

```hcl
# Primary record
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  set_identifier = "primary"
  health_check_id = aws_route53_health_check.primary.id
  
  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }
}

# Secondary (DR) record
resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  set_identifier = "secondary"
  
  alias {
    name                   = aws_lb.dr.dns_name
    zone_id                = aws_lb.dr.zone_id
    evaluate_target_health = true
  }
}
```

---

## 📦 Terraform Modules for AWS

### VPC Module

```hcl
# modules/vpc/main.tf
variable "project_name" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.project_name}-vpc" }
}

# ... subnets, route tables, etc.

output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
```

### Using the Module

```hcl
# main.tf
module "vpc" {
  source = "./modules/vpc"
  
  project_name         = var.project_name
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
}

module "web_cluster" {
  source = "./modules/ec2-cluster"
  
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.public_subnet_ids
  min_size     = 2
  max_size     = 10
}
```

---

## ✅ Best Practices

### 1. Production Checklist

```hcl
# Production settings
resource "aws_db_instance" "prod" {
  multi_az            = true   # ✅ High availability
  deletion_protection = true   # ✅ Prevent accidental deletion
  storage_encrypted   = true   # ✅ Encrypt data at rest
  backup_retention_period = 7  # ✅ Keep backups
}
```

### 2. Cost Optimization

```hcl
# Use Spot instances for non-critical workloads
resource "aws_launch_template" "spot" {
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.05"
    }
  }
}

# Use Reserved Instances for predictable workloads
# (configured in AWS console, not Terraform)
```

### 3. Tagging Strategy

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    Owner       = var.owner
  }
}
```

### 4. Use Managed Services

```
❌ Self-managed: EC2 + PostgreSQL
✅ Managed: RDS PostgreSQL

❌ Self-managed: EC2 + Redis
✅ Managed: ElastiCache Redis

❌ Self-managed: EC2 + Nginx
✅ Managed: ALB + CloudFront
```

---

## 🔬 Hands-On Labs

### Lab 1: Auto Scaling Web Tier (25 minutes)

**Objective**: Deploy a web application with Auto Scaling.

**Tasks**:
1. Create launch template with Nginx
2. Create Auto Scaling Group (min: 1, max: 3)
3. Configure Application Load Balancer
4. Set up target tracking scaling policy (CPU 70%)
5. Test scaling by generating load
6. Verify instances scale up and down

**Expected Output**:
- ASG with 1-3 instances
- ALB distributing traffic
- Automatic scaling based on CPU

---

### Lab 2: RDS with Multi-AZ (20 minutes)

**Objective**: Deploy a PostgreSQL RDS instance with high availability.

**Tasks**:
1. Create DB subnet group across 2 AZs
2. Create security group for RDS
3. Deploy RDS PostgreSQL (Multi-AZ for production)
4. Store credentials in Secrets Manager
5. Connect from EC2 instance
6. Verify failover capability

**Expected Output**:
- RDS instance in private subnets
- Multi-AZ enabled
- Credentials in Secrets Manager
- EC2 can connect to database

---

### Lab 3: Complete Production Architecture (30 minutes)

**Objective**: Build a complete production-ready AWS architecture.

**Tasks**:
1. Deploy VPC with public/private subnets
2. Create Auto Scaling web tier
3. Deploy RDS database
4. Configure CloudFront distribution
5. Set up monitoring with CloudWatch
6. Implement all security best practices

**Expected Output**:
- Complete 3-tier architecture
- CloudFront serving static content
- Auto Scaling web servers
- RDS database in private subnet
- All resources encrypted and tagged

---

## 🐛 Troubleshooting

### Common Issues

#### 1. ASG Instances Not Healthy

**Problem**: Instances launch but are marked unhealthy

**Solutions**:
```bash
# Check instance health
aws autoscaling describe-auto-scaling-instances

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn arn:...

# Check instance logs
aws ec2 get-console-output --instance-id i-xxx
```

#### 2. RDS Connection Refused

**Problem**: Can't connect to RDS from EC2

**Solutions**:
- Check security group allows port 5432 from EC2 SG
- Verify RDS is in private subnet (not publicly accessible)
- Check DB subnet group includes correct subnets

#### 3. CloudFront 403 Error

**Problem**: CloudFront returns 403 for S3 content

**Solution**:
```hcl
# Ensure OAC is configured and bucket policy allows CloudFront
resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.cloudfront.json
}
```

---

## 📝 Checkpoint Quiz

### Question 1: Auto Scaling
**What is the purpose of a Launch Template in Auto Scaling?**

A) Defines the scaling policies  
B) Specifies the instance configuration for new instances  
C) Configures the load balancer  
D) Sets the minimum and maximum instance count

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Specifies the instance configuration for new instances**

A Launch Template defines the AMI, instance type, security groups, user data, and other configuration that Auto Scaling uses when launching new instances.
</details>

---

### Question 2: RDS Multi-AZ
**What does RDS Multi-AZ provide?**

A) Better read performance  
B) Automatic failover to a standby instance in another AZ  
C) Multiple database engines  
D) Cross-region replication

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Automatic failover to a standby instance in another AZ**

Multi-AZ maintains a synchronous standby replica in a different AZ. If the primary fails, RDS automatically fails over to the standby, typically within 1-2 minutes.
</details>

---

### Question 3: CloudFront
**What is the main benefit of using CloudFront?**

A) Cheaper storage  
B) Reduced latency by caching content at edge locations globally  
C) Better security  
D) Easier deployment

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Reduced latency by caching content at edge locations globally**

CloudFront caches content at 400+ edge locations worldwide, serving users from the nearest location and reducing latency significantly compared to serving from a single origin.
</details>

---

### Question 4: Target Tracking Scaling
**What is the advantage of target tracking scaling over step scaling?**

A) It's cheaper  
B) Automatically adjusts to maintain a target metric value  
C) Scales faster  
D) Requires less configuration

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Automatically adjusts to maintain a target metric value**

Target tracking scaling automatically calculates the scaling adjustment needed to maintain the target metric (e.g., 70% CPU). It's simpler to configure and responds more smoothly than step scaling.
</details>

---

### Question 5: Aurora vs RDS
**When should you choose Aurora over standard RDS?**

A) For development environments  
B) When you need high performance and automatic storage scaling  
C) For smaller databases  
D) When cost is the primary concern

<details>
<summary>Click to reveal answer</summary>

**Answer: B) When you need high performance and automatic storage scaling**

Aurora offers up to 5x the performance of standard MySQL and 3x PostgreSQL, with automatic storage scaling up to 128TB. It's ideal for high-performance production workloads.
</details>

---

### Question 6: Terraform Modules
**What is the main benefit of creating Terraform modules for AWS?**

A) Faster execution  
B) Reusable, consistent infrastructure patterns across projects  
C) Required by AWS  
D) Better security

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Reusable, consistent infrastructure patterns across projects**

Modules encapsulate infrastructure patterns (like a VPC with standard configuration) that can be reused across multiple projects, ensuring consistency and reducing duplication.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [Auto Scaling User Guide](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)
- [RDS User Guide](https://docs.aws.amazon.com/rds/latest/userguide/)
- [CloudFront Developer Guide](https://docs.aws.amazon.com/cloudfront/latest/developerguide/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### AWS Terraform Registry
- [AWS Provider Modules](https://registry.terraform.io/namespaces/terraform-aws-modules)
- [terraform-aws-vpc](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws)
- [terraform-aws-ec2-instance](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws)

### Next Steps
- **Previous Course**: [AWS-203: Security & Storage](../AWS-203-security-storage/README.md)
- **Optional**: [AZ-200: Azure with Terraform](../../AZ-200-terraform/README.md)
- **Advanced**: [MC-300: Multi-Cloud Architecture](../../MC-300-multi-cloud/README.md)

---

## 🎉 AWS-200 Complete!

**Congratulations on completing AWS-200: AWS with Terraform!**

You've learned:
- ✅ AWS authentication and provider configuration
- ✅ VPC, subnets, and networking
- ✅ EC2 instances and security groups
- ✅ S3, EBS, IAM, and encryption
- ✅ Auto Scaling, RDS, and CloudFront
- ✅ Production-ready patterns

**You're now ready to build production AWS infrastructure with Terraform!** 🚀

---

*Part of the [Hashi-Training](../../../README.md) curriculum - AWS-200: AWS with Terraform*
---

## 🔄 AWS Provider v6 Changes

> **This module uses `hashicorp/aws ~> 6.0`** (upgraded from 5.x). The following breaking changes from the [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade) are relevant to this module:

### `aws_launch_template` — `elastic_gpu_specifications` and `elastic_inference_accelerator` removed

These attributes have been removed in v6 (both services reached End of Life):

```hcl
# ❌ Removed in v6 — do not use
resource "aws_launch_template" "web" {
  elastic_gpu_specifications { type = "eg1.medium" }       # removed
  elastic_inference_accelerator { type = "eia1.medium" }   # removed
}

# ✅ v6: simply omit these blocks
resource "aws_launch_template" "web" {
  name_prefix   = "my-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
```

The example in this module does not use these attributes.

### `aws_launch_template` — `user_data` base64 encoding (best practice)

Launch templates use `user_data` as base64-encoded content. In v6, `aws_instance.user_data` is stored in cleartext — use `base64encode()` for launch templates:

```hcl
# ✅ Correct for launch templates (base64 encoded)
resource "aws_launch_template" "web" {
  user_data = base64encode(<<-EOT
    #!/bin/bash
    # Do NOT include passwords or secrets here
    apt-get update -y
  EOT
  )
}
```

The example in this module already uses `base64encode()`. See `example/main.tf`.

### `aws_security_group` — inline rules deprecated

Inline `ingress`/`egress` blocks are deprecated in v6. See AWS-202 for the modern `aws_vpc_security_group_ingress_rule` approach. The example retains inline rules for training simplicity with a deprecation comment.

### `data.aws_ami` — `owners` now required with `most_recent = true`

In v6, `most_recent = true` without `owners` causes an error. The example already includes `owners = ["099720109477"]`.

### `aws_lb_target_group` — `preserve_client_ip` TypeNullableBool

If you use `preserve_client_ip`, ensure the value is `true`, `false`, or `""` — not `0` or `1`:

```hcl
# ✅ v6: use boolean values
resource "aws_lb_target_group" "web" {
  preserve_client_ip = "true"   # string "true"/"false" or omit entirely
}
```

**Reference**: [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade)
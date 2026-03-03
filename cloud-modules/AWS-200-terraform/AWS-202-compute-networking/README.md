# AWS-202: Compute & Networking

**Course**: AWS-200 AWS with Terraform  
**Module**: AWS-202  
**Duration**: 2 hours  
**Prerequisites**: AWS-201 (Setup & Authentication)  
**Difficulty**: Intermediate

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [VPC Architecture](#vpc-architecture)
4. [Subnets and Routing](#subnets-and-routing)
5. [Security Groups](#security-groups)
6. [EC2 Instances](#ec2-instances)
7. [Key Pairs and SSH Access](#key-pairs-and-ssh-access)
8. [Elastic IPs and Load Balancers](#elastic-ips-and-load-balancers)
9. [Best Practices](#best-practices)
10. [Hands-On Labs](#hands-on-labs)
11. [Troubleshooting](#troubleshooting)
12. [Checkpoint Quiz](#checkpoint-quiz)
13. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course teaches you how to build AWS networking infrastructure and deploy EC2 instances using Terraform. You'll create VPCs, subnets, security groups, and virtual machines following AWS best practices.

### What You'll Build

By the end of this course, you'll be able to:
- Design and implement VPC architecture
- Create public and private subnets
- Configure routing tables and internet gateways
- Deploy EC2 instances with proper security
- Implement security groups for network access control

### Course Structure

```
AWS-202-compute-networking/
├── README.md                          # This file
└── example/
    ├── main.tf                        # Main configuration
    ├── vpc.tf                         # VPC and networking
    ├── ec2.tf                         # EC2 instances
    ├── security-groups.tf             # Security groups
    ├── variables.tf                   # Input variables
    ├── outputs.tf                     # Output values
    └── versions.tf                    # Version constraints
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Design VPC Architecture**
   - Create VPCs with appropriate CIDR blocks
   - Plan subnet layout (public/private)
   - Configure internet and NAT gateways

2. **Implement Subnets and Routing**
   - Create public and private subnets
   - Configure route tables
   - Associate subnets with route tables

3. **Configure Security Groups**
   - Create security groups with rules
   - Implement least-privilege network access
   - Reference security groups in resources

4. **Deploy EC2 Instances**
   - Launch instances with proper configuration
   - Use AMI data sources
   - Configure instance types and storage

5. **Manage Access**
   - Create and use key pairs
   - Configure SSH access
   - Use Systems Manager Session Manager

---

## 🌐 VPC Architecture

### What is a VPC?

A Virtual Private Cloud (VPC) is your isolated network in AWS:

```
AWS Region (us-east-1)
└── VPC (10.0.0.0/16)
    ├── Availability Zone A (us-east-1a)
    │   ├── Public Subnet (10.0.1.0/24)
    │   └── Private Subnet (10.0.10.0/24)
    ├── Availability Zone B (us-east-1b)
    │   ├── Public Subnet (10.0.2.0/24)
    │   └── Private Subnet (10.0.20.0/24)
    └── Internet Gateway
```

### Creating a VPC

```hcl
# vpc.tf

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}
```

### Variables

```hcl
# variables.tf
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```

---

## 🔀 Subnets and Routing

### Public Subnets

```hcl
# Public subnets (internet accessible)
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Type = "public"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
```

### Private Subnets

```hcl
# Private subnets (no direct internet access)
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
    Type = "private"
  }
}
```

### Route Tables

```hcl
# Public route table (routes to internet gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway for private subnet internet access
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name = "${var.project_name}-nat"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# Private route table (routes to NAT gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

---

## 🔒 Security Groups

> **⚠️ AWS Provider v6 Note**: Inline `ingress`/`egress` blocks inside `aws_security_group` are **deprecated** in v6. The modern approach uses separate resources:
> - `aws_vpc_security_group_ingress_rule` — for inbound rules
> - `aws_vpc_security_group_egress_rule` — for outbound rules
>
> Inline rules still work in v6 but will be removed in a future major version. The examples below use inline rules for readability. For new production code, prefer the separate rule resources.

### What Are Security Groups?

Security groups act as virtual firewalls for EC2 instances:
- **Stateful**: Return traffic is automatically allowed
- **Allow rules only**: No explicit deny rules
- **Applied to instances**: Not subnets (that's NACLs)

### Web Server Security Group

```hcl
# security-groups.tf

# Web server security group
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id
  
  # HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }
  
  # HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }
  
  # SSH from specific IP (your IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
    description = "SSH from admin"
  }
  
  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# Application server security group (private)
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.main.id
  
  # Allow from web servers only
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
    description     = "App port from web servers"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-app-sg"
  }
}
```

### Security Group Rules (Separate Resource)

```hcl
# Alternative: separate security group rules
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for databases"
  vpc_id      = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
  description              = "PostgreSQL from app servers"
}
```

---

## 💻 EC2 Instances

### AMI Data Source

```hcl
# ec2.tf

# Find latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Find latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
```

### Basic EC2 Instance

```hcl
# Web server instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[0].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.main.key_name
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
  EOF
  )
  
  tags = {
    Name = "${var.project_name}-web"
    Role = "web-server"
  }
}
```

### Multiple Instances with for_each

```hcl
# Multiple web servers
variable "web_servers" {
  description = "Web server configurations"
  type = map(object({
    instance_type = string
    subnet_index  = number
  }))
  default = {
    web-1 = { instance_type = "t3.micro", subnet_index = 0 }
    web-2 = { instance_type = "t3.micro", subnet_index = 1 }
  }
}

resource "aws_instance" "web_fleet" {
  for_each = var.web_servers
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.public[each.value.subnet_index].id
  
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.main.key_name
  
  tags = {
    Name = "${var.project_name}-${each.key}"
  }
}
```

### Instance with IAM Role

```hcl
# IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"
  
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
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.private[0].id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  
  vpc_security_group_ids = [aws_security_group.app.id]
  
  tags = {
    Name = "${var.project_name}-app"
  }
}
```

---

## 🔑 Key Pairs and SSH Access

### Creating Key Pairs

```hcl
# Generate SSH key pair
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.main.public_key_openssh
}

# Save private key locally
resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0600"
}
```

### Using Existing Key Pair

```hcl
# Use existing public key
resource "aws_key_pair" "existing" {
  key_name   = "${var.project_name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
```

---

## ⚖️ Elastic IPs and Load Balancers

### Elastic IP

```hcl
# Elastic IP for web server
resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"
  
  tags = {
    Name = "${var.project_name}-web-eip"
  }
}
```

### Application Load Balancer

```hcl
# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id
  
  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_target_group_attachment" "web" {
  for_each = aws_instance.web_fleet
  
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = each.value.id
  port             = 80
}
```

### Outputs

```hcl
# outputs.tf
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "web_instance_public_ip" {
  description = "Web server public IP"
  value       = aws_eip.web.public_ip
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = aws_lb.main.dns_name
}
```

---

## ✅ Best Practices

### 1. Multi-AZ Deployment

Always deploy across multiple availability zones:
```hcl
# Use all available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count             = min(length(data.aws_availability_zones.available.names), 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  # ...
}
```

### 2. Private Subnets for Applications

```hcl
# Web servers in public subnets (need internet access)
# App servers in private subnets (no direct internet)
# Databases in private subnets (most restricted)
```

### 3. Security Group Layering

```
Internet → ALB SG → Web SG → App SG → DB SG
```

### 4. Use Data Sources for AMIs

```hcl
# Always use data sources, never hardcode AMI IDs
data "aws_ami" "ubuntu" {
  most_recent = true
  # ...
}
```

### 5. Enable Encryption

```hcl
resource "aws_instance" "web" {
  root_block_device {
    encrypted = true  # Always encrypt
  }
}
```

---

## 🔬 Hands-On Labs

### Lab 1: VPC and Subnets (20 minutes)

**Objective**: Create a VPC with public and private subnets across two AZs.

**Tasks**:
1. Create VPC with CIDR 10.0.0.0/16
2. Create 2 public subnets (10.0.1.0/24, 10.0.2.0/24)
3. Create 2 private subnets (10.0.10.0/24, 10.0.20.0/24)
4. Create internet gateway
5. Configure route tables
6. Verify connectivity

**Expected Output**:
- VPC created with DNS enabled
- 4 subnets across 2 AZs
- Public subnets route to internet gateway

---

### Lab 2: EC2 Web Server (25 minutes)

**Objective**: Deploy an Nginx web server in the public subnet.

**Tasks**:
1. Create security group allowing HTTP/HTTPS/SSH
2. Create key pair
3. Launch EC2 instance with Nginx user data
4. Assign Elastic IP
5. Verify web server is accessible

**Expected Output**:
- EC2 instance running in public subnet
- Nginx serving default page
- Accessible via Elastic IP on port 80

---

### Lab 3: Multi-Tier Architecture (30 minutes)

**Objective**: Build a complete 3-tier architecture (web, app, database).

**Tasks**:
1. Deploy web servers in public subnets
2. Deploy app servers in private subnets
3. Configure security groups for each tier
4. Set up Application Load Balancer
5. Verify traffic flows correctly

**Expected Output**:
- Load balancer distributing traffic to web servers
- Web servers can reach app servers
- App servers isolated from internet
- Security groups enforce tier separation

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Instance Not Accessible

**Problem**: Can't SSH to EC2 instance

**Solutions**:
```bash
# Check security group allows SSH from your IP
aws ec2 describe-security-groups --group-ids sg-xxx

# Check instance is in public subnet
aws ec2 describe-instances --instance-ids i-xxx

# Check key pair is correct
ssh -i key.pem ubuntu@IP_ADDRESS
```

#### 2. No Internet Access

**Problem**: Instance can't reach internet

**Solutions**:
- Public subnet: Check internet gateway and route table
- Private subnet: Check NAT gateway and route table
- Verify security group allows outbound traffic

#### 3. AMI Not Found

**Problem**: `InvalidAMIID.NotFound`

**Solution**:
```hcl
# Verify AMI exists in your region
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  # ...
}
```

---

## 📝 Checkpoint Quiz

### Question 1: VPC Subnets
**What makes a subnet "public" in AWS?**

A) It has a public IP address  
B) It has a route to an internet gateway  
C) It's in a public availability zone  
D) It has no security groups

<details>
<summary>Click to reveal answer</summary>

**Answer: B) It has a route to an internet gateway**

A subnet is public when its route table has a route directing internet-bound traffic (0.0.0.0/0) to an internet gateway.
</details>

---

### Question 2: Security Groups
**Security groups in AWS are:**

A) Stateless - you must allow both inbound and outbound  
B) Stateful - return traffic is automatically allowed  
C) Applied at the subnet level  
D) Only for inbound traffic

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Stateful - return traffic is automatically allowed**

Security groups are stateful. If you allow inbound traffic on port 80, the return traffic is automatically allowed without needing an explicit outbound rule.
</details>

---

### Question 3: AMI Selection
**Why should you use a data source to find AMIs instead of hardcoding AMI IDs?**

A) Data sources are faster  
B) AMI IDs are region-specific and change with updates  
C) Hardcoded IDs don't work  
D) Data sources are required by AWS

<details>
<summary>Click to reveal answer</summary>

**Answer: B) AMI IDs are region-specific and change with updates**

AMI IDs differ between regions and change when new versions are released. Data sources always find the latest AMI matching your criteria, making your code portable and up-to-date.
</details>

---

### Question 4: NAT Gateway
**What is the purpose of a NAT Gateway?**

A) Provides internet access to public subnets  
B) Allows private subnet instances to initiate outbound internet connections  
C) Replaces the internet gateway  
D) Provides DNS resolution

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Allows private subnet instances to initiate outbound internet connections**

A NAT Gateway allows instances in private subnets to initiate outbound connections to the internet (e.g., for updates) while preventing inbound connections from the internet.
</details>

---

### Question 5: Load Balancer
**Which load balancer type should you use for HTTP/HTTPS web applications?**

A) Classic Load Balancer  
B) Network Load Balancer  
C) Application Load Balancer  
D) Gateway Load Balancer

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Application Load Balancer**

Application Load Balancer (ALB) operates at Layer 7 (HTTP/HTTPS) and supports path-based routing, host-based routing, and other HTTP-specific features ideal for web applications.
</details>

---

### Question 6: Multi-AZ
**Why should you deploy resources across multiple availability zones?**

A) It's cheaper  
B) For high availability and fault tolerance  
C) Required by AWS  
D) Better performance

<details>
<summary>Click to reveal answer</summary>

**Answer: B) For high availability and fault tolerance**

Deploying across multiple AZs ensures your application remains available if one AZ experiences an outage. Each AZ is an isolated data center with independent power and networking.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/latest/userguide/)
- [AWS Provider EC2 Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)

### Next Steps
- **Next Course**: [AWS-203: Security & Storage](../AWS-203-security-storage/README.md)
- **Previous Course**: [AWS-201: Setup & Authentication](../AWS-201-setup-auth/README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - AWS-200: AWS with Terraform*
---

## 🔄 AWS Provider v6 Changes

> **This module uses `hashicorp/aws ~> 6.0`** (upgraded from 5.x). The following breaking changes from the [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade) are relevant to this module:

### `aws_instance` — `user_data` stored in cleartext

In v6, `user_data` is no longer hashed — it is stored in cleartext in the Terraform state file and plan output.

```hcl
# ⚠️ v6 change: user_data is stored in cleartext
resource "aws_instance" "web" {
  # ...
  user_data = <<-EOT
    #!/bin/bash
    apt-get update -y
    # DO NOT include passwords or secrets here — visible in state file!
  EOT
}

# ✅ For pre-encoded content, use user_data_base64 instead
resource "aws_instance" "web" {
  user_data_base64 = base64encode(local.user_data_script)
}
```

The example in this module already includes this warning. See `example/main.tf`.

### `data.aws_ami` — `owners` now required with `most_recent = true`

In v6, using `most_recent = true` without an `owners` filter or an `image-id`/`owner-id` filter causes an **error** (was a warning in v5).

```hcl
# ❌ v5: warning only
data "aws_ami" "ubuntu" {
  most_recent = true
  filter { name = "name"; values = ["ubuntu-*"] }
}

# ✅ v6: owners required
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical — required in v6
  filter { name = "name"; values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] }
}
```

The example in this module already includes `owners`. See `example/main.tf`.

### `aws_security_group` — inline rules deprecated

Inline `ingress`/`egress` blocks inside `aws_security_group` are deprecated in v6. The modern approach uses separate resources:

```hcl
# ❌ Deprecated in v6 (still works but will be removed in v7)
resource "aws_security_group" "web" {
  ingress { from_port = 80; to_port = 80; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
}

# ✅ Modern v6 approach
resource "aws_security_group" "web" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
```

The example retains inline rules for training simplicity with a deprecation comment.

**Reference**: [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade)
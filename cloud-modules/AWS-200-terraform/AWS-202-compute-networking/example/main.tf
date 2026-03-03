# AWS-202: Compute & Networking
# Demonstrates: VPC, subnets, internet gateway, route tables, security groups, EC2
# Provider: hashicorp/aws
# Run: terraform init && terraform apply
#
# Prerequisites: AWS credentials configured (see AWS-201)
# Cost: EC2 t3.micro is free tier eligible

terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Course      = "AWS-202"
      Environment = var.environment
      Project     = var.project_name
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# VPC
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Internet Gateway
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Public Subnet
# ─────────────────────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Type = "public"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Route Table
# ─────────────────────────────────────────────────────────────────────────────

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

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Security Group
# ─────────────────────────────────────────────────────────────────────────────

# AWS provider v6: inline ingress/egress blocks in aws_security_group are deprecated.
# The modern approach uses separate aws_vpc_security_group_ingress_rule and
# aws_vpc_security_group_egress_rule resources. Inline rules still work in v6
# but will be removed in a future major version. For new production code, prefer
# the separate rule resources. This example retains inline rules for simplicity.
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# EC2 Instance
# ─────────────────────────────────────────────────────────────────────────────

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_pair_name

  # AWS provider v6: user_data is stored in cleartext (no longer hashed).
  # Do NOT include passwords or sensitive data here — it will be visible in
  # the Terraform state file and plan output. Use user_data_base64 for
  # pre-encoded content, or pass secrets via SSM Parameter Store / Secrets Manager.
  user_data = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>Hello from Terraform AWS-202!</h1>" > /var/www/html/index.html
  EOT

  tags = {
    Name = "${var.project_name}-web"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.web.public_dns
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.web.public_ip}"
}
# Tests for AWS-202: Compute & Networking
# Uses mock_provider to test configuration without real AWS credentials.
# Validates VPC, subnet, security group, and EC2 instance configuration.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
      state = "available"
    }
  }

  mock_data "aws_ami" {
    defaults = {
      id           = "ami-0mock1234567890ab"
      name         = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240101"
      owner_id     = "099720109477"
      architecture = "x86_64"
    }
  }
}

# ---------------------------------------------------------------
# Test 1: Default variables produce a valid plan
# ---------------------------------------------------------------
run "default_variables" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR should be 10.0.0.0/16 by default"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "VPC should have DNS hostnames enabled"
  }

  assert {
    condition     = aws_subnet.public.cidr_block == "10.0.1.0/24"
    error_message = "Public subnet CIDR should be 10.0.1.0/24 by default"
  }

  assert {
    condition     = aws_subnet.public.map_public_ip_on_launch == true
    error_message = "Public subnet should auto-assign public IPs"
  }
}

# ---------------------------------------------------------------
# Test 2: Security group has correct ingress rules
# ---------------------------------------------------------------
run "security_group_rules" {
  command = plan

  assert {
    condition     = aws_security_group.web.name == "aws202-web-sg"
    error_message = "Security group name should use project_name prefix"
  }

  assert {
    condition     = length(aws_security_group.web.ingress) == 2
    error_message = "Security group should have 2 ingress rules (SSH + HTTP)"
  }
}

# ---------------------------------------------------------------
# Test 3: EC2 instance uses mocked AMI
# ---------------------------------------------------------------
run "ec2_instance_config" {
  command = plan

  assert {
    condition     = aws_instance.web.ami == "ami-0mock1234567890ab"
    error_message = "EC2 instance should use the mocked AMI ID"
  }

  assert {
    condition     = aws_instance.web.instance_type == "t3.micro"
    error_message = "EC2 instance type should be t3.micro by default"
  }
}

# ---------------------------------------------------------------
# Test 4: Custom project name propagates to resource names
# ---------------------------------------------------------------
run "custom_project_name" {
  command = plan

  variables {
    project_name = "myproject"
    environment  = "staging"
  }

  assert {
    condition     = aws_vpc.main.tags["Name"] == "myproject-vpc"
    error_message = "VPC name tag should use custom project_name"
  }

  assert {
    condition     = aws_security_group.web.name == "myproject-web-sg"
    error_message = "Security group name should use custom project_name"
  }
}

# ---------------------------------------------------------------
# Test 5: Custom instance type is accepted
# ---------------------------------------------------------------
run "custom_instance_type" {
  command = plan

  variables {
    instance_type = "t3.small"
  }

  assert {
    condition     = aws_instance.web.instance_type == "t3.small"
    error_message = "EC2 instance type should reflect the custom variable"
  }
}
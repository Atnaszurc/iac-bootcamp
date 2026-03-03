# Tests for AWS-204: Advanced Patterns
# Uses mock_provider to test configuration without real AWS credentials.
# Validates Auto Scaling Group, Application Load Balancer, and Launch Template.

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
    error_message = "VPC CIDR should be 10.0.0.0/16"
  }

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Should create 2 public subnets across availability zones"
  }

  assert {
    condition     = aws_autoscaling_group.web.desired_capacity == 2
    error_message = "ASG desired capacity should be 2 by default"
  }
}

# ---------------------------------------------------------------
# Test 2: Load balancer is configured correctly
# ---------------------------------------------------------------
run "load_balancer_config" {
  command = plan

  assert {
    condition     = aws_lb.main.internal == false
    error_message = "ALB should be internet-facing (not internal)"
  }

  assert {
    condition     = aws_lb.main.load_balancer_type == "application"
    error_message = "Load balancer type should be 'application'"
  }

  assert {
    condition     = aws_lb_target_group.web.port == 80
    error_message = "Target group should listen on port 80"
  }

  assert {
    condition     = aws_lb_target_group.web.protocol == "HTTP"
    error_message = "Target group protocol should be HTTP"
  }
}

# ---------------------------------------------------------------
# Test 3: Launch template uses mocked AMI
# ---------------------------------------------------------------
run "launch_template_config" {
  command = plan

  assert {
    condition     = aws_launch_template.web.image_id == "ami-0mock1234567890ab"
    error_message = "Launch template should use the mocked AMI ID"
  }

  assert {
    condition     = aws_launch_template.web.instance_type == "t3.micro"
    error_message = "Launch template instance type should be t3.micro by default"
  }
}

# ---------------------------------------------------------------
# Test 4: ASG scaling limits are correct
# ---------------------------------------------------------------
run "asg_scaling_limits" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.web.min_size == 1
    error_message = "ASG minimum size should be 1 by default"
  }

  assert {
    condition     = aws_autoscaling_group.web.max_size == 4
    error_message = "ASG maximum size should be 4 by default"
  }
}

# ---------------------------------------------------------------
# Test 5: Custom ASG capacity settings
# ---------------------------------------------------------------
run "custom_asg_capacity" {
  command = plan

  variables {
    asg_desired = 3
    asg_min     = 2
    asg_max     = 6
  }

  assert {
    condition     = aws_autoscaling_group.web.desired_capacity == 3
    error_message = "ASG desired capacity should reflect custom variable"
  }

  assert {
    condition     = aws_autoscaling_group.web.min_size == 2
    error_message = "ASG min size should reflect custom variable"
  }

  assert {
    condition     = aws_autoscaling_group.web.max_size == 6
    error_message = "ASG max size should reflect custom variable"
  }
}

# ---------------------------------------------------------------
# Test 6: Security groups are separated (ALB vs instances)
# ---------------------------------------------------------------
run "security_group_separation" {
  command = plan

  assert {
    condition     = aws_security_group.alb.name == "aws204-alb-sg"
    error_message = "ALB security group name should use project_name prefix"
  }

  assert {
    condition     = aws_security_group.instances.name == "aws204-instances-sg"
    error_message = "Instances security group name should use project_name prefix"
  }
}
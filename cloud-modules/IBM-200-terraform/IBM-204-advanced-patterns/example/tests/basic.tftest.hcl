mock_provider "ibm" {
  mock_data "ibm_resource_group" {
    defaults = {
      id   = "6f5d9c8a-1234-4abc-9def-1234567890ab"
      name = "Default"
    }
  }

  mock_data "ibm_is_image" {
    defaults = {
      id   = "r006-12345678-1234-1234-1234-123456789abc"
      name = "ibm-ubuntu-22-04-3-minimal-amd64-1"
    }
  }

  mock_resource "ibm_is_vpc" {
    defaults = {
      id                     = "r006-vpc-12345678-1234-1234-1234-123456789abc"
      name                   = "dev-training-vpc"
      default_security_group = "r006-sg-default-12345678"
    }
  }

  mock_resource "ibm_is_vpc_address_prefix" {
    defaults = {
      id   = "r006-prefix-12345678-1234-1234-1234-123456789abc"
      cidr = "10.240.0.0/20"
    }
  }

  mock_resource "ibm_is_public_gateway" {
    defaults = {
      id   = "r006-gw-12345678-1234-1234-1234-123456789abc"
      name = "dev-training-gateway-zone1"
    }
  }

  mock_resource "ibm_is_subnet" {
    defaults = {
      id              = "r006-subnet-12345678-1234-1234-1234-123456789abc"
      ipv4_cidr_block = "10.240.0.0/24"
    }
  }

  mock_resource "ibm_is_security_group" {
    defaults = {
      id   = "r006-sg-12345678-1234-1234-1234-123456789abc"
      name = "dev-training-lb-sg"
    }
  }

  mock_resource "ibm_is_security_group_rule" {
    defaults = {
      id = "r006-sgr-12345678-1234-1234-1234-123456789abc"
    }
  }

  mock_resource "ibm_is_ssh_key" {
    defaults = {
      id   = "r006-key-12345678-1234-1234-1234-123456789abc"
      name = "dev-training-ssh-key"
    }
  }

  mock_resource "ibm_is_instance" {
    defaults = {
      id   = "r006-vsi-12345678-1234-1234-1234-123456789abc"
      name = "dev-training-web-us-south-1-1"
    }
  }

  mock_resource "ibm_is_lb" {
    defaults = {
      id         = "r006-lb-12345678-1234-1234-1234-123456789abc"
      hostname   = "12345678-us-south.lb.appdomain.cloud"
      public_ips = ["52.116.128.100"]
    }
  }

  mock_resource "ibm_is_lb_pool" {
    defaults = {
      id = "r006-pool-12345678-1234-1234-1234-123456789abc"
    }
  }

  mock_resource "ibm_is_lb_pool_member" {
    defaults = {
      id = "r006-member-12345678-1234-1234-1234-123456789abc"
    }
  }

  mock_resource "ibm_is_lb_listener" {
    defaults = {
      id = "r006-listener-12345678-1234-1234-1234-123456789abc"
    }
  }

  mock_resource "ibm_resource_instance" {
    defaults = {
      id   = "crn:v1:bluemix:public:kms:us-south:a/1234567890abcdef1234567890abcdef:12345678-1234-1234-1234-123456789abc::"
      guid = "12345678-1234-1234-1234-123456789abc"
    }
  }

  mock_resource "ibm_kp_key" {
    defaults = {
      id  = "crn:v1:bluemix:public:kms:us-south:a/1234567890abcdef1234567890abcdef:12345678-1234-1234-1234-123456789abc:key:key-12345678"
      crn = "crn:v1:bluemix:public:kms:us-south:a/1234567890abcdef1234567890abcdef:12345678-1234-1234-1234-123456789abc:key:key-12345678"
    }
  }

  mock_resource "ibm_iam_authorization_policy" {
    defaults = {
      id = "auth-policy-12345678"
    }
  }

  mock_resource "ibm_cos_bucket" {
    defaults = {
      id          = "crn:v1:bluemix:public:cloud-object-storage:global:a/1234::cos-12345678::bucket:dev-training-backups-abc12345"
      crn         = "crn:v1:bluemix:public:cloud-object-storage:global:a/1234::cos-12345678::bucket:dev-training-backups-abc12345"
      bucket_name = "dev-training-backups-abc12345"
    }
  }

  mock_resource "random_string" {
    defaults = {
      result = "abc12345"
    }
  }
}

variables {
  ibm_region                     = "us-south"
  resource_group_name            = "Default"
  environment                    = "dev"
  project_name                   = "training"
  deploy_compute                 = false
  deploy_load_balancer           = false
  deploy_key_protect             = false
  deploy_cos                     = false
  multi_zone                     = false
  image_name                     = "ibm-ubuntu-22-04-3-minimal-amd64-1"
  ssh_public_key                 = ""
  web_tier_instance_count        = 1
  web_tier_instance_profile      = "bx2-2x8"
  app_tier_instance_count        = 1
  app_tier_instance_profile      = "bx2-2x8"
  database_tier_instance_profile = "bx2-4x16"
  enable_ssh_access              = false
  ssh_allowed_cidr               = "10.0.0.0/8"
  lb_algorithm                   = "round_robin"
  lb_health_delay                = 5
  lb_health_retries              = 2
  lb_health_timeout              = 2
  lb_health_monitor_url          = "/health"
}

run "plan_networking_only" {
  command = apply

  assert {
    condition     = output.vpc_id != null
    error_message = "Expected VPC to be created."
  }

  assert {
    condition     = output.public_subnet_zone1_id != null
    error_message = "Expected public subnet zone 1."
  }

  assert {
    condition     = output.private_subnet_zone1_id != null
    error_message = "Expected private subnet zone 1."
  }

  assert {
    condition     = output.lb_security_group_id != null
    error_message = "Expected load balancer security group."
  }

  assert {
    condition     = output.web_security_group_id != null
    error_message = "Expected web tier security group."
  }

  assert {
    condition     = output.app_security_group_id != null
    error_message = "Expected app tier security group."
  }

  assert {
    condition     = output.database_security_group_id != null
    error_message = "Expected database tier security group."
  }

  assert {
    condition     = output.load_balancer_id == null
    error_message = "Expected no load balancer when deploy_load_balancer is false."
  }

  assert {
    condition     = output.architecture_summary.compute.deployed == false
    error_message = "Expected compute not deployed."
  }
}

run "plan_with_load_balancer" {
  command = apply

  variables {
    deploy_load_balancer = true
    deploy_compute       = true
    ssh_public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDExample test@example.com"
  }

  assert {
    condition     = output.load_balancer_id != null
    error_message = "Expected load balancer to be created."
  }

  assert {
    condition     = output.load_balancer_hostname != null
    error_message = "Expected load balancer hostname."
  }

  assert {
    condition     = output.load_balancer_url != null
    error_message = "Expected load balancer URL."
  }

  assert {
    condition     = length(output.web_instances_zone1) == 1
    error_message = "Expected 1 web instance in zone 1."
  }

  assert {
    condition     = output.architecture_summary.load_balancer.deployed == true
    error_message = "Expected load balancer deployed in summary."
  }
}

run "plan_multi_zone" {
  command = apply

  variables {
    deploy_compute       = true
    deploy_load_balancer = true
    multi_zone           = true
    ssh_public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDExample test@example.com"
  }

  assert {
    condition     = length(output.web_instances_zone1) == 1
    error_message = "Expected web instances in zone 1."
  }

  assert {
    condition     = length(output.web_instances_zone2) == 1
    error_message = "Expected web instances in zone 2."
  }

  assert {
    condition     = output.database_instance_zone2 != null
    error_message = "Expected database replica in zone 2."
  }

  assert {
    condition     = output.architecture_summary.compute.multi_zone == true
    error_message = "Expected multi-zone in summary."
  }
}

run "plan_full_stack" {
  command = apply

  variables {
    deploy_compute       = true
    deploy_load_balancer = true
    deploy_key_protect   = true
    deploy_cos           = true
    multi_zone           = true
    ssh_public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDExample test@example.com"
  }

  assert {
    condition     = output.vpc_id != null
    error_message = "Expected VPC."
  }

  assert {
    condition     = output.load_balancer_id != null
    error_message = "Expected load balancer."
  }

  assert {
    condition     = output.key_protect_instance_id != null
    error_message = "Expected Key Protect."
  }

  assert {
    condition     = output.cos_instance_id != null
    error_message = "Expected COS."
  }

  assert {
    condition     = output.cos_bucket_name != null
    error_message = "Expected COS bucket."
  }

  assert {
    condition     = output.architecture_summary.encryption.key_protect_deployed == true
    error_message = "Expected Key Protect in summary."
  }

  assert {
    condition     = output.architecture_summary.encryption.cos_encrypted == true
    error_message = "Expected COS encryption in summary."
  }

  assert {
    condition     = output.architecture_summary.compute.web_count == 2
    error_message = "Expected 2 web instances (1 per zone)."
  }

  assert {
    condition     = output.architecture_summary.compute.db_count == 2
    error_message = "Expected 2 database instances (primary + replica)."
  }
}

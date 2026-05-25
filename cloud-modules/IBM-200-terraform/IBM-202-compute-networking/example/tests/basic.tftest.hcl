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
      os   = "ubuntu-22-04-amd64"
    }
  }

  mock_data "ibm_is_ssh_keys" {
    defaults = {
      keys = []
    }
  }

  mock_resource "ibm_is_vpc" {
    defaults = {
      id                        = "r006-vpc-12345678-1234-1234-1234-123456789abc"
      crn                       = "crn:v1:bluemix:public:is:us-south:a/1234567890abcdef::vpc:r006-vpc-12345678-1234-1234-1234-123456789abc"
      name                      = "dev-training-vpc"
      resource_group            = "6f5d9c8a-1234-4abc-9def-1234567890ab"
      classic_access            = false
      address_prefix_management = "auto"
      default_network_acl       = "r006-acl-12345678-1234-1234-1234-123456789abc"
      default_security_group    = "r006-sg-12345678-1234-1234-1234-123456789abc"
      default_routing_table     = "r006-rt-12345678-1234-1234-1234-123456789abc"
    }
  }

  mock_resource "ibm_is_public_gateway" {
    defaults = {
      id             = "r006-gw-12345678-1234-1234-1234-123456789abc"
      name           = "dev-training-gateway-zone1"
      vpc            = "r006-vpc-12345678-1234-1234-1234-123456789abc"
      zone           = "us-south-1"
      resource_group = "6f5d9c8a-1234-4abc-9def-1234567890ab"
      floating_ip = {
        id      = "r006-fip-gw-12345678-1234-1234-1234-123456789abc"
        address = "52.116.128.100"
      }
    }
  }

  mock_resource "ibm_is_subnet" {
    defaults = {
      id                           = "r006-subnet-12345678-1234-1234-1234-123456789abc"
      name                         = "dev-training-subnet-zone1"
      vpc                          = "r006-vpc-12345678-1234-1234-1234-123456789abc"
      zone                         = "us-south-1"
      ipv4_cidr_block              = "10.240.0.0/24"
      total_ipv4_address_count     = 256
      available_ipv4_address_count = 251
      resource_group               = "6f5d9c8a-1234-4abc-9def-1234567890ab"
      public_gateway               = "r006-gw-12345678-1234-1234-1234-123456789abc"
    }
  }

  mock_resource "ibm_is_ssh_key" {
    defaults = {
      id             = "r006-key-12345678-1234-1234-1234-123456789abc"
      name           = "dev-training-ssh-key"
      type           = "rsa"
      length         = 4096
      fingerprint    = "SHA256:abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJK"
      resource_group = "6f5d9c8a-1234-4abc-9def-1234567890ab"
    }
  }

  mock_resource "ibm_is_instance" {
    defaults = {
      id             = "r006-vsi-12345678-1234-1234-1234-123456789abc"
      name           = "dev-training-vsi-zone1"
      vpc            = "r006-vpc-12345678-1234-1234-1234-123456789abc"
      zone           = "us-south-1"
      profile        = "bx2-2x8"
      image          = "r006-12345678-1234-1234-1234-123456789abc"
      resource_group = "6f5d9c8a-1234-4abc-9def-1234567890ab"
      status         = "running"
      vcpu = {
        architecture = "amd64"
        count        = 2
      }
      memory = 8
    }
  }

  mock_resource "ibm_is_floating_ip" {
    defaults = {
      id             = "r006-fip-12345678-1234-1234-1234-123456789abc"
      name           = "dev-training-fip-zone1"
      address        = "52.116.128.50"
      zone           = "us-south-1"
      target         = "r006-nic-12345678-1234-1234-1234-123456789abc"
      resource_group = "6f5d9c8a-1234-4abc-9def-1234567890ab"
    }
  }
}

variables {
  ibm_region          = "us-south"
  resource_group_name = "Default"
  environment         = "dev"
  project_name        = "training"
  image_name          = "ibm-ubuntu-22-04-3-minimal-amd64-1"
  instance_profile    = "bx2-2x8"
  ssh_public_key      = ""
  create_instances    = false
  multi_zone          = false
  assign_floating_ip  = false
  user_data           = ""
}

run "plan_vpc_only" {
  command = apply

  assert {
    condition     = output.vpc_name == "dev-training-vpc"
    error_message = "Expected VPC name to match naming convention."
  }

  assert {
    condition     = output.vpc_id != null
    error_message = "Expected VPC ID to be set."
  }

  assert {
    condition     = output.subnet_zone1_id != null
    error_message = "Expected subnet zone 1 ID to be set."
  }

  assert {
    condition     = output.subnet_zone2_id != null
    error_message = "Expected subnet zone 2 ID to be set."
  }

  assert {
    condition     = output.public_gateway_id != null
    error_message = "Expected public gateway ID to be set."
  }

  assert {
    condition     = output.vsi_zone1_id == null
    error_message = "Expected no VSI to be created when create_instances is false."
  }

  assert {
    condition     = output.floating_ip == null
    error_message = "Expected no floating IP when instances are not created."
  }

  assert {
    condition     = output.zones_used.zone1 == "us-south-1"
    error_message = "Expected zone 1 to be us-south-1."
  }

  assert {
    condition     = output.zones_used.zone2 == "us-south-2"
    error_message = "Expected zone 2 to be us-south-2."
  }

  assert {
    condition     = length(output.common_tags) == 5
    error_message = "Expected 5 common tags."
  }

  assert {
    condition     = contains(output.common_tags, "training")
    error_message = "Expected common_tags to include 'training'."
  }

  assert {
    condition     = contains(output.common_tags, "module:ibm-202")
    error_message = "Expected common_tags to include 'module:ibm-202'."
  }
}

run "plan_with_instances" {
  command = apply

  variables {
    create_instances   = true
    ssh_public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDExample... test@example.com"
    assign_floating_ip = true
  }

  assert {
    condition     = output.vsi_zone1_id != null
    error_message = "Expected VSI zone 1 to be created when create_instances is true."
  }

  assert {
    condition     = output.vsi_zone1_private_ip != null
    error_message = "Expected VSI zone 1 to have a private IP."
  }

  assert {
    condition     = output.vsi_zone2_id == null
    error_message = "Expected no VSI in zone 2 when multi_zone is false."
  }

  assert {
    condition     = output.floating_ip != null
    error_message = "Expected floating IP to be assigned when assign_floating_ip is true."
  }

  assert {
    condition     = output.ssh_key_id != null
    error_message = "Expected SSH key to be created when ssh_public_key is provided."
  }

  assert {
    condition     = output.ssh_connection_command != null
    error_message = "Expected SSH connection command to be provided."
  }
}

run "plan_multi_zone" {
  command = apply

  variables {
    create_instances = true
    multi_zone       = true
    ssh_public_key   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDExample... test@example.com"
  }

  assert {
    condition     = output.vsi_zone1_id != null
    error_message = "Expected VSI zone 1 to be created."
  }

  assert {
    condition     = output.vsi_zone2_id != null
    error_message = "Expected VSI zone 2 to be created when multi_zone is true."
  }

  assert {
    condition     = output.vsi_zone2_private_ip != null
    error_message = "Expected VSI zone 2 to have a private IP."
  }
}

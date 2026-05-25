mock_provider "ibm" {
  mock_data "ibm_resource_group" {
    defaults = {
      id   = "6f5d9c8a-1234-4abc-9def-1234567890ab"
      name = "Default"
    }
  }

  mock_resource "ibm_is_vpc" {
    defaults = {
      id                     = "r006-vpc-12345678-1234-1234-1234-123456789abc"
      crn                    = "crn:v1:bluemix:public:is:us-south:a/1234567890abcdef::vpc:r006-vpc-12345678-1234-1234-1234-123456789abc"
      name                   = "dev-training-vpc"
      resource_group         = "6f5d9c8a-1234-4abc-9def-1234567890ab"
      default_security_group = "r006-sg-default-12345678-1234-1234-1234-123456789abc"
      default_network_acl    = "r006-acl-12345678-1234-1234-1234-123456789abc"
      default_routing_table  = "r006-rt-12345678-1234-1234-1234-123456789abc"
    }
  }

  mock_resource "ibm_is_subnet" {
    defaults = {
      id                       = "r006-subnet-12345678-1234-1234-1234-123456789abc"
      name                     = "dev-training-subnet"
      vpc                      = "r006-vpc-12345678-1234-1234-1234-123456789abc"
      zone                     = "us-south-1"
      ipv4_cidr_block          = "10.240.0.0/24"
      total_ipv4_address_count = 256
      resource_group           = "6f5d9c8a-1234-4abc-9def-1234567890ab"
    }
  }

  mock_resource "ibm_is_security_group" {
    defaults = {
      id             = "r006-sg-12345678-1234-1234-1234-123456789abc"
      name           = "dev-training-web-sg"
      vpc            = "r006-vpc-12345678-1234-1234-1234-123456789abc"
      resource_group = "6f5d9c8a-1234-4abc-9def-1234567890ab"
    }
  }

  mock_resource "ibm_is_security_group_rule" {
    defaults = {
      id        = "r006-sgr-12345678-1234-1234-1234-123456789abc"
      group     = "r006-sg-12345678-1234-1234-1234-123456789abc"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      protocol  = "tcp"
    }
  }

  mock_resource "ibm_resource_instance" {
    defaults = {
      id                = "crn:v1:bluemix:public:kms:us-south:a/1234567890abcdef1234567890abcdef:12345678-1234-1234-1234-123456789abc::"
      guid              = "12345678-1234-1234-1234-123456789abc"
      name              = "dev-training-kp"
      service           = "kms"
      plan              = "tiered-pricing"
      location          = "us-south"
      resource_group_id = "6f5d9c8a-1234-4abc-9def-1234567890ab"
      status            = "active"
    }
  }

  mock_resource "ibm_kp_key" {
    defaults = {
      id             = "crn:v1:bluemix:public:kms:us-south:a/1234567890abcdef1234567890abcdef:12345678-1234-1234-1234-123456789abc:key:key-12345678-1234-1234-1234-123456789abc"
      crn            = "crn:v1:bluemix:public:kms:us-south:a/1234567890abcdef1234567890abcdef:12345678-1234-1234-1234-123456789abc:key:key-12345678-1234-1234-1234-123456789abc"
      key_id         = "key-12345678-1234-1234-1234-123456789abc"
      key_name       = "dev-training-root-key"
      key_protect_id = "12345678-1234-1234-1234-123456789abc"
      standard_key   = false
      type           = "application/vnd.ibm.kms.key+json"
    }
  }

  mock_resource "ibm_iam_authorization_policy" {
    defaults = {
      id                  = "auth-policy-12345678-1234-1234-1234-123456789abc"
      source_service_name = "cloud-object-storage"
      target_service_name = "kms"
      roles               = ["Reader"]
    }
  }

  mock_resource "ibm_cos_bucket" {
    defaults = {
      id                   = "crn:v1:bluemix:public:cloud-object-storage:global:a/1234567890abcdef1234567890abcdef:cos-12345678-1234-1234-1234-123456789abc:bucket:dev-training-bucket-abc12345"
      crn                  = "crn:v1:bluemix:public:cloud-object-storage:global:a/1234567890abcdef1234567890abcdef:cos-12345678-1234-1234-1234-123456789abc:bucket:dev-training-bucket-abc12345"
      bucket_name          = "dev-training-bucket-abc12345"
      resource_instance_id = "crn:v1:bluemix:public:cloud-object-storage:global:a/1234567890abcdef1234567890abcdef:12345678-1234-1234-1234-123456789abc::"
      region_location      = "us-south"
      storage_class        = "standard"
    }
  }

  mock_resource "random_string" {
    defaults = {
      id     = "abc12345"
      result = "abc12345"
    }
  }
}

variables {
  ibm_region                = "us-south"
  resource_group_name       = "Default"
  environment               = "dev"
  project_name              = "training"
  allow_ssh_from_internet   = false
  ssh_allowed_cidr          = "0.0.0.0/0"
  allow_ping                = true
  enable_mysql_port         = false
  create_key_protect        = false
  key_protect_plan          = "tiered-pricing"
  create_cos                = false
  cos_plan                  = "standard"
  cos_storage_class         = "standard"
  enable_cos_encryption     = false
  enable_activity_tracking  = true
  enable_metrics_monitoring = true
  bucket_hard_quota_gb      = 0
  enable_lifecycle_policies = false
  archive_days              = 90
  expire_days               = 365
}

run "plan_security_groups_only" {
  command = apply

  assert {
    condition     = output.vpc_id != null
    error_message = "Expected VPC to be created."
  }

  assert {
    condition     = output.web_tier_security_group_id != null
    error_message = "Expected web tier security group to be created."
  }

  assert {
    condition     = output.app_tier_security_group_id != null
    error_message = "Expected app tier security group to be created."
  }

  assert {
    condition     = output.database_tier_security_group_id != null
    error_message = "Expected database tier security group to be created."
  }

  assert {
    condition     = output.key_protect_instance_id == null
    error_message = "Expected no Key Protect instance when create_key_protect is false."
  }

  assert {
    condition     = output.cos_instance_id == null
    error_message = "Expected no COS instance when create_cos is false."
  }

  assert {
    condition     = length(output.common_tags) == 5
    error_message = "Expected 5 common tags."
  }

  assert {
    condition     = contains(output.common_tags, "module:ibm-203")
    error_message = "Expected common_tags to include 'module:ibm-203'."
  }

  assert {
    condition     = output.security_architecture_summary.vpc_id != null
    error_message = "Expected security architecture summary to include VPC ID."
  }

  assert {
    condition     = output.security_architecture_summary.security_groups.web != null
    error_message = "Expected security architecture summary to include web security group."
  }

  assert {
    condition     = output.security_architecture_summary.encryption.key_protect_enabled == false
    error_message = "Expected Key Protect to be disabled."
  }
}

run "plan_with_key_protect" {
  command = apply

  variables {
    create_key_protect = true
  }

  assert {
    condition     = output.key_protect_instance_id != null
    error_message = "Expected Key Protect instance to be created."
  }

  assert {
    condition     = output.key_protect_instance_guid != null
    error_message = "Expected Key Protect instance GUID to be set."
  }

  assert {
    condition     = output.root_key_id != null
    error_message = "Expected root key to be created."
  }

  assert {
    condition     = output.security_architecture_summary.encryption.key_protect_enabled == true
    error_message = "Expected Key Protect to be enabled in summary."
  }
}

run "plan_with_cos" {
  command = apply

  variables {
    create_cos = true
  }

  assert {
    condition     = output.cos_instance_id != null
    error_message = "Expected COS instance to be created."
  }

  assert {
    condition     = output.cos_instance_guid != null
    error_message = "Expected COS instance GUID to be set."
  }

  assert {
    condition     = output.cos_bucket_name != null
    error_message = "Expected COS bucket to be created."
  }

  assert {
    condition     = output.cos_bucket_region == "us-south"
    error_message = "Expected COS bucket region to be us-south."
  }

  assert {
    condition     = output.encryption_enabled == false
    error_message = "Expected encryption to be disabled when Key Protect is not created."
  }
}

run "plan_with_encrypted_cos" {
  command = apply

  variables {
    create_key_protect    = true
    create_cos            = true
    enable_cos_encryption = true
  }

  assert {
    condition     = output.key_protect_instance_id != null
    error_message = "Expected Key Protect instance to be created."
  }

  assert {
    condition     = output.cos_instance_id != null
    error_message = "Expected COS instance to be created."
  }

  assert {
    condition     = output.cos_bucket_name != null
    error_message = "Expected encrypted COS bucket to be created."
  }

  assert {
    condition     = output.encryption_enabled == true
    error_message = "Expected encryption to be enabled."
  }

  assert {
    condition     = output.iam_authorization_policy_id != null
    error_message = "Expected IAM authorization policy to be created."
  }

  assert {
    condition     = output.security_architecture_summary.encryption.cos_encryption == true
    error_message = "Expected COS encryption to be enabled in summary."
  }
}

run "plan_with_lifecycle_policies" {
  command = apply

  variables {
    create_cos                = true
    enable_lifecycle_policies = true
    archive_days              = 30
    expire_days               = 180
  }

  assert {
    condition     = output.lifecycle_bucket_name != null
    error_message = "Expected lifecycle bucket to be created."
  }

  assert {
    condition     = output.cos_bucket_name != null
    error_message = "Expected standard bucket to also be created."
  }
}

run "plan_with_ssh_and_ping" {
  command = apply

  variables {
    allow_ssh_from_internet = true
    ssh_allowed_cidr        = "10.0.0.0/8"
    allow_ping              = true
    enable_mysql_port       = true
  }

  assert {
    condition     = output.web_tier_security_group_id != null
    error_message = "Expected web tier security group with SSH rule."
  }

  assert {
    condition     = output.database_tier_security_group_id != null
    error_message = "Expected database tier security group with MySQL rule."
  }
}

run "plan_full_stack" {
  command = apply

  variables {
    create_key_protect        = true
    create_cos                = true
    enable_cos_encryption     = true
    enable_lifecycle_policies = true
    allow_ssh_from_internet   = true
    ssh_allowed_cidr          = "10.0.0.0/8"
    allow_ping                = true
    enable_mysql_port         = true
    bucket_hard_quota_gb      = 100
  }

  assert {
    condition     = output.vpc_id != null
    error_message = "Expected VPC to be created."
  }

  assert {
    condition     = output.web_tier_security_group_id != null
    error_message = "Expected web tier security group."
  }

  assert {
    condition     = output.app_tier_security_group_id != null
    error_message = "Expected app tier security group."
  }

  assert {
    condition     = output.database_tier_security_group_id != null
    error_message = "Expected database tier security group."
  }

  assert {
    condition     = output.key_protect_instance_id != null
    error_message = "Expected Key Protect instance."
  }

  assert {
    condition     = output.cos_instance_id != null
    error_message = "Expected COS instance."
  }

  assert {
    condition     = output.encryption_enabled == true
    error_message = "Expected encryption to be enabled."
  }

  assert {
    condition     = output.lifecycle_bucket_name != null
    error_message = "Expected lifecycle bucket."
  }

  assert {
    condition     = output.security_architecture_summary.encryption.key_protect_enabled == true
    error_message = "Expected Key Protect enabled in summary."
  }

  assert {
    condition     = output.security_architecture_summary.encryption.cos_encryption == true
    error_message = "Expected COS encryption enabled in summary."
  }

  assert {
    condition     = output.security_architecture_summary.monitoring.activity_tracking == true
    error_message = "Expected activity tracking enabled in summary."
  }

  assert {
    condition     = output.security_architecture_summary.monitoring.metrics == true
    error_message = "Expected metrics monitoring enabled in summary."
  }
}

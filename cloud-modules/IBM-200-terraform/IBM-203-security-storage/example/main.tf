terraform {
  required_version = ">= 1.14"

  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 2.0"
    }
  }
}

provider "ibm" {
  region = var.ibm_region
}

# =====================================================================================
# Data Sources
# =====================================================================================

data "ibm_resource_group" "target" {
  is_default = var.resource_group_name == "Default" ? true : null
  name       = var.resource_group_name == "Default" ? null : var.resource_group_name
}

# =====================================================================================
# Local Variables
# =====================================================================================

locals {
  environment = lower(var.environment)
  common_tags = [
    "training",
    "ibm-cloud",
    "terraform",
    "module:ibm-203",
    "environment:${local.environment}",
  ]

  # Construct resource names with consistent naming convention
  vpc_name          = "${local.environment}-${var.project_name}-vpc"
  subnet_name       = "${local.environment}-${var.project_name}-subnet"
  web_sg_name       = "${local.environment}-${var.project_name}-web-sg"
  app_sg_name       = "${local.environment}-${var.project_name}-app-sg"
  database_sg_name  = "${local.environment}-${var.project_name}-database-sg"
  kp_instance_name  = "${local.environment}-${var.project_name}-kp"
  kp_key_name       = "${local.environment}-${var.project_name}-root-key"
  cos_instance_name = "${local.environment}-${var.project_name}-cos"
  cos_bucket_name   = "${local.environment}-${var.project_name}-bucket-${random_string.bucket_suffix.result}"

  # Calculate zone based on region
  zone = "${var.ibm_region}-1"
}

# Random suffix for globally unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# =====================================================================================
# VPC Resources (minimal for security group demonstration)
# =====================================================================================

resource "ibm_is_vpc" "training_vpc" {
  name                      = local.vpc_name
  resource_group            = data.ibm_resource_group.target.id
  classic_access            = false
  address_prefix_management = "auto"
  tags                      = local.common_tags
}

resource "ibm_is_subnet" "training_subnet" {
  name                     = local.subnet_name
  vpc                      = ibm_is_vpc.training_vpc.id
  zone                     = local.zone
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.target.id
  tags                     = local.common_tags
}

# =====================================================================================
# Security Groups
# =====================================================================================

# Web Tier Security Group
resource "ibm_is_security_group" "web_tier" {
  name           = local.web_sg_name
  vpc            = ibm_is_vpc.training_vpc.id
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

# Web Tier Rules
resource "ibm_is_security_group_rule" "web_inbound_http" {
  group     = ibm_is_security_group.web_tier.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "web_inbound_https" {
  group     = ibm_is_security_group.web_tier.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "web_inbound_ssh" {
  count     = var.allow_ssh_from_internet ? 1 : 0
  group     = ibm_is_security_group.web_tier.id
  direction = "inbound"
  remote    = var.ssh_allowed_cidr

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "web_inbound_icmp" {
  count     = var.allow_ping ? 1 : 0
  group     = ibm_is_security_group.web_tier.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  icmp {
    type = 8
    code = 0
  }
}

resource "ibm_is_security_group_rule" "web_outbound_all" {
  group     = ibm_is_security_group.web_tier.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Application Tier Security Group
resource "ibm_is_security_group" "app_tier" {
  name           = local.app_sg_name
  vpc            = ibm_is_vpc.training_vpc.id
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

# Application Tier Rules
resource "ibm_is_security_group_rule" "app_inbound_from_web" {
  group     = ibm_is_security_group.app_tier.id
  direction = "inbound"
  remote    = ibm_is_security_group.web_tier.id

  tcp {
    port_min = 8080
    port_max = 8080
  }
}

resource "ibm_is_security_group_rule" "app_inbound_ssh_from_web" {
  group     = ibm_is_security_group.app_tier.id
  direction = "inbound"
  remote    = ibm_is_security_group.web_tier.id

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "app_outbound_all" {
  group     = ibm_is_security_group.app_tier.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Database Tier Security Group
resource "ibm_is_security_group" "database_tier" {
  name           = local.database_sg_name
  vpc            = ibm_is_vpc.training_vpc.id
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

# Database Tier Rules
resource "ibm_is_security_group_rule" "db_inbound_postgres_from_app" {
  group     = ibm_is_security_group.database_tier.id
  direction = "inbound"
  remote    = ibm_is_security_group.app_tier.id

  tcp {
    port_min = 5432
    port_max = 5432
  }
}

resource "ibm_is_security_group_rule" "db_inbound_mysql_from_app" {
  count     = var.enable_mysql_port ? 1 : 0
  group     = ibm_is_security_group.database_tier.id
  direction = "inbound"
  remote    = ibm_is_security_group.app_tier.id

  tcp {
    port_min = 3306
    port_max = 3306
  }
}

resource "ibm_is_security_group_rule" "db_outbound_all" {
  group     = ibm_is_security_group.database_tier.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# =====================================================================================
# IBM Key Protect
# =====================================================================================

resource "ibm_resource_instance" "kp_instance" {
  count             = var.create_key_protect ? 1 : 0
  name              = local.kp_instance_name
  service           = "kms"
  plan              = var.key_protect_plan
  location          = var.ibm_region
  resource_group_id = data.ibm_resource_group.target.id
  tags              = local.common_tags
}

resource "ibm_kp_key" "root_key" {
  count          = var.create_key_protect ? 1 : 0
  key_protect_id = ibm_resource_instance.kp_instance[0].guid
  key_name       = local.kp_key_name
  standard_key   = false # false = root key for envelope encryption
  force_delete   = var.environment == "dev" ? true : false
}

# =====================================================================================
# Cloud Object Storage
# =====================================================================================

resource "ibm_resource_instance" "cos_instance" {
  count             = var.create_cos ? 1 : 0
  name              = local.cos_instance_name
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = "global"
  resource_group_id = data.ibm_resource_group.target.id
  tags              = local.common_tags
}

# =====================================================================================
# IAM Authorization Policy (COS to Key Protect)
# =====================================================================================

resource "ibm_iam_authorization_policy" "cos_kp_policy" {
  count                       = var.create_cos && var.create_key_protect && var.enable_cos_encryption ? 1 : 0
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = ibm_resource_instance.cos_instance[0].guid
  target_service_name         = "kms"
  target_resource_instance_id = ibm_resource_instance.kp_instance[0].guid
  roles                       = ["Reader"]
}

# =====================================================================================
# COS Buckets
# =====================================================================================

# Standard bucket with encryption
resource "ibm_cos_bucket" "encrypted_bucket" {
  count                = var.create_cos && var.create_key_protect && var.enable_cos_encryption ? 1 : 0
  bucket_name          = local.cos_bucket_name
  resource_instance_id = ibm_resource_instance.cos_instance[0].id
  region_location      = var.ibm_region
  storage_class        = var.cos_storage_class
  kms_key_crn          = ibm_kp_key.root_key[0].id

  # Ensure authorization policy exists before creating bucket
  depends_on = [ibm_iam_authorization_policy.cos_kp_policy]

  # Activity tracking
  activity_tracking {
    read_data_events  = var.enable_activity_tracking
    write_data_events = var.enable_activity_tracking
    management_events = var.enable_activity_tracking
  }

  # Metrics monitoring
  metrics_monitoring {
    usage_metrics_enabled   = var.enable_metrics_monitoring
    request_metrics_enabled = var.enable_metrics_monitoring
  }

  # Hard quota (optional)
  hard_quota = var.bucket_hard_quota_gb > 0 ? var.bucket_hard_quota_gb * 1024 * 1024 * 1024 : null
}

# Bucket without encryption (for comparison)
resource "ibm_cos_bucket" "standard_bucket" {
  count                = var.create_cos && !var.enable_cos_encryption ? 1 : 0
  bucket_name          = local.cos_bucket_name
  resource_instance_id = ibm_resource_instance.cos_instance[0].id
  region_location      = var.ibm_region
  storage_class        = var.cos_storage_class

  activity_tracking {
    read_data_events  = var.enable_activity_tracking
    write_data_events = var.enable_activity_tracking
    management_events = var.enable_activity_tracking
  }

  metrics_monitoring {
    usage_metrics_enabled   = var.enable_metrics_monitoring
    request_metrics_enabled = var.enable_metrics_monitoring
  }

  hard_quota = var.bucket_hard_quota_gb > 0 ? var.bucket_hard_quota_gb * 1024 * 1024 * 1024 : null
}

# Bucket with lifecycle policies
resource "ibm_cos_bucket" "lifecycle_bucket" {
  count                = var.create_cos && var.enable_lifecycle_policies ? 1 : 0
  bucket_name          = "${local.cos_bucket_name}-lifecycle"
  resource_instance_id = ibm_resource_instance.cos_instance[0].id
  region_location      = var.ibm_region
  storage_class        = "standard"

  # Archive rule - move to cold storage after specified days
  archive_rule {
    rule_id = "archive-old-objects"
    enable  = true
    days    = var.archive_days
    type    = "Glacier"
  }

  # Expire rule - delete very old objects
  expire_rule {
    rule_id = "expire-very-old-objects"
    enable  = true
    days    = var.expire_days
  }
}

# =====================================================================================
# Outputs
# =====================================================================================

output "vpc_id" {
  description = "ID of the created VPC"
  value       = ibm_is_vpc.training_vpc.id
}

output "vpc_default_security_group_id" {
  description = "ID of the VPC default security group"
  value       = ibm_is_vpc.training_vpc.default_security_group
}

output "web_tier_security_group_id" {
  description = "ID of the web tier security group"
  value       = ibm_is_security_group.web_tier.id
}

output "app_tier_security_group_id" {
  description = "ID of the application tier security group"
  value       = ibm_is_security_group.app_tier.id
}

output "database_tier_security_group_id" {
  description = "ID of the database tier security group"
  value       = ibm_is_security_group.database_tier.id
}

output "security_group_summary" {
  description = "Summary of created security groups"
  value = {
    web_tier = {
      id   = ibm_is_security_group.web_tier.id
      name = ibm_is_security_group.web_tier.name
    }
    app_tier = {
      id   = ibm_is_security_group.app_tier.id
      name = ibm_is_security_group.app_tier.name
    }
    database_tier = {
      id   = ibm_is_security_group.database_tier.id
      name = ibm_is_security_group.database_tier.name
    }
  }
}

output "key_protect_instance_id" {
  description = "ID of the Key Protect instance (if created)"
  value       = var.create_key_protect ? ibm_resource_instance.kp_instance[0].id : null
}

output "key_protect_instance_guid" {
  description = "GUID of the Key Protect instance (if created)"
  value       = var.create_key_protect ? ibm_resource_instance.kp_instance[0].guid : null
}

output "root_key_id" {
  description = "ID (CRN) of the root key (if created)"
  value       = var.create_key_protect ? ibm_kp_key.root_key[0].id : null
  sensitive   = true
}

output "root_key_crn" {
  description = "CRN of the root key (if created)"
  value       = var.create_key_protect ? ibm_kp_key.root_key[0].crn : null
  sensitive   = true
}

output "cos_instance_id" {
  description = "ID of the COS instance (if created)"
  value       = var.create_cos ? ibm_resource_instance.cos_instance[0].id : null
}

output "cos_instance_guid" {
  description = "GUID of the COS instance (if created)"
  value       = var.create_cos ? ibm_resource_instance.cos_instance[0].guid : null
}

output "cos_bucket_name" {
  description = "Name of the primary COS bucket (if created)"
  value = var.create_cos ? (
    var.enable_cos_encryption ? ibm_cos_bucket.encrypted_bucket[0].bucket_name : ibm_cos_bucket.standard_bucket[0].bucket_name
  ) : null
}

output "cos_bucket_crn" {
  description = "CRN of the primary COS bucket (if created)"
  value = var.create_cos ? (
    var.enable_cos_encryption ? ibm_cos_bucket.encrypted_bucket[0].crn : ibm_cos_bucket.standard_bucket[0].crn
  ) : null
}

output "cos_bucket_region" {
  description = "Region of the COS bucket"
  value = var.create_cos ? (
    var.enable_cos_encryption ? ibm_cos_bucket.encrypted_bucket[0].region_location : ibm_cos_bucket.standard_bucket[0].region_location
  ) : null
}

output "lifecycle_bucket_name" {
  description = "Name of the lifecycle bucket (if created)"
  value       = var.create_cos && var.enable_lifecycle_policies ? ibm_cos_bucket.lifecycle_bucket[0].bucket_name : null
}

output "encryption_enabled" {
  description = "Whether COS encryption with Key Protect is enabled"
  value       = var.create_cos && var.create_key_protect && var.enable_cos_encryption
}

output "iam_authorization_policy_id" {
  description = "ID of the IAM authorization policy (if created)"
  value       = var.create_cos && var.create_key_protect && var.enable_cos_encryption ? ibm_iam_authorization_policy.cos_kp_policy[0].id : null
}

output "resource_group_id" {
  description = "ID of the resource group used"
  value       = data.ibm_resource_group.target.id
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

output "security_architecture_summary" {
  description = "Summary of the security architecture"
  value = {
    vpc_id = ibm_is_vpc.training_vpc.id
    security_groups = {
      web      = ibm_is_security_group.web_tier.name
      app      = ibm_is_security_group.app_tier.name
      database = ibm_is_security_group.database_tier.name
    }
    encryption = {
      key_protect_enabled = var.create_key_protect
      cos_encryption      = var.create_cos && var.create_key_protect && var.enable_cos_encryption
    }
    monitoring = {
      activity_tracking = var.enable_activity_tracking
      metrics           = var.enable_metrics_monitoring
    }
  }
}

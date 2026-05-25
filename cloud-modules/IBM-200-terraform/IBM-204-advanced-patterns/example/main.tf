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

# Find the latest Ubuntu image
data "ibm_is_image" "ubuntu" {
  name = var.image_name
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
    "module:ibm-204",
    "environment:${local.environment}",
    "architecture:multi-tier",
  ]

  # Construct resource names with consistent naming convention
  vpc_name             = "${local.environment}-${var.project_name}-vpc"
  public_subnet_zone1  = "${local.environment}-${var.project_name}-public-subnet-zone1"
  public_subnet_zone2  = "${local.environment}-${var.project_name}-public-subnet-zone2"
  private_subnet_zone1 = "${local.environment}-${var.project_name}-private-subnet-zone1"
  private_subnet_zone2 = "${local.environment}-${var.project_name}-private-subnet-zone2"
  gateway_zone1        = "${local.environment}-${var.project_name}-gateway-zone1"
  gateway_zone2        = "${local.environment}-${var.project_name}-gateway-zone2"
  lb_name              = "${local.environment}-${var.project_name}-lb"
  ssh_key_name         = "${local.environment}-${var.project_name}-ssh-key"
  kp_instance_name     = "${local.environment}-${var.project_name}-kp"
  kp_key_name          = "${local.environment}-${var.project_name}-root-key"
  cos_instance_name    = "${local.environment}-${var.project_name}-cos"
  cos_bucket_name      = "${local.environment}-${var.project_name}-backups-${random_string.bucket_suffix.result}"

  # Calculate zones based on region
  zone1 = "${var.ibm_region}-1"
  zone2 = "${var.ibm_region}-2"

  # CIDR blocks for subnets
  public_cidr_zone1  = "10.240.0.0/24"
  private_cidr_zone1 = "10.240.1.0/24"
  public_cidr_zone2  = "10.240.2.0/24"
  private_cidr_zone2 = "10.240.3.0/24"
}

# Random suffix for globally unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# =====================================================================================
# VPC and Networking
# =====================================================================================

resource "ibm_is_vpc" "main" {
  name                      = local.vpc_name
  resource_group            = data.ibm_resource_group.target.id
  classic_access            = false
  address_prefix_management = "manual"
  tags                      = local.common_tags
}

# Address prefixes for manual management
resource "ibm_is_vpc_address_prefix" "zone1" {
  name = "${local.vpc_name}-zone1-prefix"
  zone = local.zone1
  vpc  = ibm_is_vpc.main.id
  cidr = "10.240.0.0/20" # Covers 10.240.0.0 - 10.240.15.255
}

resource "ibm_is_vpc_address_prefix" "zone2" {
  name = "${local.vpc_name}-zone2-prefix"
  zone = local.zone2
  vpc  = ibm_is_vpc.main.id
  cidr = "10.240.16.0/20" # Covers 10.240.16.0 - 10.240.31.255
}

# Public Gateways for outbound internet access
resource "ibm_is_public_gateway" "zone1" {
  name           = local.gateway_zone1
  vpc            = ibm_is_vpc.main.id
  zone           = local.zone1
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

resource "ibm_is_public_gateway" "zone2" {
  name           = local.gateway_zone2
  vpc            = ibm_is_vpc.main.id
  zone           = local.zone2
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

# Public Subnets (for load balancer)
resource "ibm_is_subnet" "public_zone1" {
  name            = local.public_subnet_zone1
  vpc             = ibm_is_vpc.main.id
  zone            = local.zone1
  ipv4_cidr_block = local.public_cidr_zone1
  public_gateway  = ibm_is_public_gateway.zone1.id
  resource_group  = data.ibm_resource_group.target.id
  tags            = concat(local.common_tags, ["tier:public"])

  depends_on = [ibm_is_vpc_address_prefix.zone1]
}

resource "ibm_is_subnet" "public_zone2" {
  name            = local.public_subnet_zone2
  vpc             = ibm_is_vpc.main.id
  zone            = local.zone2
  ipv4_cidr_block = local.public_cidr_zone2
  public_gateway  = ibm_is_public_gateway.zone2.id
  resource_group  = data.ibm_resource_group.target.id
  tags            = concat(local.common_tags, ["tier:public"])

  depends_on = [ibm_is_vpc_address_prefix.zone2]
}

# Private Subnets (for application and database tiers)
resource "ibm_is_subnet" "private_zone1" {
  name            = local.private_subnet_zone1
  vpc             = ibm_is_vpc.main.id
  zone            = local.zone1
  ipv4_cidr_block = local.private_cidr_zone1
  resource_group  = data.ibm_resource_group.target.id
  tags            = concat(local.common_tags, ["tier:private"])

  depends_on = [ibm_is_vpc_address_prefix.zone1]
}

resource "ibm_is_subnet" "private_zone2" {
  name            = local.private_subnet_zone2
  vpc             = ibm_is_vpc.main.id
  zone            = local.zone2
  ipv4_cidr_block = local.private_cidr_zone2
  resource_group  = data.ibm_resource_group.target.id
  tags            = concat(local.common_tags, ["tier:private"])

  depends_on = [ibm_is_vpc_address_prefix.zone2]
}

# =====================================================================================
# Security Groups
# =====================================================================================

# Load Balancer Security Group
resource "ibm_is_security_group" "lb" {
  name           = "${local.environment}-${var.project_name}-lb-sg"
  vpc            = ibm_is_vpc.main.id
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

resource "ibm_is_security_group_rule" "lb_inbound_http" {
  group     = ibm_is_security_group.lb.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "lb_inbound_https" {
  group     = ibm_is_security_group.lb.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "lb_outbound_all" {
  group     = ibm_is_security_group.lb.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Web Tier Security Group
resource "ibm_is_security_group" "web" {
  name           = "${local.environment}-${var.project_name}-web-sg"
  vpc            = ibm_is_vpc.main.id
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

resource "ibm_is_security_group_rule" "web_inbound_http_from_lb" {
  group     = ibm_is_security_group.web.id
  direction = "inbound"
  remote    = ibm_is_security_group.lb.id
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "web_inbound_https_from_lb" {
  group     = ibm_is_security_group.web.id
  direction = "inbound"
  remote    = ibm_is_security_group.lb.id
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "web_inbound_ssh" {
  count     = var.enable_ssh_access ? 1 : 0
  group     = ibm_is_security_group.web.id
  direction = "inbound"
  remote    = var.ssh_allowed_cidr
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "web_outbound_all" {
  group     = ibm_is_security_group.web.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Application Tier Security Group
resource "ibm_is_security_group" "app" {
  name           = "${local.environment}-${var.project_name}-app-sg"
  vpc            = ibm_is_vpc.main.id
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

resource "ibm_is_security_group_rule" "app_inbound_from_web" {
  group     = ibm_is_security_group.app.id
  direction = "inbound"
  remote    = ibm_is_security_group.web.id
  tcp {
    port_min = 8080
    port_max = 8080
  }
}

resource "ibm_is_security_group_rule" "app_inbound_ssh" {
  count     = var.enable_ssh_access ? 1 : 0
  group     = ibm_is_security_group.app.id
  direction = "inbound"
  remote    = ibm_is_security_group.web.id
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "app_outbound_all" {
  group     = ibm_is_security_group.app.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Database Tier Security Group
resource "ibm_is_security_group" "database" {
  name           = "${local.environment}-${var.project_name}-database-sg"
  vpc            = ibm_is_vpc.main.id
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

resource "ibm_is_security_group_rule" "db_inbound_postgres_from_app" {
  group     = ibm_is_security_group.database.id
  direction = "inbound"
  remote    = ibm_is_security_group.app.id
  tcp {
    port_min = 5432
    port_max = 5432
  }
}

resource "ibm_is_security_group_rule" "db_outbound_all" {
  group     = ibm_is_security_group.database.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# =====================================================================================
# SSH Key
# =====================================================================================

resource "ibm_is_ssh_key" "main" {
  count          = var.ssh_public_key != "" ? 1 : 0
  name           = local.ssh_key_name
  public_key     = var.ssh_public_key
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags
}

# =====================================================================================
# Compute Instances
# =====================================================================================

# Web Tier Instances
resource "ibm_is_instance" "web_zone1" {
  count          = var.deploy_compute ? var.web_tier_instance_count : 0
  name           = "${local.environment}-${var.project_name}-web-${local.zone1}-${count.index + 1}"
  vpc            = ibm_is_vpc.main.id
  zone           = local.zone1
  profile        = var.web_tier_instance_profile
  image          = data.ibm_is_image.ubuntu.id
  resource_group = data.ibm_resource_group.target.id
  tags           = concat(local.common_tags, ["tier:web", "zone:${local.zone1}"])

  primary_network_interface {
    subnet          = ibm_is_subnet.public_zone1.id
    security_groups = [ibm_is_security_group.web.id]
  }

  keys = var.ssh_public_key != "" ? [ibm_is_ssh_key.main[0].id] : []

  user_data = var.web_tier_user_data != "" ? var.web_tier_user_data : null
}

resource "ibm_is_instance" "web_zone2" {
  count          = var.deploy_compute && var.multi_zone ? var.web_tier_instance_count : 0
  name           = "${local.environment}-${var.project_name}-web-${local.zone2}-${count.index + 1}"
  vpc            = ibm_is_vpc.main.id
  zone           = local.zone2
  profile        = var.web_tier_instance_profile
  image          = data.ibm_is_image.ubuntu.id
  resource_group = data.ibm_resource_group.target.id
  tags           = concat(local.common_tags, ["tier:web", "zone:${local.zone2}"])

  primary_network_interface {
    subnet          = ibm_is_subnet.public_zone2.id
    security_groups = [ibm_is_security_group.web.id]
  }

  keys = var.ssh_public_key != "" ? [ibm_is_ssh_key.main[0].id] : []

  user_data = var.web_tier_user_data != "" ? var.web_tier_user_data : null
}

# Application Tier Instances
resource "ibm_is_instance" "app_zone1" {
  count          = var.deploy_compute ? var.app_tier_instance_count : 0
  name           = "${local.environment}-${var.project_name}-app-${local.zone1}-${count.index + 1}"
  vpc            = ibm_is_vpc.main.id
  zone           = local.zone1
  profile        = var.app_tier_instance_profile
  image          = data.ibm_is_image.ubuntu.id
  resource_group = data.ibm_resource_group.target.id
  tags           = concat(local.common_tags, ["tier:app", "zone:${local.zone1}"])

  primary_network_interface {
    subnet          = ibm_is_subnet.private_zone1.id
    security_groups = [ibm_is_security_group.app.id]
  }

  keys = var.ssh_public_key != "" ? [ibm_is_ssh_key.main[0].id] : []

  user_data = var.app_tier_user_data != "" ? var.app_tier_user_data : null
}

resource "ibm_is_instance" "app_zone2" {
  count          = var.deploy_compute && var.multi_zone ? var.app_tier_instance_count : 0
  name           = "${local.environment}-${var.project_name}-app-${local.zone2}-${count.index + 1}"
  vpc            = ibm_is_vpc.main.id
  zone           = local.zone2
  profile        = var.app_tier_instance_profile
  image          = data.ibm_is_image.ubuntu.id
  resource_group = data.ibm_resource_group.target.id
  tags           = concat(local.common_tags, ["tier:app", "zone:${local.zone2}"])

  primary_network_interface {
    subnet          = ibm_is_subnet.private_zone2.id
    security_groups = [ibm_is_security_group.app.id]
  }

  keys = var.ssh_public_key != "" ? [ibm_is_ssh_key.main[0].id] : []

  user_data = var.app_tier_user_data != "" ? var.app_tier_user_data : null
}

# Database Tier Instances
resource "ibm_is_instance" "database_zone1" {
  count          = var.deploy_compute ? 1 : 0
  name           = "${local.environment}-${var.project_name}-database-${local.zone1}"
  vpc            = ibm_is_vpc.main.id
  zone           = local.zone1
  profile        = var.database_tier_instance_profile
  image          = data.ibm_is_image.ubuntu.id
  resource_group = data.ibm_resource_group.target.id
  tags           = concat(local.common_tags, ["tier:database", "zone:${local.zone1}", "role:primary"])

  primary_network_interface {
    subnet          = ibm_is_subnet.private_zone1.id
    security_groups = [ibm_is_security_group.database.id]
  }

  keys = var.ssh_public_key != "" ? [ibm_is_ssh_key.main[0].id] : []

  user_data = var.database_tier_user_data != "" ? var.database_tier_user_data : null
}

resource "ibm_is_instance" "database_zone2" {
  count          = var.deploy_compute && var.multi_zone ? 1 : 0
  name           = "${local.environment}-${var.project_name}-database-${local.zone2}"
  vpc            = ibm_is_vpc.main.id
  zone           = local.zone2
  profile        = var.database_tier_instance_profile
  image          = data.ibm_is_image.ubuntu.id
  resource_group = data.ibm_resource_group.target.id
  tags           = concat(local.common_tags, ["tier:database", "zone:${local.zone2}", "role:replica"])

  primary_network_interface {
    subnet          = ibm_is_subnet.private_zone2.id
    security_groups = [ibm_is_security_group.database.id]
  }

  keys = var.ssh_public_key != "" ? [ibm_is_ssh_key.main[0].id] : []

  user_data = var.database_tier_user_data != "" ? var.database_tier_user_data : null
}

# =====================================================================================
# Load Balancer
# =====================================================================================

resource "ibm_is_lb" "web" {
  count          = var.deploy_load_balancer ? 1 : 0
  name           = local.lb_name
  subnets        = [ibm_is_subnet.public_zone1.id, ibm_is_subnet.public_zone2.id]
  type           = "public"
  resource_group = data.ibm_resource_group.target.id
  tags           = local.common_tags

  security_groups = [ibm_is_security_group.lb.id]
}

# Backend Pool
resource "ibm_is_lb_pool" "web" {
  count               = var.deploy_load_balancer ? 1 : 0
  lb                  = ibm_is_lb.web[0].id
  name                = "web-backend-pool"
  protocol            = "http"
  algorithm           = var.lb_algorithm
  health_delay        = var.lb_health_delay
  health_retries      = var.lb_health_retries
  health_timeout      = var.lb_health_timeout
  health_type         = "http"
  health_monitor_url  = var.lb_health_monitor_url
  health_monitor_port = 80
}

# Pool Members - Zone 1
resource "ibm_is_lb_pool_member" "web_zone1" {
  count          = var.deploy_load_balancer && var.deploy_compute ? var.web_tier_instance_count : 0
  lb             = ibm_is_lb.web[0].id
  pool           = ibm_is_lb_pool.web[0].id
  port           = 80
  target_address = "10.240.0.${4 + count.index}"
  weight         = 50
}

# Pool Members - Zone 2
resource "ibm_is_lb_pool_member" "web_zone2" {
  count          = var.deploy_load_balancer && var.deploy_compute && var.multi_zone ? var.web_tier_instance_count : 0
  lb             = ibm_is_lb.web[0].id
  pool           = ibm_is_lb_pool.web[0].id
  port           = 80
  target_address = "10.240.64.${4 + count.index}"
  weight         = 50
}

# HTTP Listener
resource "ibm_is_lb_listener" "web_http" {
  count        = var.deploy_load_balancer ? 1 : 0
  lb           = ibm_is_lb.web[0].id
  port         = 80
  protocol     = "http"
  default_pool = ibm_is_lb_pool.web[0].id
}

# =====================================================================================
# IBM Key Protect (Optional)
# =====================================================================================

resource "ibm_resource_instance" "kp_instance" {
  count             = var.deploy_key_protect ? 1 : 0
  name              = local.kp_instance_name
  service           = "kms"
  plan              = "tiered-pricing"
  location          = var.ibm_region
  resource_group_id = data.ibm_resource_group.target.id
  tags              = local.common_tags
}

resource "ibm_kp_key" "root_key" {
  count          = var.deploy_key_protect ? 1 : 0
  key_protect_id = ibm_resource_instance.kp_instance[0].guid
  key_name       = local.kp_key_name
  standard_key   = false
  force_delete   = var.environment == "dev" ? true : false
}

# =====================================================================================
# Cloud Object Storage (Optional)
# =====================================================================================

resource "ibm_resource_instance" "cos_instance" {
  count             = var.deploy_cos ? 1 : 0
  name              = local.cos_instance_name
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  resource_group_id = data.ibm_resource_group.target.id
  tags              = local.common_tags
}

# IAM Authorization Policy
resource "ibm_iam_authorization_policy" "cos_kp_policy" {
  count                       = var.deploy_cos && var.deploy_key_protect ? 1 : 0
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = ibm_resource_instance.cos_instance[0].guid
  target_service_name         = "kms"
  target_resource_instance_id = ibm_resource_instance.kp_instance[0].guid
  roles                       = ["Reader"]
}

# Encrypted Backup Bucket
resource "ibm_cos_bucket" "backups" {
  count                = var.deploy_cos && var.deploy_key_protect ? 1 : 0
  bucket_name          = local.cos_bucket_name
  resource_instance_id = ibm_resource_instance.cos_instance[0].id
  region_location      = var.ibm_region
  storage_class        = "standard"
  kms_key_crn          = ibm_kp_key.root_key[0].id

  depends_on = [ibm_iam_authorization_policy.cos_kp_policy]

  activity_tracking {
    read_data_events  = true
    write_data_events = true
    management_events = true
  }

  metrics_monitoring {
    usage_metrics_enabled   = true
    request_metrics_enabled = true
  }
}

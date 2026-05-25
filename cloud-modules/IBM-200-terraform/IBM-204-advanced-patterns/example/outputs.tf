# =====================================================================================
# VPC and Networking Outputs
# =====================================================================================

output "vpc_id" {
  description = "ID of the created VPC"
  value       = ibm_is_vpc.main.id
}

output "vpc_name" {
  description = "Name of the created VPC"
  value       = ibm_is_vpc.main.name
}

output "vpc_crn" {
  description = "CRN of the created VPC"
  value       = ibm_is_vpc.main.crn
}

output "public_subnet_zone1_id" {
  description = "ID of the public subnet in zone 1"
  value       = ibm_is_subnet.public_zone1.id
}

output "public_subnet_zone2_id" {
  description = "ID of the public subnet in zone 2"
  value       = ibm_is_subnet.public_zone2.id
}

output "private_subnet_zone1_id" {
  description = "ID of the private subnet in zone 1"
  value       = ibm_is_subnet.private_zone1.id
}

output "private_subnet_zone2_id" {
  description = "ID of the private subnet in zone 2"
  value       = ibm_is_subnet.private_zone2.id
}

output "subnet_summary" {
  description = "Summary of all subnets"
  value = {
    public_zone1 = {
      id   = ibm_is_subnet.public_zone1.id
      cidr = ibm_is_subnet.public_zone1.ipv4_cidr_block
      zone = ibm_is_subnet.public_zone1.zone
    }
    public_zone2 = {
      id   = ibm_is_subnet.public_zone2.id
      cidr = ibm_is_subnet.public_zone2.ipv4_cidr_block
      zone = ibm_is_subnet.public_zone2.zone
    }
    private_zone1 = {
      id   = ibm_is_subnet.private_zone1.id
      cidr = ibm_is_subnet.private_zone1.ipv4_cidr_block
      zone = ibm_is_subnet.private_zone1.zone
    }
    private_zone2 = {
      id   = ibm_is_subnet.private_zone2.id
      cidr = ibm_is_subnet.private_zone2.ipv4_cidr_block
      zone = ibm_is_subnet.private_zone2.zone
    }
  }
}

# =====================================================================================
# Security Group Outputs
# =====================================================================================

output "lb_security_group_id" {
  description = "ID of the load balancer security group"
  value       = ibm_is_security_group.lb.id
}

output "web_security_group_id" {
  description = "ID of the web tier security group"
  value       = ibm_is_security_group.web.id
}

output "app_security_group_id" {
  description = "ID of the application tier security group"
  value       = ibm_is_security_group.app.id
}

output "database_security_group_id" {
  description = "ID of the database tier security group"
  value       = ibm_is_security_group.database.id
}

output "security_group_summary" {
  description = "Summary of all security groups"
  value = {
    load_balancer = {
      id   = ibm_is_security_group.lb.id
      name = ibm_is_security_group.lb.name
    }
    web_tier = {
      id   = ibm_is_security_group.web.id
      name = ibm_is_security_group.web.name
    }
    app_tier = {
      id   = ibm_is_security_group.app.id
      name = ibm_is_security_group.app.name
    }
    database_tier = {
      id   = ibm_is_security_group.database.id
      name = ibm_is_security_group.database.name
    }
  }
}

# =====================================================================================
# Compute Instance Outputs
# =====================================================================================

output "web_instances_zone1" {
  description = "Web tier instances in zone 1"
  value = var.deploy_compute ? [
    for idx, instance in ibm_is_instance.web_zone1 : {
      id         = instance.id
      name       = instance.name
      private_ip = "10.240.0.${4 + idx}"
    }
  ] : []
}

output "web_instances_zone2" {
  description = "Web tier instances in zone 2"
  value = var.deploy_compute && var.multi_zone ? [
    for idx, instance in ibm_is_instance.web_zone2 : {
      id         = instance.id
      name       = instance.name
      private_ip = "10.240.64.${4 + idx}"
    }
  ] : []
}

output "app_instances_zone1" {
  description = "Application tier instances in zone 1"
  value = var.deploy_compute ? [
    for idx, instance in ibm_is_instance.app_zone1 : {
      id         = instance.id
      name       = instance.name
      private_ip = "10.240.1.${4 + idx}"
    }
  ] : []
}

output "app_instances_zone2" {
  description = "Application tier instances in zone 2"
  value = var.deploy_compute && var.multi_zone ? [
    for idx, instance in ibm_is_instance.app_zone2 : {
      id         = instance.id
      name       = instance.name
      private_ip = "10.240.65.${4 + idx}"
    }
  ] : []
}

output "database_instance_zone1" {
  description = "Database instance in zone 1 (primary)"
  value = var.deploy_compute ? {
    id         = ibm_is_instance.database_zone1[0].id
    name       = ibm_is_instance.database_zone1[0].name
    private_ip = "10.240.4.4"
    role       = "primary"
  } : null
}

output "database_instance_zone2" {
  description = "Database instance in zone 2 (replica)"
  value = var.deploy_compute && var.multi_zone ? {
    id         = ibm_is_instance.database_zone2[0].id
    name       = ibm_is_instance.database_zone2[0].name
    private_ip = "10.240.5.4"
    role       = "replica"
  } : null
}

# =====================================================================================
# Load Balancer Outputs
# =====================================================================================

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = var.deploy_load_balancer ? ibm_is_lb.web[0].id : null
}

output "load_balancer_hostname" {
  description = "Hostname of the load balancer"
  value       = var.deploy_load_balancer ? ibm_is_lb.web[0].hostname : null
}

output "load_balancer_public_ips" {
  description = "Public IPs of the load balancer"
  value       = var.deploy_load_balancer ? ibm_is_lb.web[0].public_ips : null
}

output "load_balancer_url" {
  description = "URL to access the load balancer"
  value       = var.deploy_load_balancer ? "http://${ibm_is_lb.web[0].hostname}" : null
}

output "load_balancer_pool_id" {
  description = "ID of the load balancer backend pool"
  value       = var.deploy_load_balancer ? ibm_is_lb_pool.web[0].id : null
}

output "load_balancer_summary" {
  description = "Summary of load balancer configuration"
  value = var.deploy_load_balancer ? {
    id               = ibm_is_lb.web[0].id
    hostname         = ibm_is_lb.web[0].hostname
    type             = ibm_is_lb.web[0].type
    algorithm        = ibm_is_lb_pool.web[0].algorithm
    health_check_url = ibm_is_lb_pool.web[0].health_monitor_url
    member_count     = (var.deploy_compute ? var.web_tier_instance_count : 0) + (var.deploy_compute && var.multi_zone ? var.web_tier_instance_count : 0)
  } : null
}

# =====================================================================================
# Key Protect Outputs
# =====================================================================================

output "key_protect_instance_id" {
  description = "ID of the Key Protect instance"
  value       = var.deploy_key_protect ? ibm_resource_instance.kp_instance[0].id : null
}

output "key_protect_instance_guid" {
  description = "GUID of the Key Protect instance"
  value       = var.deploy_key_protect ? ibm_resource_instance.kp_instance[0].guid : null
}

output "root_key_id" {
  description = "ID (CRN) of the root key"
  value       = var.deploy_key_protect ? ibm_kp_key.root_key[0].id : null
  sensitive   = true
}

# =====================================================================================
# Cloud Object Storage Outputs
# =====================================================================================

output "cos_instance_id" {
  description = "ID of the COS instance"
  value       = var.deploy_cos ? ibm_resource_instance.cos_instance[0].id : null
}

output "cos_instance_guid" {
  description = "GUID of the COS instance"
  value       = var.deploy_cos ? ibm_resource_instance.cos_instance[0].guid : null
}

output "cos_bucket_name" {
  description = "Name of the COS backup bucket"
  value       = var.deploy_cos && var.deploy_key_protect ? ibm_cos_bucket.backups[0].bucket_name : null
}

output "cos_bucket_crn" {
  description = "CRN of the COS backup bucket"
  value       = var.deploy_cos && var.deploy_key_protect ? ibm_cos_bucket.backups[0].crn : null
}

# =====================================================================================
# Architecture Summary Outputs
# =====================================================================================

output "architecture_summary" {
  description = "Complete architecture summary"
  value = {
    vpc = {
      id   = ibm_is_vpc.main.id
      name = ibm_is_vpc.main.name
    }
    zones = {
      zone1 = local.zone1
      zone2 = local.zone2
    }
    subnets = {
      public_count  = 2
      private_count = 2
    }
    security_groups = {
      count = 4
      tiers = ["load_balancer", "web", "app", "database"]
    }
    compute = {
      deployed   = var.deploy_compute
      multi_zone = var.multi_zone
      web_count  = var.deploy_compute ? var.web_tier_instance_count * (var.multi_zone ? 2 : 1) : 0
      app_count  = var.deploy_compute ? var.app_tier_instance_count * (var.multi_zone ? 2 : 1) : 0
      db_count   = var.deploy_compute ? (var.multi_zone ? 2 : 1) : 0
    }
    load_balancer = {
      deployed = var.deploy_load_balancer
      type     = var.deploy_load_balancer ? "public" : null
      url      = var.deploy_load_balancer ? "http://${ibm_is_lb.web[0].hostname}" : null
    }
    encryption = {
      key_protect_deployed = var.deploy_key_protect
      cos_encrypted        = var.deploy_cos && var.deploy_key_protect
    }
    storage = {
      cos_deployed = var.deploy_cos
    }
  }
}

output "deployment_instructions" {
  description = "Instructions for accessing the deployed infrastructure"
  value       = var.deploy_load_balancer ? "Load Balancer URL: http://${ibm_is_lb.web[0].hostname}" : "Deploy with deploy_load_balancer=true to access the application"
}

output "resource_group_id" {
  description = "ID of the resource group used"
  value       = data.ibm_resource_group.target.id
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

# ============================================================================
# Project Information
# ============================================================================

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "zone" {
  description = "The GCP zone"
  value       = var.zone
}

# ============================================================================
# Network
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_cidr" {
  description = "CIDR range of the subnet"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

# ============================================================================
# Load Balancer
# ============================================================================

output "load_balancer_ip" {
  description = "External IP address of the load balancer"
  value       = google_compute_global_forwarding_rule.app.ip_address
}

output "load_balancer_url" {
  description = "URL to access the load balancer"
  value       = "http://${google_compute_global_forwarding_rule.app.ip_address}"
}

output "backend_service_id" {
  description = "ID of the backend service"
  value       = google_compute_backend_service.app.id
}

output "health_check_id" {
  description = "ID of the health check"
  value       = google_compute_health_check.lb.id
}

# ============================================================================
# Managed Instance Group
# ============================================================================

output "instance_template_id" {
  description = "ID of the instance template"
  value       = google_compute_instance_template.app.id
}

output "instance_template_name" {
  description = "Name of the instance template"
  value       = google_compute_instance_template.app.name
}

output "mig_id" {
  description = "ID of the managed instance group"
  value       = google_compute_region_instance_group_manager.app.id
}

output "mig_instance_group" {
  description = "Instance group URL"
  value       = google_compute_region_instance_group_manager.app.instance_group
}

output "mig_status" {
  description = "Status of the managed instance group"
  value       = google_compute_region_instance_group_manager.app.status
}

output "autoscaler_id" {
  description = "ID of the autoscaler"
  value       = google_compute_region_autoscaler.app.id
}

output "autoscaler_target" {
  description = "Autoscaler target configuration"
  value = {
    min_replicas = var.autoscaler_min_replicas
    max_replicas = var.autoscaler_max_replicas
    cpu_target   = var.autoscaler_cpu_target
  }
}

# ============================================================================
# Cloud SQL
# ============================================================================

output "database_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = var.enable_cloud_sql ? google_sql_database_instance.main[0].name : null
}

output "database_connection_name" {
  description = "Connection name for Cloud SQL instance"
  value       = var.enable_cloud_sql ? google_sql_database_instance.main[0].connection_name : null
}

output "database_private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = var.enable_cloud_sql ? google_sql_database_instance.main[0].private_ip_address : null
}

output "database_name" {
  description = "Name of the database"
  value       = var.enable_cloud_sql ? google_sql_database.database[0].name : null
}

output "database_user" {
  description = "Database user name"
  value       = var.enable_cloud_sql ? google_sql_user.user[0].name : null
}

output "database_password" {
  description = "Database password (sensitive)"
  value       = var.enable_cloud_sql ? random_password.db_password.result : null
  sensitive   = true
}

output "database_version" {
  description = "Database version"
  value       = var.enable_cloud_sql ? google_sql_database_instance.main[0].database_version : null
}

# ============================================================================
# Summary
# ============================================================================

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    load_balancer = {
      ip_address = google_compute_global_forwarding_rule.app.ip_address
      url        = "http://${google_compute_global_forwarding_rule.app.ip_address}"
    }
    managed_instance_group = {
      name           = google_compute_region_instance_group_manager.app.name
      target_size    = var.mig_target_size
      min_replicas   = var.autoscaler_min_replicas
      max_replicas   = var.autoscaler_max_replicas
      instance_group = google_compute_region_instance_group_manager.app.instance_group
    }
    database = var.enable_cloud_sql ? {
      instance_name = google_sql_database_instance.main[0].name
      database_name = google_sql_database.database[0].name
      private_ip    = google_sql_database_instance.main[0].private_ip_address
      version       = google_sql_database_instance.main[0].database_version
    } : null
    network = {
      vpc_name    = google_compute_network.vpc.name
      subnet_cidr = google_compute_subnetwork.subnet.ip_cidr_range
    }
  }
}

# ============================================================================
# Access Instructions
# ============================================================================

output "access_instructions" {
  description = "Instructions for accessing and managing resources"
  value = <<-EOT
    
    === GCP-204 Advanced Patterns Resources ===
    
    Load Balancer:
      External IP: ${google_compute_global_forwarding_rule.app.ip_address}
      URL: http://${google_compute_global_forwarding_rule.app.ip_address}
      
      Test the load balancer:
        curl http://${google_compute_global_forwarding_rule.app.ip_address}
      
      Monitor backend health:
        gcloud compute backend-services get-health ${google_compute_backend_service.app.name} --global
    
    Managed Instance Group:
      Name: ${google_compute_region_instance_group_manager.app.name}
      Region: ${var.region}
      Target Size: ${var.mig_target_size}
      Autoscaling: ${var.autoscaler_min_replicas}-${var.autoscaler_max_replicas} instances
      
      List instances:
        gcloud compute instance-groups managed list-instances ${google_compute_region_instance_group_manager.app.name} --region=${var.region}
      
      Describe MIG:
        gcloud compute instance-groups managed describe ${google_compute_region_instance_group_manager.app.name} --region=${var.region}
      
      View autoscaler status:
        gcloud compute instance-groups managed describe ${google_compute_region_instance_group_manager.app.name} --region=${var.region} --format="get(status.autoscaler)"
      
      Manually scale (overrides autoscaler):
        gcloud compute instance-groups managed resize ${google_compute_region_instance_group_manager.app.name} --size=3 --region=${var.region}
      
      Rolling update:
        gcloud compute instance-groups managed rolling-action replace ${google_compute_region_instance_group_manager.app.name} --region=${var.region}
    
    ${var.enable_cloud_sql ? <<-SQL
    Cloud SQL:
      Instance: ${google_sql_database_instance.main[0].name}
      Database: ${google_sql_database.database[0].name}
      User: ${google_sql_user.user[0].name}
      Private IP: ${google_sql_database_instance.main[0].private_ip_address}
      Version: ${google_sql_database_instance.main[0].database_version}
      
      Connect using Cloud SQL Proxy:
        cloud-sql-proxy ${google_sql_database_instance.main[0].connection_name}
      
      Connect from Compute Engine (with private IP):
        psql "host=${google_sql_database_instance.main[0].private_ip_address} dbname=${google_sql_database.database[0].name} user=${google_sql_user.user[0].name}"
      
      View database info:
        gcloud sql instances describe ${google_sql_database_instance.main[0].name}
      
      List databases:
        gcloud sql databases list --instance=${google_sql_database_instance.main[0].name}
      
      Create backup:
        gcloud sql backups create --instance=${google_sql_database_instance.main[0].name}
      
      List backups:
        gcloud sql backups list --instance=${google_sql_database_instance.main[0].name}
    SQL
: "Cloud SQL is disabled"}
    
    Monitoring:
      View load balancer metrics:
        gcloud monitoring dashboards list
      
      View MIG metrics:
        gcloud compute instance-groups managed describe ${google_compute_region_instance_group_manager.app.name} --region=${var.region}
      
      View logs:
        gcloud logging read "resource.type=http_load_balancer" --limit=50
    
    Load Testing:
      Generate load to test autoscaling:
        ab -n 10000 -c 100 http://${google_compute_global_forwarding_rule.app.ip_address}/
      
      Or using hey:
        hey -z 5m -c 50 http://${google_compute_global_forwarding_rule.app.ip_address}/
    
    Cleanup:
      To destroy all resources:
        terraform destroy
    
  EOT
}

# ============================================================================
# Connection Strings
# ============================================================================

output "database_connection_string" {
  description = "Database connection string (without password)"
  value = var.enable_cloud_sql ? (
    startswith(var.database_version, "POSTGRES") ?
    "postgresql://${google_sql_user.user[0].name}@${google_sql_database_instance.main[0].private_ip_address}:5432/${google_sql_database.database[0].name}" :
    "mysql://${google_sql_user.user[0].name}@${google_sql_database_instance.main[0].private_ip_address}:3306/${google_sql_database.database[0].name}"
  ) : null
}
# GCP-204: Advanced Patterns
# Demonstrates: Load balancers, Managed Instance Groups, autoscaling, Cloud SQL
# Provider: hashicorp/google
# Run: terraform init && terraform apply
#
# Prerequisites: GCP credentials configured (see GCP-201)

terraform {
  required_version = ">= 1.14"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.24.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider configuration
# ─────────────────────────────────────────────────────────────────────────────

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# ============================================================================
# Network Infrastructure
# ============================================================================

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.required_apis]
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.vpc_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rule - Allow health checks
resource "google_compute_firewall" "allow_health_check" {
  name    = "${var.vpc_name}-allow-health-check"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = [tostring(var.health_check_port)]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["http-server"]
}

# Firewall rule - Allow HTTP
resource "google_compute_firewall" "allow_http" {
  name    = "${var.vpc_name}-allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Firewall rule - Allow internal
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
}

# ============================================================================
# Instance Template & Managed Instance Group
# ============================================================================

# Instance template
resource "google_compute_instance_template" "app" {
  name_prefix  = "gcp-204-app-template-"
  machine_type = var.instance_template_machine_type
  region       = var.region

  tags = ["http-server", "app-server"]

  disk {
    source_image = var.instance_template_image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.instance_template_disk_size
    disk_type    = "pd-standard"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    # No external IP - instances use Cloud NAT
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    
    # Create a simple web page with instance info
    cat > /var/www/html/index.html <<'EOF'
    <!DOCTYPE html>
    <html>
    <head>
        <title>GCP-204 Demo</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f0f0f0; }
            .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            h1 { color: #4285f4; }
            .info { background: #e8f0fe; padding: 10px; border-radius: 4px; margin: 10px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>GCP-204: Advanced Patterns</h1>
            <div class="info">
                <strong>Instance:</strong> $(hostname)<br>
                <strong>Zone:</strong> $(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d/ -f4)<br>
                <strong>Internal IP:</strong> $(hostname -I | awk '{print $1}')<br>
                <strong>Time:</strong> $(date)
            </div>
            <p>This instance is part of a Managed Instance Group with autoscaling and load balancing.</p>
        </div>
    </body>
    </html>
    EOF
    
    systemctl restart nginx
  EOT

  labels = merge(
    var.labels,
    {
      environment = var.environment
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Regional Managed Instance Group
resource "google_compute_region_instance_group_manager" "app" {
  name               = "gcp-204-mig"
  base_instance_name = "app"
  region             = var.region

  version {
    instance_template = google_compute_instance_template.app.id
  }

  target_size = var.mig_target_size

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }

  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
    max_unavailable_fixed        = 0
    instance_redistribution_type = "PROACTIVE"
  }
}

# Autoscaler
resource "google_compute_region_autoscaler" "app" {
  name   = "gcp-204-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.app.id

  autoscaling_policy {
    min_replicas    = var.autoscaler_min_replicas
    max_replicas    = var.autoscaler_max_replicas
    cooldown_period = var.autoscaler_cooldown_period

    cpu_utilization {
      target = var.autoscaler_cpu_target
    }

    metric {
      name   = "compute.googleapis.com/instance/network/received_bytes_count"
      target = 1000000
      type   = "GAUGE"
    }
  }
}

# ============================================================================
# Load Balancer
# ============================================================================

# Health check for load balancer
resource "google_compute_health_check" "lb" {
  name                = "gcp-204-lb-health-check"
  check_interval_sec  = var.health_check_interval
  timeout_sec         = var.health_check_timeout
  healthy_threshold   = var.health_check_healthy_threshold
  unhealthy_threshold = var.health_check_unhealthy_threshold

  http_health_check {
    port         = var.health_check_port
    request_path = "/"
  }
}

# Health check for auto-healing
resource "google_compute_health_check" "autohealing" {
  name                = "gcp-204-autohealing-health-check"
  check_interval_sec  = 30
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# Backend service
resource "google_compute_backend_service" "app" {
  name                  = "gcp-204-backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  health_checks = [google_compute_health_check.lb.id]

  backend {
    group           = google_compute_region_instance_group_manager.app.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  iap {
    enabled = false
  }
}

# URL map
resource "google_compute_url_map" "app" {
  name            = "gcp-204-url-map"
  default_service = google_compute_backend_service.app.id
}

# HTTP proxy
resource "google_compute_target_http_proxy" "app" {
  name    = "gcp-204-http-proxy"
  url_map = google_compute_url_map.app.id
}

# Global forwarding rule (external IP)
resource "google_compute_global_forwarding_rule" "app" {
  name                  = "gcp-204-forwarding-rule"
  target                = google_compute_target_http_proxy.app.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# ============================================================================
# Cloud SQL
# ============================================================================

# Private IP allocation for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  count         = var.enable_cloud_sql ? 1 : 0
  name          = "gcp-204-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# Private VPC connection
resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = var.enable_cloud_sql ? 1 : 0
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]

  depends_on = [google_project_service.required_apis]
}

# Cloud SQL instance
resource "google_sql_database_instance" "main" {
  count            = var.enable_cloud_sql ? 1 : 0
  name             = "gcp-204-db-${random_id.suffix.hex}"
  database_version = var.database_version
  region           = var.region

  settings {
    tier              = var.database_tier
    disk_size         = var.database_disk_size
    disk_type         = var.database_disk_type
    availability_type = var.database_ha_enabled ? "REGIONAL" : "ZONAL"

    backup_configuration {
      enabled                        = var.database_backup_enabled
      start_time                     = var.database_backup_start_time
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_google_cloud_services = true
    }

    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
    }

    database_flags {
      name  = "max_connections"
      value = "100"
    }

    maintenance_window {
      day          = 7  # Sunday
      hour         = 3  # 3 AM
      update_track = "stable"
    }
  }

  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Database
resource "google_sql_database" "database" {
  count    = var.enable_cloud_sql ? 1 : 0
  name     = var.database_name
  instance = google_sql_database_instance.main[0].name
}

# Database user
resource "google_sql_user" "user" {
  count    = var.enable_cloud_sql ? 1 : 0
  name     = var.database_user
  instance = google_sql_database_instance.main[0].name
  password = random_password.db_password.result
}
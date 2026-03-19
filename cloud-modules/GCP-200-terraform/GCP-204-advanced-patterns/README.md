# GCP-204: Advanced GCP Patterns

**Level**: 204 (Intermediate - Cloud Specific)  
**Duration**: 1 hour  
**Prerequisites**: GCP-203 (Security & Storage)  
**Status**: 🚧 **PLANNED** - Content in development

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ Configure Cloud Load Balancing
- ✅ Implement Managed Instance Groups (MIGs)
- ✅ Set up autoscaling policies
- ✅ Deploy Cloud SQL databases
- ✅ Build multi-region architectures
- ✅ Configure Cloud Monitoring and Logging
- ✅ Implement production-ready patterns
- ✅ Optimize costs and performance

---

## 📚 Topics Covered

### 1. Cloud Load Balancing
- HTTP(S) Load Balancer
- TCP/SSL Proxy Load Balancer
- Network Load Balancer
- Internal Load Balancer
- Backend services and health checks
- URL maps and path-based routing
- SSL certificates and policies

### 2. Managed Instance Groups (MIGs)
- Regional vs zonal MIGs
- Instance templates
- Autoscaling policies
- Rolling updates
- Health checks
- Load balancer integration

### 3. Autoscaling
- CPU-based autoscaling
- Load balancing utilization
- Custom metrics
- Scaling policies
- Cooldown periods
- Min/max instances

### 4. Cloud SQL
- MySQL, PostgreSQL, SQL Server
- High availability configuration
- Backup and recovery
- Read replicas
- Private IP connectivity
- Maintenance windows

### 5. Multi-Region Deployments
- Regional resource distribution
- Cross-region load balancing
- Data replication strategies
- Disaster recovery
- Latency optimization

### 6. Cloud CDN
- CDN configuration
- Cache policies
- Signed URLs
- Cache invalidation
- Performance optimization

### 7. Cloud Monitoring & Logging
- Uptime checks
- Alerting policies
- Log-based metrics
- Dashboards
- SLOs and SLIs

### 8. Production Patterns
- Blue-green deployments
- Canary deployments
- Circuit breakers
- Rate limiting
- Cost optimization

---

## 🛠️ Hands-On Labs

### Lab 1: HTTP(S) Load Balancer
**Objective**: Create a global load balancer with backend services

**Steps**:
1. Create instance template
2. Create managed instance group
3. Configure health check
4. Create backend service
5. Configure URL map
6. Create HTTP(S) load balancer
7. Test load distribution

**Expected Outcome**: Working global load balancer

---

### Lab 2: Autoscaling MIG
**Objective**: Implement autoscaling based on CPU utilization

**Steps**:
1. Create instance template with load generator
2. Create regional MIG
3. Configure autoscaling policy
4. Set min/max instances
5. Generate load
6. Observe scaling behavior
7. Test scale-down

**Expected Outcome**: MIG that scales based on load

---

### Lab 3: Cloud SQL Database
**Objective**: Deploy highly available Cloud SQL instance

**Steps**:
1. Create Cloud SQL instance
2. Configure high availability
3. Set up automated backups
4. Create read replica
5. Configure private IP
6. Connect from Compute Engine
7. Test failover

**Expected Outcome**: Production-ready Cloud SQL setup

---

### Lab 4: Multi-Region Architecture
**Objective**: Build infrastructure across multiple regions

**Steps**:
1. Deploy resources in multiple regions
2. Configure cross-region load balancing
3. Set up Cloud CDN
4. Implement health checks
5. Test failover scenarios
6. Measure latency

**Expected Outcome**: Resilient multi-region architecture

---

### Lab 5: Monitoring and Alerting
**Objective**: Implement comprehensive monitoring

**Steps**:
1. Create uptime checks
2. Configure alerting policies
3. Set up notification channels
4. Create custom dashboards
5. Implement log-based metrics
6. Test alert triggers

**Expected Outcome**: Production monitoring setup

---

## 📖 Key Concepts

### Load Balancer Types

| Type | Scope | Use Case | Layer |
|------|-------|----------|-------|
| **HTTP(S)** | Global | Web applications | L7 |
| **TCP/SSL Proxy** | Global | Non-HTTP traffic | L4 |
| **Network** | Regional | High performance | L4 |
| **Internal** | Regional | Internal services | L4/L7 |

### Autoscaling Metrics

| Metric | Description | Best For |
|--------|-------------|----------|
| **CPU utilization** | Average CPU usage | General workloads |
| **HTTP load balancing** | Requests per second | Web applications |
| **Custom metrics** | Application-specific | Specialized workloads |
| **Pub/Sub queue** | Message backlog | Event-driven systems |

### Cloud SQL Tiers

| Tier | vCPUs | Memory | Use Case |
|------|-------|--------|----------|
| **db-f1-micro** | Shared | 0.6 GB | Development |
| **db-g1-small** | Shared | 1.7 GB | Small apps |
| **db-n1-standard-1** | 1 | 3.75 GB | Production |
| **db-n1-highmem-2** | 2 | 13 GB | Memory-intensive |

---

## 💻 Example Code

### HTTP(S) Load Balancer with MIG

```hcl
# Instance template
resource "google_compute_instance_template" "web" {
  name_prefix  = "web-template-"
  machine_type = "e2-medium"
  
  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }
  
  network_interface {
    network = "default"
    access_config {}
  }
  
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    cat > /var/www/html/index.html <<HTML
    <h1>Server: $(hostname)</h1>
    <p>Region: $(curl -H "Metadata-Flavor: Google" \
      http://metadata.google.internal/computeMetadata/v1/instance/zone)</p>
    HTML
  EOF
  
  tags = ["http-server"]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Health check
resource "google_compute_health_check" "http" {
  name               = "http-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  
  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# Regional MIG
resource "google_compute_region_instance_group_manager" "web" {
  name   = "web-mig"
  region = "us-central1"
  
  base_instance_name = "web"
  
  version {
    instance_template = google_compute_instance_template.web.id
  }
  
  target_size = 2
  
  named_port {
    name = "http"
    port = 80
  }
  
  auto_healing_policies {
    health_check      = google_compute_health_check.http.id
    initial_delay_sec = 300
  }
}

# Autoscaler
resource "google_compute_region_autoscaler" "web" {
  name   = "web-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.web.id
  
  autoscaling_policy {
    max_replicas    = 10
    min_replicas    = 2
    cooldown_period = 60
    
    cpu_utilization {
      target = 0.6
    }
    
    load_balancing_utilization {
      target = 0.8
    }
  }
}

# Backend service
resource "google_compute_backend_service" "web" {
  name          = "web-backend"
  health_checks = [google_compute_health_check.http.id]
  
  backend {
    group           = google_compute_region_instance_group_manager.web.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
  
  enable_cdn = true
  
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl       = 3600
    max_ttl           = 86400
    client_ttl        = 3600
    negative_caching  = true
  }
}

# URL map
resource "google_compute_url_map" "web" {
  name            = "web-url-map"
  default_service = google_compute_backend_service.web.id
}

# HTTP proxy
resource "google_compute_target_http_proxy" "web" {
  name    = "web-http-proxy"
  url_map = google_compute_url_map.web.id
}

# Global forwarding rule
resource "google_compute_global_forwarding_rule" "web" {
  name       = "web-forwarding-rule"
  target     = google_compute_target_http_proxy.web.id
  port_range = "80"
  ip_protocol = "TCP"
}

# Output load balancer IP
output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.web.ip_address
}
```

### Cloud SQL with High Availability

```hcl
# Random suffix for unique names
resource "random_id" "db_suffix" {
  byte_length = 4
}

# Cloud SQL instance
resource "google_sql_database_instance" "main" {
  name             = "main-instance-${random_id.db_suffix.hex}"
  database_version = "POSTGRES_15"
  region           = "us-central1"
  
  settings {
    tier              = "db-n1-standard-2"
    availability_type = "REGIONAL"  # High availability
    disk_size         = 100
    disk_type         = "PD_SSD"
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
      require_ssl     = true
    }
    
    maintenance_window {
      day          = 7  # Sunday
      hour         = 3
      update_track = "stable"
    }
    
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }
    
    database_flags {
      name  = "max_connections"
      value = "100"
    }
  }
  
  deletion_protection = true
  
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Database
resource "google_sql_database" "app_db" {
  name     = "app_database"
  instance = google_sql_database_instance.main.name
}

# Database user
resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.main.name
  password = var.db_password  # Use Secret Manager in production
}

# Read replica
resource "google_sql_database_instance" "replica" {
  name                 = "replica-instance-${random_id.db_suffix.hex}"
  master_instance_name = google_sql_database_instance.main.name
  region               = "us-east1"
  database_version     = "POSTGRES_15"
  
  replica_configuration {
    failover_target = false
  }
  
  settings {
    tier      = "db-n1-standard-2"
    disk_size = 100
    disk_type = "PD_SSD"
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }
}

# Private VPC connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
```

### Multi-Region Deployment

```hcl
# Deploy in multiple regions
locals {
  regions = ["us-central1", "europe-west1", "asia-east1"]
}

# Regional MIGs
resource "google_compute_region_instance_group_manager" "regional" {
  for_each = toset(local.regions)
  
  name   = "web-mig-${each.key}"
  region = each.key
  
  base_instance_name = "web-${each.key}"
  
  version {
    instance_template = google_compute_instance_template.web.id
  }
  
  target_size = 2
  
  named_port {
    name = "http"
    port = 80
  }
  
  auto_healing_policies {
    health_check      = google_compute_health_check.http.id
    initial_delay_sec = 300
  }
}

# Backend service with multiple regions
resource "google_compute_backend_service" "multi_region" {
  name          = "multi-region-backend"
  health_checks = [google_compute_health_check.http.id]
  
  dynamic "backend" {
    for_each = google_compute_region_instance_group_manager.regional
    content {
      group           = backend.value.instance_group
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    }
  }
  
  enable_cdn = true
  
  cdn_policy {
    cache_mode       = "CACHE_ALL_STATIC"
    default_ttl      = 3600
    max_ttl          = 86400
    negative_caching = true
  }
}
```

### Cloud Monitoring and Alerting

```hcl
# Uptime check
resource "google_monitoring_uptime_check_config" "http" {
  display_name = "Web Application Uptime Check"
  timeout      = "10s"
  period       = "60s"
  
  http_check {
    path         = "/"
    port         = 80
    request_method = "GET"
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = google_compute_global_forwarding_rule.web.ip_address
    }
  }
}

# Notification channel
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification"
  type         = "email"
  
  labels = {
    email_address = var.alert_email
  }
}

# Alert policy for high CPU
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "High CPU Usage"
  combiner     = "OR"
  
  conditions {
    display_name = "CPU usage above 80%"
    
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [google_monitoring_notification_channel.email.id]
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Alert policy for uptime check
resource "google_monitoring_alert_policy" "uptime_alert" {
  display_name = "Uptime Check Failed"
  combiner     = "OR"
  
  conditions {
    display_name = "Uptime check failed"
    
    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\""
      duration        = "60s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      
      aggregations {
        alignment_period     = "60s"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        group_by_fields      = ["resource.label.*"]
      }
    }
  }
  
  notification_channels = [google_monitoring_notification_channel.email.id]
}

# Custom dashboard
resource "google_monitoring_dashboard" "main" {
  dashboard_json = jsonencode({
    displayName = "Application Dashboard"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "CPU Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "Request Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"http_load_balancer\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}
```

---

## 🧪 Validation & Testing

### Test Load Balancer

```bash
# Get load balancer IP
LB_IP=$(gcloud compute forwarding-rules describe web-forwarding-rule \
  --global --format="get(IPAddress)")

# Test HTTP endpoint
curl http://$LB_IP

# Load test
ab -n 10000 -c 100 http://$LB_IP/
```

### Monitor Autoscaling

```bash
# Watch MIG size
watch -n 5 'gcloud compute instance-groups managed describe web-mig \
  --region=us-central1 --format="get(targetSize)"'

# View autoscaler status
gcloud compute instance-groups managed describe web-mig \
  --region=us-central1 --format="get(status.autoscaler)"
```

### Test Cloud SQL Connection

```bash
# Connect to Cloud SQL from Compute Engine
gcloud sql connect main-instance --user=app_user --database=app_database
```

---

## 💡 Best Practices

### Load Balancing
1. **Use health checks** - Ensure traffic only goes to healthy instances
2. **Enable Cloud CDN** - Improve performance and reduce costs
3. **Configure SSL** - Use managed certificates
4. **Set appropriate timeouts** - Based on application needs
5. **Use connection draining** - For graceful shutdowns

### Autoscaling
1. **Set realistic targets** - 60-80% CPU utilization
2. **Configure cooldown** - Prevent flapping
3. **Use multiple metrics** - CPU + load balancing utilization
4. **Test scaling** - Verify behavior under load
5. **Set appropriate min/max** - Based on capacity planning

### Cloud SQL
1. **Enable HA** - For production databases
2. **Use private IP** - More secure than public
3. **Configure backups** - Automated with PITR
4. **Use read replicas** - For read-heavy workloads
5. **Monitor performance** - Use Query Insights

### Cost Optimization
1. **Right-size instances** - Don't over-provision
2. **Use committed use discounts** - For predictable workloads
3. **Enable autoscaling** - Scale down when not needed
4. **Use preemptible VMs** - For fault-tolerant workloads
5. **Monitor costs** - Set up budgets and alerts

---

## 📚 Additional Resources

### Official Documentation
- [Cloud Load Balancing](https://cloud.google.com/load-balancing/docs)
- [Managed Instance Groups](https://cloud.google.com/compute/docs/instance-groups)
- [Cloud SQL](https://cloud.google.com/sql/docs)
- [Cloud Monitoring](https://cloud.google.com/monitoring/docs)

### Terraform Resources
- [google_compute_backend_service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service)
- [google_compute_instance_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager)
- [google_sql_database_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance)

---

## ✅ Module Completion Checklist

You've completed GCP-204 when you can:

- [ ] Configure HTTP(S) load balancers
- [ ] Implement managed instance groups
- [ ] Set up autoscaling
- [ ] Deploy Cloud SQL databases
- [ ] Build multi-region architectures
- [ ] Configure monitoring and alerting
- [ ] Implement production-ready patterns
- [ ] Optimize costs and performance

---

## 🎓 Course Completion

**Congratulations!** You've completed GCP-200: Google Cloud Platform with Terraform.

### What You've Learned
- ✅ GCP authentication and setup
- ✅ VPC networking and Compute Engine
- ✅ IAM, storage, and encryption
- ✅ Load balancing and autoscaling
- ✅ Production-ready patterns

### Next Steps

1. **Practice**: Build real projects on GCP
2. **Certifications**: Consider Google Cloud certifications
3. **Multi-Cloud**: Explore [MC-300: Multi-Cloud Architecture](../../MC-300-multi-cloud/README.md)
4. **Contribute**: Share your knowledge and examples

---

*Part of [GCP-200: Google Cloud Platform with Terraform](../README.md)*  
*Last Updated: 2026-03-18*
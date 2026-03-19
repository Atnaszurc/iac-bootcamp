# GCP-202: Compute & Networking
# Demonstrates: VPC, subnets, firewall rules, Cloud NAT, Compute Engine instances
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
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

# Get latest Debian image
data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

# Custom VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "Custom VPC for GCP-202 training"

  depends_on = [google_project_service.compute]
}

# Public subnet
resource "google_compute_subnetwork" "public" {
  name          = "${var.vpc_name}-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  # Enable Private Google Access
  private_ip_google_access = true

  # Enable VPC Flow Logs
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Private subnet
resource "google_compute_subnetwork" "private" {
  name          = "${var.vpc_name}-private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Firewall rule: Allow SSH from anywhere
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.vpc_name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-enabled"]

  description = "Allow SSH access to instances with ssh-enabled tag"
}

# Firewall rule: Allow HTTP/HTTPS
resource "google_compute_firewall" "allow_web" {
  name    = "${var.vpc_name}-allow-web"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]

  description = "Allow HTTP/HTTPS to web servers"
}

# Firewall rule: Allow internal traffic
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

  source_ranges = [var.public_subnet_cidr, var.private_subnet_cidr]

  description = "Allow all internal traffic within VPC"
}

# Firewall rule: Allow health checks
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.vpc_name}-allow-health-checks"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["allow-health-checks"]

  description = "Allow Google Cloud health checks"
}

# Cloud Router for Cloud NAT
resource "google_compute_router" "router" {
  count   = var.enable_nat ? 1 : 0
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  count  = var.enable_nat ? 1 : 0
  name   = "${var.vpc_name}-nat"
  router = google_compute_router.router[0].name
  region = google_compute_router.router[0].region

  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Public instances (with external IP)
resource "google_compute_instance" "public" {
  count        = var.instance_count
  name         = "${var.vpc_name}-public-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["ssh-enabled", "web-server"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id

    # Assign external IP
    access_config {
      # Ephemeral IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key != "" ? var.ssh_public_key : file(var.ssh_public_key_file)}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Create custom index page
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>GCP-202 Public Instance</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .info { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        </style>
    </head>
    <body>
        <h1>GCP-202 Training - Public Instance</h1>
        <div class="info">
            <p><strong>Hostname:</strong> $(hostname)</p>
            <p><strong>Instance:</strong> ${var.vpc_name}-public-${count.index + 1}</p>
            <p><strong>Zone:</strong> ${var.zone}</p>
            <p><strong>Environment:</strong> ${var.environment}</p>
            <p><strong>Subnet:</strong> Public (${var.public_subnet_cidr})</p>
        </div>
    </body>
    </html>
HTML
  EOF

  labels = merge(
    var.labels,
    {
      environment = var.environment
      tier        = "public"
      instance    = "public-${count.index + 1}"
    }
  )

  allow_stopping_for_update = true

  depends_on = [google_project_service.compute]
}

# Private instances (no external IP)
resource "google_compute_instance" "private" {
  count        = var.instance_count
  name         = "${var.vpc_name}-private-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["ssh-enabled"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
    # No access_config = no external IP
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key != "" ? var.ssh_public_key : file(var.ssh_public_key_file)}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y curl
    
    # Test internet connectivity via Cloud NAT
    echo "Testing internet connectivity..." > /tmp/nat-test.log
    if curl -s https://www.google.com > /dev/null; then
      echo "SUCCESS: Internet access via Cloud NAT working" >> /tmp/nat-test.log
    else
      echo "FAILED: No internet access" >> /tmp/nat-test.log
    fi
  EOF

  labels = merge(
    var.labels,
    {
      environment = var.environment
      tier        = "private"
      instance    = "private-${count.index + 1}"
    }
  )

  allow_stopping_for_update = true

  depends_on = [
    google_project_service.compute,
    google_compute_router_nat.nat
  ]
}
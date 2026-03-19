# GCP-202: Compute & Networking

**Level**: 202 (Intermediate - Cloud Specific)  
**Duration**: 2 hours  
**Prerequisites**: GCP-201 (Setup & Authentication)  
**Status**: 🚧 **PLANNED** - Content in development

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ Create custom VPC networks in GCP
- ✅ Configure subnets with custom IP ranges
- ✅ Implement firewall rules for network security
- ✅ Deploy Compute Engine instances
- ✅ Configure Cloud NAT for private instances
- ✅ Use instance templates for standardization
- ✅ Build multi-tier network architectures
- ✅ Understand regional vs zonal resources

---

## 📚 Topics Covered

### 1. VPC Networks
- Auto-mode vs custom-mode VPCs
- VPC network creation
- Subnet IP address planning (RFC 1918)
- Regional subnets
- Secondary IP ranges
- VPC peering
- Shared VPC concepts

### 2. Subnets
- Creating custom subnets
- IP address range selection
- Private Google Access
- Flow logs
- Regional subnet distribution
- Subnet expansion

### 3. Firewall Rules
- Ingress and egress rules
- Priority and rule evaluation
- Network tags for targeting
- Service accounts as targets
- Allow and deny rules
- Logging firewall rules
- Best practices for firewall design

### 4. Cloud NAT & Cloud Router
- Cloud Router configuration
- Cloud NAT for outbound internet access
- NAT IP allocation
- Logging and monitoring
- Regional NAT configuration

### 5. Compute Engine Instances
- Machine types and families (E2, N2, N2D, C2, M2)
- Custom machine types
- Image selection (public images, custom images)
- Boot disk configuration
- Startup scripts and metadata
- SSH key management
- Network interface configuration
- Labels and metadata

### 6. Instance Templates
- Creating instance templates
- Template versioning
- Using templates with instance groups
- Updating templates

### 7. Regional vs Zonal Resources
- Understanding GCP regions and zones
- Regional resources (subnets, Cloud NAT)
- Zonal resources (instances, disks)
- High availability considerations

---

## 🛠️ Hands-On Labs

### Lab 1: Create Custom VPC Network
**Objective**: Build a custom VPC with multiple subnets

**Steps**:
1. Create a custom-mode VPC network
2. Add subnets in different regions
3. Configure Private Google Access
4. Enable VPC Flow Logs
5. Verify network in Cloud Console

**Expected Outcome**: Custom VPC with regional subnets

---

### Lab 2: Configure Firewall Rules
**Objective**: Implement network security with firewall rules

**Steps**:
1. Create firewall rule for SSH (port 22)
2. Create firewall rule for HTTP (port 80)
3. Create firewall rule for HTTPS (port 443)
4. Use network tags for targeting
5. Test connectivity
6. Create deny rule for specific traffic

**Expected Outcome**: Secure network with proper firewall rules

---

### Lab 3: Deploy Compute Engine Instance
**Objective**: Launch a VM with custom configuration

**Steps**:
1. Choose appropriate machine type
2. Select Ubuntu or Debian image
3. Configure boot disk
4. Add startup script
5. Configure network interface
6. Add SSH keys
7. Deploy instance
8. SSH into instance
9. Verify startup script execution

**Expected Outcome**: Running Compute Engine instance accessible via SSH

---

### Lab 4: Configure Cloud NAT
**Objective**: Enable internet access for private instances

**Steps**:
1. Create Cloud Router
2. Configure Cloud NAT
3. Deploy instance without external IP
4. Test outbound internet connectivity
5. Review NAT logs

**Expected Outcome**: Private instance with outbound internet access

---

### Lab 5: Multi-Tier Architecture
**Objective**: Build a complete multi-tier network

**Steps**:
1. Create VPC with public and private subnets
2. Deploy web server in public subnet
3. Deploy database server in private subnet
4. Configure firewall rules for each tier
5. Set up Cloud NAT for private subnet
6. Test connectivity between tiers
7. Verify internet access patterns

**Expected Outcome**: Production-like multi-tier architecture

---

## 📖 Key Concepts

### VPC Network Architecture

```
VPC Network (Global)
├── Subnet 1 (us-central1) - 10.0.1.0/24
├── Subnet 2 (us-east1) - 10.0.2.0/24
└── Subnet 3 (europe-west1) - 10.0.3.0/24

Firewall Rules (Global)
├── allow-ssh (priority 1000)
├── allow-http (priority 1000)
└── deny-all (priority 65534)
```

### Machine Type Families

| Family | Use Case | Example Types |
|--------|----------|---------------|
| E2 | Cost-optimized, general purpose | e2-micro, e2-medium |
| N2 | Balanced price/performance | n2-standard-2, n2-standard-4 |
| N2D | AMD-based, cost-effective | n2d-standard-2 |
| C2 | Compute-optimized | c2-standard-4 |
| M2 | Memory-optimized | m2-ultramem-208 |

### IP Address Planning

**Private IP Ranges (RFC 1918)**:
- `10.0.0.0/8` - Large networks
- `172.16.0.0/12` - Medium networks
- `192.168.0.0/16` - Small networks

**Recommended Subnet Sizes**:
- `/24` - 256 addresses (251 usable)
- `/20` - 4,096 addresses (4,091 usable)
- `/16` - 65,536 addresses (65,531 usable)

---

## 💻 Example Code

### Custom VPC Network

```hcl
# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "custom-vpc"
  auto_create_subnetworks = false
  description             = "Custom VPC for multi-tier application"
}

# Subnet in us-central1
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
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

# Subnet in us-east1
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-east1"
  network       = google_compute_network.vpc.id
  
  private_ip_google_access = true
}
```

### Firewall Rules

```hcl
# Allow SSH from anywhere
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-enabled"]
  
  description = "Allow SSH access to instances with ssh-enabled tag"
}

# Allow HTTP/HTTPS from anywhere
resource "google_compute_firewall" "allow_web" {
  name    = "allow-web"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  
  description = "Allow HTTP/HTTPS to web servers"
}

# Allow internal traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
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
  
  source_ranges = ["10.0.0.0/8"]
  
  description = "Allow all internal traffic within VPC"
}
```

### Cloud NAT Configuration

```hcl
# Cloud Router
resource "google_compute_router" "router" {
  name    = "nat-router"
  region  = "us-central1"
  network = google_compute_network.vpc.id
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name   = "nat-gateway"
  router = google_compute_router.router.name
  region = google_compute_router.router.region
  
  nat_ip_allocate_option = "AUTO_ONLY"
  
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
```

### Compute Engine Instance

```hcl
# Get latest Ubuntu image
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

# Compute Engine instance
resource "google_compute_instance" "web_server" {
  name         = "web-server-01"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  
  tags = ["web-server", "ssh-enabled"]
  
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 20
      type  = "pd-standard"
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    
    # Assign external IP
    access_config {
      # Ephemeral IP
    }
  }
  
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
  
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
  EOF
  
  labels = {
    environment = "dev"
    managed_by  = "terraform"
  }
  
  # Allow stopping for updates
  allow_stopping_for_update = true
}
```

### Instance Template

```hcl
# Instance template for web servers
resource "google_compute_instance_template" "web_template" {
  name_prefix  = "web-template-"
  machine_type = "e2-medium"
  region       = "us-central1"
  
  tags = ["web-server", "ssh-enabled"]
  
  disk {
    source_image = data.google_compute_image.ubuntu.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-standard"
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    
    access_config {
      # Ephemeral IP
    }
  }
  
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
  
  metadata_startup_script = file("${path.module}/startup-script.sh")
  
  labels = {
    environment = "production"
    managed_by  = "terraform"
  }
  
  # Create new template before destroying old one
  lifecycle {
    create_before_destroy = true
  }
}
```

### Multi-Tier Architecture

```hcl
# Web tier (public subnet)
resource "google_compute_instance" "web" {
  count        = 2
  name         = "web-${count.index + 1}"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  
  tags = ["web-server", "ssh-enabled"]
  
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    access_config {}
  }
  
  metadata_startup_script = file("${path.module}/web-startup.sh")
}

# Database tier (private subnet, no external IP)
resource "google_compute_instance" "database" {
  name         = "database-01"
  machine_type = "n2-standard-2"
  zone         = "us-east1-b"
  
  tags = ["database", "ssh-enabled"]
  
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 50
      type  = "pd-ssd"
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
    # No access_config = no external IP
  }
  
  metadata_startup_script = file("${path.module}/db-startup.sh")
}

# Firewall: Allow web tier to access database tier
resource "google_compute_firewall" "web_to_db" {
  name    = "allow-web-to-db"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["5432"]  # PostgreSQL
  }
  
  source_tags = ["web-server"]
  target_tags = ["database"]
  
  description = "Allow web servers to access database"
}
```

---

## 🧪 Validation & Testing

### Verify VPC and Subnets

```bash
# List VPC networks
gcloud compute networks list

# Describe VPC
gcloud compute networks describe custom-vpc

# List subnets
gcloud compute networks subnets list --network=custom-vpc
```

### Verify Firewall Rules

```bash
# List firewall rules
gcloud compute firewall-rules list --filter="network:custom-vpc"

# Describe specific rule
gcloud compute firewall-rules describe allow-ssh
```

### Test Instance Connectivity

```bash
# SSH into instance
gcloud compute ssh web-server-01 --zone=us-central1-a

# Test HTTP endpoint
curl http://EXTERNAL_IP

# Test internal connectivity
ping 10.0.2.5
```

### Verify Cloud NAT

```bash
# From private instance (via SSH through bastion)
curl ifconfig.me  # Should show NAT IP, not instance IP
```

---

## 🚨 Common Issues & Solutions

### Issue 1: "Quota exceeded"

**Error**: `Quota 'CPUS' exceeded. Limit: 24.0 in region us-central1`

**Solution**: Request quota increase or use smaller machine types

### Issue 2: "IP address already in use"

**Error**: `The resource 'projects/.../regions/.../subnetworks/...' already exists`

**Solution**: Use different IP ranges or delete existing subnet

### Issue 3: "Cannot SSH into instance"

**Possible Causes**:
- Firewall rule not allowing SSH
- Wrong SSH key
- Instance not fully started

**Solution**: Check firewall rules, verify SSH keys, wait for startup

### Issue 4: "Private instance cannot access internet"

**Solution**: Configure Cloud NAT for the subnet's region

---

## 💡 Best Practices

### Network Design
1. **Use custom VPCs** - More control than auto-mode
2. **Plan IP ranges** - Avoid overlapping with other networks
3. **Use /24 subnets** - Good balance of size and flexibility
4. **Enable Private Google Access** - Access GCP services without external IPs
5. **Use regional subnets** - Better for high availability

### Firewall Rules
1. **Least privilege** - Only allow necessary traffic
2. **Use network tags** - More flexible than IP-based rules
3. **Document rules** - Use descriptions
4. **Log important rules** - Enable logging for security analysis
5. **Order matters** - Lower priority numbers evaluated first

### Compute Instances
1. **Use labels** - For organization and cost tracking
2. **Right-size instances** - Don't over-provision
3. **Use startup scripts** - Automate configuration
4. **Use instance templates** - For consistency
5. **Enable deletion protection** - For production instances

### Cost Optimization
1. **Use E2 instances** - Most cost-effective for general workloads
2. **Use preemptible VMs** - Up to 80% cheaper for fault-tolerant workloads
3. **Stop unused instances** - Don't leave them running
4. **Use committed use discounts** - For predictable workloads
5. **Right-size disks** - Don't over-provision storage

---

## 📚 Additional Resources

### Official Documentation
- [VPC Networks](https://cloud.google.com/vpc/docs)
- [Firewall Rules](https://cloud.google.com/vpc/docs/firewalls)
- [Compute Engine](https://cloud.google.com/compute/docs)
- [Cloud NAT](https://cloud.google.com/nat/docs)

### Terraform Resources
- [google_compute_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network)
- [google_compute_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork)
- [google_compute_firewall](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall)
- [google_compute_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)

---

## ✅ Module Completion Checklist

You've completed GCP-202 when you can:

- [ ] Create custom VPC networks
- [ ] Configure subnets with proper IP ranges
- [ ] Implement firewall rules
- [ ] Deploy Compute Engine instances
- [ ] Configure Cloud NAT
- [ ] Use instance templates
- [ ] Build multi-tier architectures
- [ ] Troubleshoot networking issues

---

## 🔄 What's Next?

After completing GCP-202, proceed to:

**→ [GCP-203: Security & Storage](../GCP-203-security-storage/README.md)**

Learn IAM, service accounts, Cloud Storage, and encryption.

---

*Part of [GCP-200: Google Cloud Platform with Terraform](../README.md)*  
*Last Updated: 2026-03-18*
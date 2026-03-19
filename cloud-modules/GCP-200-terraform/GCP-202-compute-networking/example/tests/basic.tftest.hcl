# ============================================================================
# GCP-202: Compute & Networking - Terraform Tests with Mock Provider
# ============================================================================
# Uses mock_provider to test configuration without real GCP credentials.

mock_provider "google" {}

mock_provider "random" {}

# Basic test for GCP-202 example
# Tests VPC, subnets, firewall rules, Cloud NAT, and Compute Engine instances

variables {
  project_id           = "test-project-12345"
  region               = "us-central1"
  zone                 = "us-central1-a"
  environment          = "dev"
  vpc_name             = "test-vpc"
  public_subnet_cidr   = "10.0.1.0/24"
  private_subnet_cidr  = "10.0.2.0/24"
  instance_count       = 2
  machine_type         = "e2-medium"
  enable_nat           = true
  ssh_user             = "terraform"
  ssh_public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... test-key"
}

run "validate_vpc_configuration" {
  command = plan

  assert {
    condition     = google_compute_network.vpc.name == "test-vpc"
    error_message = "VPC name should be test-vpc"
  }

  assert {
    condition     = google_compute_network.vpc.auto_create_subnetworks == false
    error_message = "VPC should be custom mode (not auto-create subnets)"
  }
}

run "validate_subnet_configuration" {
  command = plan

  assert {
    condition     = google_compute_subnetwork.public.ip_cidr_range == "10.0.1.0/24"
    error_message = "Public subnet CIDR should be 10.0.1.0/24"
  }

  assert {
    condition     = google_compute_subnetwork.private.ip_cidr_range == "10.0.2.0/24"
    error_message = "Private subnet CIDR should be 10.0.2.0/24"
  }

  assert {
    condition     = google_compute_subnetwork.public.private_ip_google_access == true
    error_message = "Public subnet should have Private Google Access enabled"
  }

  assert {
    condition     = google_compute_subnetwork.private.private_ip_google_access == true
    error_message = "Private subnet should have Private Google Access enabled"
  }

  assert {
    condition     = google_compute_subnetwork.public.region == var.region
    error_message = "Public subnet should be in the specified region"
  }
}

run "validate_vpc_flow_logs" {
  command = plan

  assert {
    condition     = length(google_compute_subnetwork.public.log_config) > 0
    error_message = "Public subnet should have VPC Flow Logs enabled"
  }

  assert {
    condition     = length(google_compute_subnetwork.private.log_config) > 0
    error_message = "Private subnet should have VPC Flow Logs enabled"
  }

  assert {
    condition     = google_compute_subnetwork.public.log_config[0].aggregation_interval == "INTERVAL_5_SEC"
    error_message = "Flow logs should use 5 second aggregation interval"
  }
}

run "validate_firewall_rules" {
  command = plan

  assert {
    condition     = google_compute_firewall.allow_ssh.network == google_compute_network.vpc.name
    error_message = "SSH firewall rule should be attached to VPC"
  }

  assert {
    condition     = length([for rule in google_compute_firewall.allow_ssh.allow : rule if contains(rule.ports, "22")]) > 0
    error_message = "SSH firewall rule should allow port 22"
  }

  assert {
    condition     = contains(google_compute_firewall.allow_ssh.target_tags, "ssh-enabled")
    error_message = "SSH firewall rule should target ssh-enabled tag"
  }

  assert {
    condition     = length([for rule in google_compute_firewall.allow_web.allow : rule if contains(rule.ports, "80")]) > 0
    error_message = "Web firewall rule should allow port 80"
  }

  assert {
    condition     = length([for rule in google_compute_firewall.allow_web.allow : rule if contains(rule.ports, "443")]) > 0
    error_message = "Web firewall rule should allow port 443"
  }
}

run "validate_internal_firewall" {
  command = plan

  assert {
    condition     = length(google_compute_firewall.allow_internal.allow) >= 3
    error_message = "Internal firewall should allow TCP, UDP, and ICMP"
  }

  assert {
    condition     = contains(google_compute_firewall.allow_internal.source_ranges, var.public_subnet_cidr)
    error_message = "Internal firewall should allow traffic from public subnet"
  }

  assert {
    condition     = contains(google_compute_firewall.allow_internal.source_ranges, var.private_subnet_cidr)
    error_message = "Internal firewall should allow traffic from private subnet"
  }
}

run "validate_cloud_nat" {
  command = plan

  assert {
    condition     = var.enable_nat ? length(google_compute_router.router) == 1 : true
    error_message = "Cloud Router should be created when NAT is enabled"
  }

  assert {
    condition     = var.enable_nat ? length(google_compute_router_nat.nat) == 1 : true
    error_message = "Cloud NAT should be created when enabled"
  }

  assert {
    condition     = var.enable_nat ? google_compute_router_nat.nat[0].nat_ip_allocate_option == "AUTO_ONLY" : true
    error_message = "Cloud NAT should use AUTO_ONLY IP allocation"
  }

  assert {
    condition     = var.enable_nat ? google_compute_router_nat.nat[0].source_subnetwork_ip_ranges_to_nat == "ALL_SUBNETWORKS_ALL_IP_RANGES" : true
    error_message = "Cloud NAT should NAT all subnetworks"
  }
}

run "validate_public_instances" {
  command = plan

  assert {
    condition     = length(google_compute_instance.public) == var.instance_count
    error_message = "Should create correct number of public instances"
  }

  assert {
    condition     = google_compute_instance.public[0].machine_type == var.machine_type
    error_message = "Public instances should use specified machine type"
  }

  assert {
    condition     = google_compute_instance.public[0].zone == var.zone
    error_message = "Public instances should be in specified zone"
  }

  assert {
    condition     = contains(google_compute_instance.public[0].tags, "ssh-enabled")
    error_message = "Public instances should have ssh-enabled tag"
  }

  assert {
    condition     = contains(google_compute_instance.public[0].tags, "web-server")
    error_message = "Public instances should have web-server tag"
  }

  assert {
    condition     = length(google_compute_instance.public[0].network_interface[0].access_config) > 0
    error_message = "Public instances should have external IP (access_config)"
  }
}

run "validate_private_instances" {
  command = plan

  assert {
    condition     = length(google_compute_instance.private) == var.instance_count
    error_message = "Should create correct number of private instances"
  }

  assert {
    condition     = google_compute_instance.private[0].machine_type == var.machine_type
    error_message = "Private instances should use specified machine type"
  }

  assert {
    condition     = contains(google_compute_instance.private[0].tags, "ssh-enabled")
    error_message = "Private instances should have ssh-enabled tag"
  }

  assert {
    condition     = length(google_compute_instance.private[0].network_interface[0].access_config) == 0
    error_message = "Private instances should NOT have external IP"
  }

  # Note: Subnetwork validation removed as it's unknown during plan
  # Verify instance exists instead
  assert {
    condition     = length(google_compute_instance.private) == var.instance_count
    error_message = "Should create correct number of private instances"
  }
}

run "validate_instance_boot_disks" {
  command = plan

  assert {
    condition     = google_compute_instance.public[0].boot_disk[0].initialize_params[0].size == 20
    error_message = "Boot disk should be 20 GB"
  }

  assert {
    condition     = google_compute_instance.public[0].boot_disk[0].initialize_params[0].type == "pd-standard"
    error_message = "Boot disk should be standard persistent disk"
  }

  assert {
    condition     = google_compute_instance.public[0].boot_disk[0].initialize_params[0].image == data.google_compute_image.debian.self_link
    error_message = "Boot disk should use Debian image"
  }
}

run "validate_instance_labels" {
  command = plan

  assert {
    condition     = contains(keys(google_compute_instance.public[0].labels), "managed_by")
    error_message = "Public instances should have managed_by label"
  }

  assert {
    condition     = contains(keys(google_compute_instance.public[0].labels), "environment")
    error_message = "Public instances should have environment label"
  }

  assert {
    condition     = google_compute_instance.public[0].labels["tier"] == "public"
    error_message = "Public instances should have tier=public label"
  }

  assert {
    condition     = google_compute_instance.private[0].labels["tier"] == "private"
    error_message = "Private instances should have tier=private label"
  }
}

run "validate_startup_scripts" {
  command = plan

  assert {
    condition     = length(google_compute_instance.public[0].metadata_startup_script) > 0
    error_message = "Public instances should have startup script"
  }

  assert {
    condition     = length(google_compute_instance.private[0].metadata_startup_script) > 0
    error_message = "Private instances should have startup script"
  }
}

run "validate_outputs" {
  command = plan

  assert {
    condition     = output.vpc_name == google_compute_network.vpc.name
    error_message = "Output vpc_name should match created VPC"
  }

  assert {
    condition     = output.public_subnet_cidr == var.public_subnet_cidr
    error_message = "Output public_subnet_cidr should match variable"
  }

  assert {
    condition     = output.private_subnet_cidr == var.private_subnet_cidr
    error_message = "Output private_subnet_cidr should match variable"
  }

  assert {
    condition     = length(output.public_instance_names) == var.instance_count
    error_message = "Should output correct number of public instance names"
  }

  assert {
    condition     = length(output.private_instance_names) == var.instance_count
    error_message = "Should output correct number of private instance names"
  }

  assert {
    condition     = length(output.firewall_rules) == 4
    error_message = "Should have 4 firewall rules"
  }

  assert {
    condition     = output.nat_enabled == var.enable_nat
    error_message = "Output nat_enabled should match variable"
  }
}

run "validate_infrastructure_summary" {
  command = plan

  assert {
    condition     = output.infrastructure_summary.public_instances == var.instance_count
    error_message = "Summary should show correct number of public instances"
  }

  assert {
    condition     = output.infrastructure_summary.private_instances == var.instance_count
    error_message = "Summary should show correct number of private instances"
  }

  assert {
    condition     = output.infrastructure_summary.firewall_rules == 4
    error_message = "Summary should show 4 firewall rules"
  }

  assert {
    condition     = output.infrastructure_summary.nat_enabled == var.enable_nat
    error_message = "Summary should show NAT status"
  }
}
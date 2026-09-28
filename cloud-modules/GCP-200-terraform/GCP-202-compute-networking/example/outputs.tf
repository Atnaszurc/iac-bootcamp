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

# VPC Outputs
output "vpc_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "vpc_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

# Subnet Outputs
output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = google_compute_subnetwork.public.name
}

output "public_subnet_cidr" {
  description = "CIDR range of the public subnet"
  value       = google_compute_subnetwork.public.ip_cidr_range
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = google_compute_subnetwork.private.name
}

output "private_subnet_cidr" {
  description = "CIDR range of the private subnet"
  value       = google_compute_subnetwork.private.ip_cidr_range
}

# Firewall Outputs
output "firewall_rules" {
  description = "List of created firewall rules"
  value = [
    google_compute_firewall.allow_ssh.name,
    google_compute_firewall.allow_web.name,
    google_compute_firewall.allow_internal.name,
    google_compute_firewall.allow_health_checks.name
  ]
}

# Cloud NAT Outputs
output "nat_enabled" {
  description = "Whether Cloud NAT is enabled"
  value       = var.enable_nat
}

output "nat_name" {
  description = "Name of the Cloud NAT"
  value       = var.enable_nat ? google_compute_router_nat.nat[0].name : null
}

output "router_name" {
  description = "Name of the Cloud Router"
  value       = var.enable_nat ? google_compute_router.router[0].name : null
}

# Public Instance Outputs
output "public_instance_names" {
  description = "Names of public instances"
  value       = google_compute_instance.public[*].name
}

output "public_instance_internal_ips" {
  description = "Internal IP addresses of public instances"
  value       = google_compute_instance.public[*].network_interface[0].network_ip
}

output "public_instance_external_ips" {
  description = "External IP addresses of public instances"
  value       = google_compute_instance.public[*].network_interface[0].access_config[0].nat_ip
}

output "public_instance_self_links" {
  description = "Self links of public instances"
  value       = google_compute_instance.public[*].self_link
}

# Private Instance Outputs
output "private_instance_names" {
  description = "Names of private instances"
  value       = google_compute_instance.private[*].name
}

output "private_instance_internal_ips" {
  description = "Internal IP addresses of private instances"
  value       = google_compute_instance.private[*].network_interface[0].network_ip
}

output "private_instance_self_links" {
  description = "Self links of private instances"
  value       = google_compute_instance.private[*].self_link
}

# SSH Connection Strings
output "ssh_commands_public" {
  description = "SSH commands to connect to public instances"
  value = [
    for instance in google_compute_instance.public :
    "gcloud compute ssh ${instance.name} --zone=${var.zone}"
  ]
}

output "ssh_commands_private" {
  description = "SSH commands to connect to private instances (via IAP tunnel)"
  value = [
    for instance in google_compute_instance.private :
    "gcloud compute ssh ${instance.name} --zone=${var.zone} --tunnel-through-iap"
  ]
}

# Web URLs
output "web_urls" {
  description = "URLs to access web servers on public instances"
  value = [
    for ip in google_compute_instance.public[*].network_interface[0].access_config[0].nat_ip :
    "http://${ip}"
  ]
}

# Summary
output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    vpc_network       = google_compute_network.vpc.name
    public_subnet     = google_compute_subnetwork.public.name
    private_subnet    = google_compute_subnetwork.private.name
    public_instances  = length(google_compute_instance.public)
    private_instances = length(google_compute_instance.private)
    firewall_rules = length([
      google_compute_firewall.allow_ssh,
      google_compute_firewall.allow_web,
      google_compute_firewall.allow_internal,
      google_compute_firewall.allow_health_checks
    ])
    nat_enabled = var.enable_nat
  }
}
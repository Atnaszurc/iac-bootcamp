# TF-102 Section 5: for Expressions
# Demonstrates list/map comprehensions in Terraform

terraform {
  required_version = ">= 1.14"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

variable "servers" {
  type = list(object({
    name    = string
    role    = string
    enabled = bool
  }))
  default = [
    { name = "web-01",   role = "frontend", enabled = true  },
    { name = "web-02",   role = "frontend", enabled = false },
    { name = "api-01",   role = "backend",  enabled = true  },
    { name = "db-01",    role = "database", enabled = true  },
    { name = "cache-01", role = "cache",    enabled = false },
  ]
}

variable "base_tags" {
  type = map(string)
  default = {
    project     = "hashi-training"
    owner       = "platform-team"
    cost_center = "engineering"
  }
}

variable "environment" {
  type    = string
  default = "dev"
}

locals {
  # --- List transformations ---

  # All server names
  all_names = [for s in var.servers : s.name]

  # Only enabled server names (with filter)
  enabled_names = [for s in var.servers : s.name if s.enabled]

  # Uppercase all names
  upper_names = [for s in var.servers : upper(s.name)]

  # Formatted display strings
  display_strings = [for s in var.servers : "${s.name} (${s.role}) - ${s.enabled ? "active" : "disabled"}"]

  # --- Map transformations ---

  # Map of name => role (all servers)
  name_to_role = {for s in var.servers : s.name => s.role}

  # Map of name => role (enabled only)
  enabled_map = {for s in var.servers : s.name => s.role if s.enabled}

  # Map of name => full server object (enabled only)
  enabled_servers = {for s in var.servers : s.name => s if s.enabled}

  # --- Map iteration ---

  # Add environment prefix to all tag keys
  prefixed_tags = {for k, v in var.base_tags : "${var.environment}_${k}" => v}

  # Uppercase all tag values
  upper_tag_values = {for k, v in var.base_tags : k => upper(v)}

  # Create key=value strings from tags
  tag_strings = [for k, v in var.base_tags : "${k}=${v}"]
}

# Create a summary report using for expressions
resource "local_file" "server_report" {
  content  = <<-EOT
    Server Infrastructure Report
    ============================
    Environment: ${var.environment}
    
    All Servers (${length(local.all_names)}):
    ${join("\n", [for name in local.all_names : "  - ${name}"])}
    
    Enabled Servers (${length(local.enabled_names)}):
    ${join("\n", [for name in local.enabled_names : "  - ${name}"])}
    
    Role Assignments (enabled only):
    ${join("\n", [for name, role in local.enabled_map : "  ${name}: ${role}"])}
    
    Tags:
    ${join("\n", [for k, v in var.base_tags : "  ${k}: ${v}"])}
  EOT
  filename = "${path.module}/server-report.txt"
}

# Create individual config files for enabled servers using for_each
# Note: for expression produces the set, for_each creates the resources
resource "local_file" "server_configs" {
  for_each = local.enabled_servers

  content  = <<-EOT
    # Server Configuration: ${each.key}
    name    = "${each.value.name}"
    role    = "${each.value.role}"
    enabled = ${each.value.enabled}
    env     = "${var.environment}"
  EOT
  filename = "${path.module}/configs/${each.key}.conf"
}
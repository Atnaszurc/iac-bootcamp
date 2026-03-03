# TF-306 Section 2: Collection Functions — Working Examples
# Run: terraform init && terraform apply
# Or explore interactively: terraform console

terraform {
  required_version = ">= 1.14"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Variables
# ─────────────────────────────────────────────────────────────────────────────
variable "environments" {
  description = "Deployment environments"
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}

variable "regions" {
  description = "Deployment regions"
  type        = list(string)
  default     = ["eastus", "westeurope"]
}

variable "global_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    team       = "platform"
  }
}

variable "resource_tags" {
  description = "Resource-specific tags"
  type        = map(string)
  default = {
    component   = "web-server"
    environment = "production"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Locals: demonstrate each collection function
# ─────────────────────────────────────────────────────────────────────────────
locals {
  # ── flatten() ─────────────────────────────────────────────────────────────
  nested_lists = [["web-01", "web-02"], ["api-01"], ["db-01", "db-02"]]
  flat_servers = flatten(local.nested_lists)

  # flatten with for expression — all env-service combinations
  services = ["web", "api", "db"]
  all_combinations_list = flatten([
    for env in var.environments : [
      for svc in local.services : "${env}-${svc}"
    ]
  ])

  # ── merge() ───────────────────────────────────────────────────────────────
  # Resource-specific tags override global tags
  final_tags = merge(var.global_tags, var.resource_tags)

  # ── setproduct() ──────────────────────────────────────────────────────────
  # All environment × region combinations
  env_region_combos = setproduct(var.environments, var.regions)

  # Convert to map for for_each usage
  deployment_map = {
    for combo in local.env_region_combos :
    "${combo[0]}-${combo[1]}" => {
      environment = combo[0]
      region      = combo[1]
    }
  }

  # ── zipmap() ──────────────────────────────────────────────────────────────
  server_names = ["web-01", "api-01", "db-01"]
  ip_addresses = ["10.0.0.10", "10.0.0.20", "10.0.0.30"]
  server_ip_map = zipmap(local.server_names, local.ip_addresses)

  # ── distinct(), compact(), concat() ───────────────────────────────────────
  tags_with_dupes = ["web", "frontend", "web", "nginx", "frontend"]
  unique_tags     = distinct(local.tags_with_dupes)

  raw_list   = ["web", "", "api", "", "db"]
  clean_list = compact(local.raw_list)

  base_packages  = ["curl", "wget"]
  extra_packages = ["nginx", "git"]
  all_packages   = concat(local.base_packages, local.extra_packages)

  # ── keys(), values(), lookup() ────────────────────────────────────────────
  vm_sizes = {
    small  = "1cpu-1gb"
    medium = "2cpu-4gb"
    large  = "4cpu-8gb"
  }
  size_names    = keys(local.vm_sizes)
  size_values   = values(local.vm_sizes)
  default_size  = lookup(local.vm_sizes, "xlarge", "2cpu-4gb")
  selected_size = lookup(local.vm_sizes, "large", "2cpu-4gb")

  # ── element() with negative indices — NEW in Terraform 1.10 ───────────────
  # element(list, index) wraps around the list length.
  # Before 1.10: only non-negative indices were supported.
  # Since 1.10: negative indices count from the END of the list.
  #
  # element(-1) = last item
  # element(-2) = second-to-last item
  # element(-n) = nth item from the end
  #
  # Note: element() wraps around (modulo), unlike list[index] which errors
  # on out-of-bounds. Negative indices also wrap.

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Positive indices (traditional)
  first_az  = element(local.availability_zones, 0)   # "us-east-1a"
  second_az = element(local.availability_zones, 1)   # "us-east-1b"

  # Negative indices (Terraform 1.10+)
  last_az        = element(local.availability_zones, -1)  # "us-east-1c"
  second_last_az = element(local.availability_zones, -2)  # "us-east-1b"
  third_last_az  = element(local.availability_zones, -3)  # "us-east-1a"

  # Wrapping behavior — index wraps around list length
  # element(list, length(list)) == element(list, 0) == first item
  wrapped_az = element(local.availability_zones, 3)   # "us-east-1a" (wraps)
  wrapped_neg = element(local.availability_zones, -4) # "us-east-1c" (wraps back)

  # Real-world use case: distribute resources across AZs using modulo-like behavior
  # Assign each of N resources to an AZ, cycling through available zones
  resource_count = 5
  az_assignments = [
    for i in range(local.resource_count) :
    element(local.availability_zones, i)
    # i=0 → us-east-1a, i=1 → us-east-1b, i=2 → us-east-1c,
    # i=3 → us-east-1a (wraps), i=4 → us-east-1b (wraps)
  ]

  # Use negative index to get the "last" AZ for a special resource
  # (e.g., a management node always in the last AZ)
  management_az = element(local.availability_zones, -1)  # Always last AZ
}

# ─────────────────────────────────────────────────────────────────────────────
# Use setproduct result with for_each — create a config file per deployment
# ─────────────────────────────────────────────────────────────────────────────
resource "local_file" "deployment_config" {
  for_each = local.deployment_map
  filename = "${path.module}/deployments/${each.key}.conf"
  content  = <<-EOT
    # Deployment: ${each.key}
    environment = ${each.value.environment}
    region      = ${each.value.region}
  EOT
}

# ─────────────────────────────────────────────────────────────────────────────
# Output a summary of all collection function results
# ─────────────────────────────────────────────────────────────────────────────
resource "local_file" "collection_results" {
  filename = "${path.module}/results.txt"
  content  = <<-EOT
    # TF-306 Collection Functions Results

    ## flatten()
    flat_servers          = ${join(", ", local.flat_servers)}
    all_combinations_list = ${join(", ", local.all_combinations_list)}

    ## merge()
    final_tags = ${jsonencode(local.final_tags)}

    ## setproduct() → deployment_map keys
    deployments = ${join(", ", keys(local.deployment_map))}

    ## zipmap()
    server_ip_map = ${jsonencode(local.server_ip_map)}

    ## distinct()
    unique_tags = ${join(", ", local.unique_tags)}

    ## compact()
    clean_list = ${join(", ", local.clean_list)}

    ## concat()
    all_packages = ${join(", ", local.all_packages)}

    ## keys() and values()
    size_names   = ${join(", ", local.size_names)}
    size_values  = ${join(", ", local.size_values)}

    ## lookup()
    default_size  = ${local.default_size}
    selected_size = ${local.selected_size}

    ## element() with negative indices — NEW in Terraform 1.10
    first_az       = ${local.first_az}
    last_az        = ${local.last_az}
    second_last_az = ${local.second_last_az}
    wrapped_az     = ${local.wrapped_az}
    az_assignments = ${join(", ", local.az_assignments)}
    management_az  = ${local.management_az}
  EOT
}
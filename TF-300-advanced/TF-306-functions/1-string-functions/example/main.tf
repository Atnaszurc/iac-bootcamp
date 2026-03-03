# TF-306 Section 1: String Functions — Working Examples
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
variable "project" {
  description = "Project name"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "component" {
  description = "Component name (may contain spaces/special chars)"
  type        = string
  default     = "web server"
}

variable "servers" {
  description = "List of server roles"
  type        = list(string)
  default     = ["web", "api", "db"]
}

# ─────────────────────────────────────────────────────────────────────────────
# Locals: demonstrate each string function category
# ─────────────────────────────────────────────────────────────────────────────
locals {
  # ── format() ──────────────────────────────────────────────────────────────
  vm_name_formatted = format("vm-%s-%s", var.environment, var.component)
  padded_index      = format("%03d", 5)
  dns_name          = format("%s.%s.example.com", var.project, var.environment)

  # ── formatlist() ──────────────────────────────────────────────────────────
  server_hostnames = formatlist("%s.%s.example.com", var.servers, var.environment)

  # ── replace() ─────────────────────────────────────────────────────────────
  # Make component name DNS/resource-safe
  safe_component = lower(replace(var.component, "/[^a-z0-9]/", "-"))

  # ── split() and join() ────────────────────────────────────────────────────
  cidr       = "10.0.0.0/24"
  cidr_parts = split("/", local.cidr)
  network    = local.cidr_parts[0]
  prefix_len = local.cidr_parts[1]

  packages     = ["nginx", "curl", "wget", "git"]
  install_cmd  = "apt-get install -y ${join(" ", local.packages)}"
  package_csv  = join(", ", local.packages)

  # ── trim functions ────────────────────────────────────────────────────────
  env_raw    = "  production  "
  env_clean  = trim(local.env_raw, " ")
  no_prefix  = trimprefix("env-production", "env-")
  no_suffix  = trimsuffix("server.example.com.", ".")

  # ── case conversion ───────────────────────────────────────────────────────
  upper_env = upper(var.environment)
  lower_env = lower(var.environment)

  # ── regex() ───────────────────────────────────────────────────────────────
  version_string = "terraform-1.9.5-linux-amd64"
  version_number = regex("[0-9]+\\.[0-9]+\\.[0-9]+", local.version_string)

  # ── regexall() ────────────────────────────────────────────────────────────
  ip_text      = "server1=10.0.0.1 server2=10.0.0.2 server3=10.0.0.3"
  ip_addresses = regexall("[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+", local.ip_text)

  # ── substr() ──────────────────────────────────────────────────────────────
  long_name  = "my-very-long-resource-name-that-exceeds-limits"
  short_name = substr(local.long_name, 0, 20)

  # ── Combined: production-ready resource name ──────────────────────────────
  resource_name = substr(
    format("%s-%s-%s", var.project, var.environment, local.safe_component),
    0, 63
  )

  # ── templatestring() — NEW in Terraform 1.9 ───────────────────────────────
  # Renders a template from a STRING value (not a file path like templatefile).
  # The template content can come from a variable, data source, or local.
  #
  # Syntax: templatestring(template_string, variables_map)
  # Template syntax: same as templatefile — ${var} and %{ for } directives

  # Simple template from a local string
  greeting_template = "Hello, $${name}! You are deploying to $${environment}."
  greeting_rendered = templatestring(local.greeting_template, {
    name        = "Alice"
    environment = var.environment
  })

  # Multi-line template — useful for generating config files dynamically
  cloud_init_template = <<-TMPL
    #cloud-config
    hostname: $${hostname}
    fqdn: $${hostname}.$${domain}
    manage_etc_hosts: true
    packages:
$${packages_list}
  TMPL

  cloud_init_rendered = templatestring(local.cloud_init_template, {
    hostname      = format("%s-%s", var.project, var.environment)
    domain        = "example.internal"
    packages_list = join("\n", [for pkg in ["nginx", "curl", "git"] : "      - ${pkg}"])
  })

  # Real-world use case: template stored in a variable (e.g., from a data source)
  # In production, this template content might come from:
  #   - data "http" "template" { url = "https://config-server/templates/..." }
  #   - data "aws_s3_object" "template" { ... }
  #   - A variable passed from a parent module
  nginx_config_template = <<-TMPL
    server {
      listen 80;
      server_name $${server_name};
      root /var/www/$${project};

      location / {
        proxy_pass http://localhost:$${app_port};
      }
    }
  TMPL

  nginx_config = templatestring(local.nginx_config_template, {
    server_name = format("%s.example.com", var.project)
    project     = var.project
    app_port    = 3000
  })
}

# ─────────────────────────────────────────────────────────────────────────────
# Output the results to a file so you can see them without running apply
# ─────────────────────────────────────────────────────────────────────────────
resource "local_file" "string_function_results" {
  filename = "${path.module}/results.txt"
  content  = <<-EOT
    # TF-306 String Functions Results
    # Generated by Terraform

    ## format()
    vm_name_formatted = ${local.vm_name_formatted}
    padded_index      = ${local.padded_index}
    dns_name          = ${local.dns_name}

    ## formatlist()
    server_hostnames  = ${join(", ", local.server_hostnames)}

    ## replace()
    safe_component    = ${local.safe_component}

    ## split() and join()
    network           = ${local.network}
    prefix_len        = ${local.prefix_len}
    install_cmd       = ${local.install_cmd}
    package_csv       = ${local.package_csv}

    ## trim functions
    env_clean         = "${local.env_clean}"
    no_prefix         = ${local.no_prefix}
    no_suffix         = ${local.no_suffix}

    ## case conversion
    upper_env         = ${local.upper_env}
    lower_env         = ${local.lower_env}

    ## regex()
    version_number    = ${local.version_number}

    ## regexall()
    ip_addresses      = ${join(", ", local.ip_addresses)}

    ## substr()
    short_name        = ${local.short_name}

    ## Combined resource name
    resource_name     = ${local.resource_name}

    ## templatestring() — NEW in Terraform 1.9
    greeting_rendered = ${local.greeting_rendered}
    nginx_config      = (see nginx.conf output file)
  EOT
}

# Write the nginx config to its own file for clarity
resource "local_file" "nginx_config" {
  filename = "${path.module}/nginx.conf"
  content  = local.nginx_config
}

# Write the cloud-init config to its own file
resource "local_file" "cloud_init" {
  filename = "${path.module}/cloud-init.yaml"
  content  = local.cloud_init_rendered
}
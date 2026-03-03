# TF-306 Section 4: Encoding Functions Example
# Demonstrates: jsonencode(), jsondecode(), yamlencode(), yamldecode(),
#               base64encode(), base64decode(), tostring(), tonumber(), tobool()
#
# This example uses the local provider (no cloud credentials needed).
# Run: terraform init && terraform apply

terraform {
  required_version = ">= 1.14"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 3
}

variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = true
}

variable "s3_buckets" {
  description = "S3 bucket names for IAM policy generation"
  type        = list(string)
  default     = ["logs-bucket", "data-bucket", "backup-bucket"]
}

variable "vm_packages" {
  description = "Packages to install on VMs"
  type        = list(string)
  default     = ["nginx", "curl", "git", "htop"]
}

# ---------------------------------------------------------------------------
# Locals: demonstrate encoding functions
# ---------------------------------------------------------------------------

locals {

  # =========================================================================
  # jsonencode() — HCL → JSON string
  # =========================================================================

  # Simple map to JSON
  app_config_json = jsonencode({
    environment = var.environment
    replicas    = var.app_replicas
    monitoring  = var.enable_monitoring
    version     = "1.0.0"
  })

  # IAM-style policy with dynamic statements (for expression inside jsonencode)
  iam_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for bucket in var.s3_buckets : {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [
          "arn:aws:s3:::${bucket}",
          "arn:aws:s3:::${bucket}/*"
        ]
      }
    ]
  })

  # Nested structure
  deployment_spec_json = jsonencode({
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = "app-${var.environment}"
      namespace = "default"
      labels = {
        app         = "myapp"
        environment = var.environment
      }
    }
    spec = {
      replicas = var.app_replicas
      selector = {
        matchLabels = {
          app = "myapp"
        }
      }
    }
  })

  # =========================================================================
  # jsondecode() — JSON string → HCL
  # =========================================================================

  # Decode a JSON string back to a map
  decoded_config = jsondecode(local.app_config_json)

  # Access decoded values
  decoded_environment = local.decoded_config.environment
  decoded_replicas    = local.decoded_config.replicas

  # =========================================================================
  # yamlencode() — HCL → YAML string
  # =========================================================================

  # Cloud-init style config
  cloud_init_yaml = yamlencode({
    packages = var.vm_packages
    runcmd = [
      "systemctl enable nginx",
      "systemctl start nginx",
      "echo 'Setup complete' > /var/log/setup.log"
    ]
    write_files = [
      {
        path    = "/etc/app/config.json"
        content = local.app_config_json
      }
    ]
  })

  # Kubernetes-style config
  k8s_config_yaml = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "app-config"
      namespace = "default"
    }
    data = {
      environment = var.environment
      replicas    = tostring(var.app_replicas)
      monitoring  = tostring(var.enable_monitoring)
    }
  })

  # =========================================================================
  # yamldecode() — YAML string → HCL
  # =========================================================================

  # Decode a YAML string back to a map
  decoded_cloud_init = yamldecode(local.cloud_init_yaml)

  # Access decoded values
  decoded_packages = local.decoded_cloud_init.packages

  # =========================================================================
  # base64encode() / base64decode()
  # =========================================================================

  # Encode a startup script (common for VM user_data)
  startup_script = <<-SCRIPT
    #!/bin/bash
    set -e
    apt-get update -q
    apt-get install -y ${join(" ", var.vm_packages)}
    systemctl enable nginx
    systemctl start nginx
    echo "Environment: ${var.environment}" > /etc/app-environment
  SCRIPT

  startup_script_b64 = base64encode(local.startup_script)

  # Decode it back to verify round-trip
  startup_script_decoded = base64decode(local.startup_script_b64)

  # =========================================================================
  # Type conversion: tostring(), tonumber(), tobool()
  # =========================================================================

  # tostring() — convert number/bool to string
  replicas_as_string  = tostring(var.app_replicas)       # "3"
  monitoring_as_string = tostring(var.enable_monitoring) # "true"

  # tonumber() — convert string to number
  port_string = "8080"
  port_number = tonumber(local.port_string)  # 8080

  # tobool() — convert string to bool
  flag_string = "true"
  flag_bool   = tobool(local.flag_string)  # true

  # toset() — convert list to set (removes duplicates)
  packages_with_dupes = ["nginx", "curl", "nginx", "git", "curl"]
  unique_packages     = toset(local.packages_with_dupes)
  # → {"curl", "git", "nginx"}  (sorted, deduplicated)

  # tolist() — convert set/tuple to list
  packages_list = tolist(local.unique_packages)
}

# ---------------------------------------------------------------------------
# Write outputs to files
# ---------------------------------------------------------------------------

# JSON outputs
resource "local_file" "app_config_json" {
  filename = "${path.module}/output/app-config.json"
  content  = local.app_config_json
}

resource "local_file" "iam_policy_json" {
  filename = "${path.module}/output/iam-policy.json"
  content  = local.iam_policy_json
}

resource "local_file" "deployment_spec_json" {
  filename = "${path.module}/output/deployment-spec.json"
  content  = local.deployment_spec_json
}

# YAML outputs
resource "local_file" "cloud_init_yaml" {
  filename = "${path.module}/output/cloud-init.yaml"
  # Prepend the required cloud-init header
  content  = "#cloud-config\n${local.cloud_init_yaml}"
}

resource "local_file" "k8s_configmap_yaml" {
  filename = "${path.module}/output/k8s-configmap.yaml"
  content  = local.k8s_config_yaml
}

# Base64 output
resource "local_file" "startup_script_b64" {
  filename = "${path.module}/output/startup-script.b64"
  content  = local.startup_script_b64
}

# Summary
resource "local_file" "encoding_summary" {
  filename = "${path.module}/output/encoding-functions-summary.txt"
  content  = <<-EOT
    ============================================================
    TF-306 Section 4: Encoding Functions Summary
    ============================================================

    --- jsonencode() ---
    Converts HCL maps/lists to JSON strings.
    app_config_json (first 60 chars):
      ${substr(local.app_config_json, 0, 60)}...

    IAM policy generated for ${length(var.s3_buckets)} buckets:
      ${join(", ", var.s3_buckets)}

    --- jsondecode() ---
    Parses JSON strings back to HCL maps.
    Decoded environment: ${local.decoded_environment}
    Decoded replicas:    ${local.decoded_replicas}

    --- yamlencode() ---
    Converts HCL maps/lists to YAML strings.
    Cloud-init packages: ${join(", ", local.decoded_packages)}

    --- yamldecode() ---
    Parses YAML strings back to HCL maps.
    Decoded package count: ${length(local.decoded_packages)}

    --- base64encode() / base64decode() ---
    Original script length:  ${length(local.startup_script)} chars
    Base64 encoded length:   ${length(local.startup_script_b64)} chars
    Round-trip match:        ${local.startup_script == local.startup_script_decoded ? "YES ✓" : "NO ✗"}

    --- Type Conversions ---
    tostring(${var.app_replicas})       → "${local.replicas_as_string}"
    tostring(${var.enable_monitoring})  → "${local.monitoring_as_string}"
    tonumber("${local.port_string}")    → ${local.port_number}
    tobool("${local.flag_string}")      → ${local.flag_bool}

    --- toset() deduplication ---
    Input:  ${jsonencode(local.packages_with_dupes)}
    Output: ${jsonencode(tolist(local.unique_packages))}

    --- Output Files ---
    output/app-config.json       — jsonencode() result
    output/iam-policy.json       — dynamic IAM policy
    output/deployment-spec.json  — nested JSON structure
    output/cloud-init.yaml       — yamlencode() result
    output/k8s-configmap.yaml    — Kubernetes ConfigMap
    output/startup-script.b64    — base64encode() result

    ============================================================
    EOT
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "app_config_json" {
  description = "Application config as JSON"
  value       = local.app_config_json
}

output "cloud_init_yaml_preview" {
  description = "First 200 chars of cloud-init YAML"
  value       = substr(local.cloud_init_yaml, 0, 200)
}

output "base64_round_trip_success" {
  description = "Verify base64 encode/decode round-trip"
  value       = local.startup_script == local.startup_script_decoded
}

output "type_conversions" {
  description = "Type conversion examples"
  value = {
    replicas_as_string   = local.replicas_as_string
    monitoring_as_string = local.monitoring_as_string
    port_as_number       = local.port_number
    flag_as_bool         = local.flag_bool
  }
}

output "unique_packages" {
  description = "Deduplicated packages via toset()"
  value       = local.unique_packages
}

output "output_files" {
  description = "Generated output files"
  value = {
    app_config    = local_file.app_config_json.filename
    iam_policy    = local_file.iam_policy_json.filename
    deployment    = local_file.deployment_spec_json.filename
    cloud_init    = local_file.cloud_init_yaml.filename
    k8s_configmap = local_file.k8s_configmap_yaml.filename
    startup_b64   = local_file.startup_script_b64.filename
    summary       = local_file.encoding_summary.filename
  }
}
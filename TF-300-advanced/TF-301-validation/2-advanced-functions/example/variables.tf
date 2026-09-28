variable "base_name" {
  type    = string
  default = "My App"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "labels" {
  type = map(string)
  default = {
    Owner   = "devops-team"
    Project = "iac-bootcamp"
    Tier    = "web"
  }
}

variable "image_version" {
  description = "Ubuntu cloud image version, e.g. 20260915 or 20260915.1"
  type        = string
  default     = "20260915"

  validation {
    condition     = can(regex("^\\d{8}(\\.\\d+)?$", var.image_version))
    error_message = "image_version must look like 20260915 or 20260915.1."
  }
}

variable "max_image_age_days" {
  type    = number
  default = 90
}

variable "lab_cidr" {
  type    = string
  default = "10.140.0.0/22"
}

variable "tiers" {
  type    = list(string)
  default = ["web", "app", "db"]
}

variable "snapshot_retention" {
  description = "How long to keep VM snapshots, as a Go duration (e.g. 72h, 1h30m)"
  type        = string
  default     = "72h"

  validation {
    condition     = can(provider::time::duration_parse(var.snapshot_retention))
    error_message = "snapshot_retention must be a duration like 72h or 1h30m (units: h, m, s)."
  }
}

variable "snapshot_interval_hours" {
  type    = number
  default = 6
}

variable "service_name" {
  type    = string
  default = "Grafana"
}

variable "site" {
  type    = string
  default = "Home lab"
}

# TF-301 Section 2: Advanced functions & provider-defined functions
# No infrastructure: everything here is computed. Run:
#   terraform init
#   terraform apply        # random_string is the only "resource", it costs nothing
#   terraform output
#   terraform test

terraform {
  required_version = ">= 1.8" # provider-defined functions
  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13" # rfc3339_parse, duration_parse
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Task 1: Naming convention (function chaining)
# ─────────────────────────────────────────────────────────────────────────────

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  # Order matters: clean first, then truncate, then strip a trailing hyphen
  # the truncation may have created.
  raw_name   = "${var.base_name}-${var.environment}-${random_string.suffix.result}"
  clean_name = replace(lower(trimspace(local.raw_name)), "/[^a-z0-9-]+/", "-")
  vm_name    = trimsuffix(substr(local.clean_name, 0, 63), "-") # hostname limit
}

# ─────────────────────────────────────────────────────────────────────────────
# Task 2: Labels → VM description (libvirt has no tags; description is the
# closest thing and shows up in virsh and virt-manager)
# ─────────────────────────────────────────────────────────────────────────────

locals {
  label_pairs = [for k in sort(keys(var.labels)) : "${lower(k)}=${var.labels[k]}"]
  description = substr(join(";", local.label_pairs), 0, 255)
}

# ─────────────────────────────────────────────────────────────────────────────
# Task 3: Base image age (provider-defined function: time::rfc3339_parse)
# Ubuntu cloud image versions look like "20260915" or "20260915.1"
# ─────────────────────────────────────────────────────────────────────────────

locals {
  build_date = regex("^(\\d{4})(\\d{2})(\\d{2})", var.image_version)
  image_built = provider::time::rfc3339_parse(
    format("%s-%s-%sT00:00:00Z", local.build_date[0], local.build_date[1], local.build_date[2])
  )
  # plantimestamp() is fixed for the whole plan (unlike timestamp())
  now_unix       = provider::time::rfc3339_parse(plantimestamp()).unix
  image_age_days = floor((local.now_unix - local.image_built.unix) / 86400)
}

check "base_image_is_fresh" {
  assert {
    condition     = local.image_age_days <= var.max_image_age_days
    error_message = "Base image ${var.image_version} is ${local.image_age_days} days old (limit ${var.max_image_age_days}). Rebuild it with Packer (PKR-100)."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Task 4: One network per tier (cidrsubnets)
# ─────────────────────────────────────────────────────────────────────────────

locals {
  tier_cidrs = zipmap(var.tiers, cidrsubnets(var.lab_cidr, [for t in var.tiers : 2]...))
}

# ─────────────────────────────────────────────────────────────────────────────
# Task 5: Human-readable durations (provider-defined function: time::duration_parse)
# ─────────────────────────────────────────────────────────────────────────────

locals {
  snapshot_retention_hours = provider::time::duration_parse(var.snapshot_retention).hours
  snapshots_to_keep        = ceil(local.snapshot_retention_hours / var.snapshot_interval_hours)
}

# ─────────────────────────────────────────────────────────────────────────────
# Task 6: Name builder with a lookup table and error handling
# ─────────────────────────────────────────────────────────────────────────────

locals {
  site_codes = {
    "Stockholm lab" = "sto"
    "Home lab"      = "hom"
    "Classroom"     = "cls"
  }

  # lookup() with a default for unknown sites; try() for a service name
  # that would otherwise make regex() error
  site_code    = lookup(local.site_codes, var.site, "unk")
  service_slug = try(regex("^[a-z][a-z0-9]*", lower(var.service_name)), "svc")
  host_name = join("-", compact([
    local.service_slug,
    var.environment,
    local.site_code,
    random_string.suffix.result,
  ]))
}

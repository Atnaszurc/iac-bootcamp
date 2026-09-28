# TF-301 Section 7: Capturing Ephemeral Values with terraform_data (Terraform 1.16+)
#
# This example demonstrates:
# 1. Generating a password with an EPHEMERAL resource (never in state by itself)
# 2. Deliberately capturing it once with terraform_data's store block
# 3. Pinning the captured value with `version` — and rotating it by bumping it
# 4. Using the captured value in a regular (non-write-only) attribute
#
# Run with:
#   terraform init
#   terraform apply
#   terraform apply                          # no changes — the version pins it
#   terraform apply -var password_version=2  # rotate

terraform {
  required_version = ">= 1.16"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7" # ephemeral random_password
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# EPHEMERAL RESOURCE — produces a NEW password on every plan and apply.
# On its own it can only flow into ephemeral contexts (provisioners,
# write-only attributes, ephemeral outputs).
# ─────────────────────────────────────────────────────────────────────────────

ephemeral "random_password" "db" {
  length           = var.password_length
  override_special = "-_"
}

# ─────────────────────────────────────────────────────────────────────────────
# CAPTURE — terraform_data store block (Terraform 1.16+)
#
# input      write-only: accepts ephemeral values, is never stored itself
# sensitive  true → value lands in store.sensitive_output (else store.output)
# version    the captured value only changes when version changes; without it
#            the ephemeral password would change on EVERY apply
# ─────────────────────────────────────────────────────────────────────────────

resource "terraform_data" "db_password" {
  store {
    input     = ephemeral.random_password.db.result
    sensitive = true
    version   = var.password_version
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# CONSUMER — a regular attribute that cannot take an ephemeral value directly.
# Writing ephemeral.random_password.db.result here would be an error;
# the captured copy is a normal (sensitive) value.
# ─────────────────────────────────────────────────────────────────────────────

resource "local_sensitive_file" "db_credentials" {
  filename        = "${path.module}/out/db-credentials.env"
  file_permission = "0600"
  content         = <<-EOT
    DB_USER=${var.db_user}
    DB_PASSWORD=${terraform_data.db_password.store.sensitive_output}
  EOT
}

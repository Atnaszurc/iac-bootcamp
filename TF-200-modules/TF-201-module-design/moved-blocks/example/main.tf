# TF-201 Supplement: moved blocks example
# Demonstrates renaming resources without destroy/recreate
#
# HOW TO USE THIS EXAMPLE:
# Step 1: Comment out the "AFTER" section, uncomment "BEFORE", apply
# Step 2: Uncomment "AFTER" section + moved blocks, comment out "BEFORE", plan
# Step 3: Observe "has moved to" in plan output — no destroy/create
# Step 4: Apply to update state

terraform {
  required_version = ">= 1.14"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

# ============================================================
# BEFORE: Original resource names
# Uncomment this section for Step 1
# ============================================================

# resource "local_file" "web_server_config" {
#   content  = "server = web\nport = 80\nenvironment = ${var.environment}"
#   filename = "${path.module}/web.conf"
# }
#
# resource "local_file" "api_server_config" {
#   content  = "server = api\nport = 8080\nenvironment = ${var.environment}"
#   filename = "${path.module}/api.conf"
# }
#
# resource "local_file" "database_config" {
#   content  = "server = db\nport = 5432\nenvironment = ${var.environment}"
#   filename = "${path.module}/db.conf"
# }

# ============================================================
# AFTER: Renamed resources + moved blocks
# Uncomment this section for Step 2+
# ============================================================

resource "local_file" "web" {
  content  = "server = web\nport = 80\nenvironment = ${var.environment}"
  filename = "${path.module}/web.conf"
}

resource "local_file" "api" {
  content  = "server = api\nport = 8080\nenvironment = ${var.environment}"
  filename = "${path.module}/api.conf"
}

resource "local_file" "db" {
  content  = "server = db\nport = 5432\nenvironment = ${var.environment}"
  filename = "${path.module}/db.conf"
}

# moved blocks: tell Terraform about the renames
# These can be removed after all environments have applied
moved {
  from = local_file.web_server_config
  to   = local_file.web
}

moved {
  from = local_file.api_server_config
  to   = local_file.api
}

moved {
  from = local_file.database_config
  to   = local_file.db
}
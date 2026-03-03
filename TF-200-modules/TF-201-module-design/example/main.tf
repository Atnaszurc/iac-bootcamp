# TF-201: Module Design & Composition
# =====================================
# This example demonstrates the core Terraform module pattern:
#   - A reusable child module in modules/app-config/
#   - The root module calling that child module multiple times
#   - How inputs flow in and outputs flow out
#
# Key concepts:
#   - Module source paths (local: "./modules/app-config")
#   - Passing variables to modules
#   - Consuming module outputs
#   - Module reuse (same module, different inputs)

terraform {
  required_version = ">= 1.14"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

# ─────────────────────────────────────────────
# Module Instance 1: Development environment
# ─────────────────────────────────────────────
# The same module is called with dev-specific inputs.
# Notice: base_dir uses path.module so files land inside
# this example directory (not the system root).

module "app_dev" {
  source = "./modules/app-config"

  app_name    = var.app_name
  environment = "dev"
  port        = var.dev_port
  log_level   = "debug"
  debug_mode  = true
  base_dir    = "${path.module}/output"

  env_overrides = {
    DATABASE_URL = "postgres://localhost:5432/myapp_dev"
    CACHE_TTL    = "60"
    FEATURE_X    = "enabled"
  }

  tags = merge(var.common_tags, {
    Environment = "dev"
    CostCenter  = "engineering"
  })
}

# ─────────────────────────────────────────────
# Module Instance 2: Production environment
# ─────────────────────────────────────────────
# Same module, different inputs — this is the power of modules.
# Production gets a different port, log level, and overrides.

module "app_prod" {
  source = "./modules/app-config"

  app_name    = var.app_name
  environment = "prod"
  port        = var.prod_port
  log_level   = "warn"
  debug_mode  = false
  base_dir    = "${path.module}/output"

  env_overrides = {
    DATABASE_URL = "postgres://db.prod.internal:5432/myapp"
    CACHE_TTL    = "3600"
    FEATURE_X    = "disabled"
  }

  tags = merge(var.common_tags, {
    Environment = "prod"
    CostCenter  = "operations"
  })
}

# ─────────────────────────────────────────────
# Module Instance 3: Staging environment
# ─────────────────────────────────────────────
# A third instance shows how modules scale — add environments
# without duplicating any resource logic.

module "app_staging" {
  source = "./modules/app-config"

  app_name    = var.app_name
  environment = "staging"
  port        = var.staging_port
  log_level   = "info"
  debug_mode  = false
  base_dir    = "${path.module}/output"

  env_overrides = {
    DATABASE_URL = "postgres://db.staging.internal:5432/myapp_staging"
    CACHE_TTL    = "300"
    FEATURE_X    = "enabled"
  }

  tags = merge(var.common_tags, {
    Environment = "staging"
    CostCenter  = "engineering"
  })
}
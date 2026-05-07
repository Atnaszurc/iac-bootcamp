terraform {
  required_version = ">= 1.15.0"
}

# ============================================================================
# IMPORTANT: Terraform 1.15 Module Source Variables - Limitations
# ============================================================================
# Terraform 1.15 introduced support for variables in module sources, but with
# significant limitations:
#
# ✅ WORKS in terraform plan/apply:
#   - Variables in module sources
#   - Locals in module sources
#
# ❌ LIMITATION during terraform init:
#   - Variables must have values available during init
#   - Cannot use variables that require user input
#   - Locals with dynamic expressions don't work during init
#
# PRACTICAL IMPLICATION:
#   - Best used with -var flags or environment variables during init
#   - Or use literal paths and demonstrate the concept
#
# This example demonstrates the CONCEPT with static paths, as dynamic
# sources require special init-time handling.
# ============================================================================

# ============================================================================
# Example 1: Static Module Source (Traditional Approach)
# ============================================================================
# This is the traditional and most reliable approach

module "basic_config" {
  source = "./modules/versioned-config"

  app_name    = "basic-app"
  environment = var.environment
}

# ============================================================================
# Example 2: Environment-Specific Module Versions
# ============================================================================
# Note: Source is static, but version is dynamic based on environment

locals {
  # Version strategy per environment
  environment_versions = {
    dev     = "1.0.0" # Stable version for development
    staging = "1.1.0" # Latest features for staging
    prod    = "1.0.5" # Proven version for production
  }

  config_version = local.environment_versions[var.environment]
}

module "versioned_config" {
  source = "./modules/versioned-config"

  app_name    = "versioned-app"
  environment = var.environment
  version_tag = local.config_version
}

# ============================================================================
# Example 3: Conditional Configuration (Not Source)
# ============================================================================
# Instead of conditional sources, use conditional configuration

module "conditional_config" {
  source = "./modules/versioned-config"

  app_name    = "conditional-app"
  environment = var.environment
  # Pass conditional logic as configuration
  version_tag = var.use_local_development ? "dev-latest" : "1.0.0"
}

# ============================================================================
# Example 4: Centralized Version Management
# ============================================================================
# Use locals for version registry, but static source in module

locals {
  # Central registry of all module versions
  module_registry = {
    config = {
      source      = "./modules/versioned-config"
      version     = "1.0.0"
      description = "Application configuration module"
    }
    network = {
      source      = "./modules/network"
      version     = "2.0.0"
      description = "Network configuration module"
    }
  }
}

module "registry_config" {
  # Static source - locals used only for version
  source = "./modules/versioned-config"

  app_name    = "registry-app"
  environment = var.environment
  version_tag = local.module_registry.config.version
}

# ============================================================================
# Example 5: Multi-Environment Version Matrix
# ============================================================================

locals {
  # Version matrix: environment x module
  version_matrix = {
    dev = {
      config  = "1.0.0"
      network = "1.5.0"
    }
    staging = {
      config  = "1.1.0"
      network = "2.0.0"
    }
    prod = {
      config  = "1.0.5"
      network = "1.8.0"
    }
  }

  # Select versions for current environment
  current_versions = local.version_matrix[var.environment]
}

module "matrix_config" {
  source = "./modules/versioned-config"

  app_name    = "matrix-app"
  environment = var.environment
  version_tag = local.current_versions.config
}

# ============================================================================
# Example 6: Feature Flag with Dynamic Configuration
# ============================================================================
# Source is static, but configuration changes based on feature flag

locals {
  # Feature flag determines configuration
  feature_enabled = var.enable_advanced_features
}

module "feature_config" {
  source = "./modules/versioned-config"

  app_name    = "feature-app"
  environment = var.environment
  # Pass feature flag to module for internal logic
  version_tag = local.feature_enabled ? "2.0.0" : "1.0.0"
}

# ============================================================================
# Example 7: Version Override for Testing
# ============================================================================

locals {
  # Default versions
  default_versions = {
    config  = "1.0.0"
    network = "2.0.0"
  }

  # Merge defaults with overrides (for testing)
  final_versions = merge(
    local.default_versions,
    var.override_module_versions
  )
}

module "override_config" {
  source = "./modules/versioned-config"

  app_name    = "override-app"
  environment = var.environment
  version_tag = local.final_versions.config
}

# ============================================================================
# Example 8: Cloud Provider-Specific Configuration
# ============================================================================
# Use static source, pass cloud provider as configuration

module "cloud_config" {
  source = "./modules/versioned-config"

  app_name    = "cloud-app-${var.cloud_provider}"
  environment = var.environment
  version_tag = "1.0.0"
}

# ============================================================================
# Example 9: Canary Deployment with Module Versions
# ============================================================================

locals {
  # Use canary version if enabled
  canary_enabled = var.enable_canary_deployment

  canary_version = local.canary_enabled ? "1.2.0-beta" : "1.0.0"
}

module "canary_config" {
  source = "./modules/versioned-config"

  app_name    = "canary-app"
  environment = var.environment
  version_tag = local.canary_version
}

# ============================================================================
# Example 10: Tenant-Specific Configuration
# ============================================================================
# Use static source, pass tenant ID as configuration

locals {
  # Different module configurations per tenant
  tenant_module_config = {
    tenant_a = {
      version = "1.0.0"
    }
    tenant_b = {
      version = "1.1.0"
    }
    default = {
      version = "1.0.0"
    }
  }

  # Select tenant config or use default
  tenant_config = lookup(
    local.tenant_module_config,
    var.tenant_id,
    local.tenant_module_config.default
  )
}

module "tenant_config" {
  source = "./modules/versioned-config"

  app_name    = "tenant-app-${var.tenant_id}"
  environment = var.environment
  version_tag = local.tenant_config.version
}

# ============================================================================
# Example 11: CI/CD Pipeline Integration
# ============================================================================

locals {
  # Module version from CI/CD pipeline or default
  pipeline_version = var.ci_module_version != "" ? var.ci_module_version : "1.0.0"
}

module "pipeline_config" {
  source = "./modules/versioned-config"

  app_name    = "pipeline-app"
  environment = var.environment
  version_tag = local.pipeline_version
}
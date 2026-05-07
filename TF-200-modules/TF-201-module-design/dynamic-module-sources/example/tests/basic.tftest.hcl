variables {
  environment              = "dev"
  use_local_development    = true
  enable_advanced_features = false
  cloud_provider           = "aws"
  enable_canary_deployment = false
  tenant_id                = "default"
  ci_module_version        = ""
  ci_environment           = false
}

run "test_basic_config" {
  command = plan

  assert {
    condition     = module.basic_config.app_name == "basic-app"
    error_message = "Basic config app name should be 'basic-app'"
  }

  assert {
    condition     = module.basic_config.environment == "dev"
    error_message = "Basic config environment should be 'dev'"
  }
}

run "test_versioned_config" {
  command = plan

  assert {
    condition     = module.versioned_config.app_name == "versioned-app"
    error_message = "Versioned config app name should be 'versioned-app'"
  }

  assert {
    condition     = module.versioned_config.version == "1.0.0"
    error_message = "Versioned config should use dev version 1.0.0"
  }
}

run "test_environment_versions" {
  command = plan

  assert {
    condition     = output.environment_versions.dev == "1.0.0"
    error_message = "Dev environment should use version 1.0.0"
  }

  assert {
    condition     = output.environment_versions.staging == "1.1.0"
    error_message = "Staging environment should use version 1.1.0"
  }

  assert {
    condition     = output.environment_versions.prod == "1.0.5"
    error_message = "Prod environment should use version 1.0.5"
  }
}

run "test_version_matrix" {
  command = plan

  assert {
    condition     = output.version_matrix.dev.config == "1.0.0"
    error_message = "Dev config version should be 1.0.0"
  }

  assert {
    condition     = output.version_matrix.staging.config == "1.1.0"
    error_message = "Staging config version should be 1.1.0"
  }

  assert {
    condition     = output.version_matrix.prod.config == "1.0.5"
    error_message = "Prod config version should be 1.0.5"
  }
}

run "test_module_registry" {
  command = plan

  assert {
    condition     = output.module_registry.config.version == "1.0.0"
    error_message = "Config module version in registry should be 1.0.0"
  }

  assert {
    condition     = output.module_registry.network.version == "2.0.0"
    error_message = "Network module version in registry should be 2.0.0"
  }
}

run "test_conditional_config_local" {
  command = plan

  variables {
    use_local_development = true
  }

  assert {
    condition     = module.conditional_config.app_name == "conditional-app"
    error_message = "Conditional config should work with local modules"
  }
}

run "test_staging_environment" {
  command = plan

  variables {
    environment = "staging"
  }

  assert {
    condition     = module.versioned_config.environment == "staging"
    error_message = "Should use staging environment"
  }

  assert {
    condition     = module.versioned_config.version == "1.1.0"
    error_message = "Staging should use version 1.1.0"
  }
}

run "test_prod_environment" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = module.versioned_config.environment == "prod"
    error_message = "Should use prod environment"
  }

  assert {
    condition     = module.versioned_config.version == "1.0.5"
    error_message = "Prod should use version 1.0.5"
  }
}

run "test_canary_deployment_disabled" {
  command = plan

  variables {
    enable_canary_deployment = false
  }

  assert {
    condition     = module.canary_config.version == "1.0.0"
    error_message = "Should use stable version when canary is disabled"
  }
}

run "test_canary_deployment_enabled" {
  command = plan

  variables {
    enable_canary_deployment = true
  }

  assert {
    condition     = module.canary_config.version == "1.2.0-beta"
    error_message = "Should use beta version when canary is enabled"
  }
}

run "test_tenant_config" {
  command = plan

  variables {
    tenant_id = "tenant_a"
  }

  assert {
    condition     = module.tenant_config.app_name == "tenant-app-tenant_a"
    error_message = "Tenant config should include tenant ID in app name"
  }
}

run "test_ci_version_override" {
  command = plan

  variables {
    ci_module_version = "1.5.0"
    ci_environment    = true
  }

  assert {
    condition     = module.pipeline_config.version == "1.5.0"
    error_message = "Should use CI-provided version"
  }
}

run "test_version_override" {
  command = plan

  variables {
    override_module_versions = {
      config = "2.0.0"
    }
  }

  assert {
    condition     = module.override_config.version == "2.0.0"
    error_message = "Should use overridden version"
  }
}
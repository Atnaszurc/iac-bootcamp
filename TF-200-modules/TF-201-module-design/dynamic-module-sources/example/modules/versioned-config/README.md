# Versioned Configuration Module

A simple configuration module used to demonstrate dynamic module sources in Terraform 1.15+.

## Purpose

This module serves as a demonstration module for the dynamic module sources feature. It creates simple configuration resources that can be versioned and managed dynamically.

## Usage

```hcl
module "config" {
  source = "./modules/versioned-config"
  
  app_name    = "my-app"
  environment = "dev"
  version_tag = "1.0.0"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| app_name | Name of the application | string | n/a | yes |
| environment | Environment name (dev, staging, prod) | string | n/a | yes |
| version_tag | Version tag for the configuration | string | "1.0.0" | no |

## Outputs

| Name | Description |
|------|-------------|
| config_data | Configuration data object |
| config_json | Configuration as JSON string |
| app_name | Application name |
| environment | Environment name |
| version | Configuration version |

## Resources

- `terraform_data.config` - Configuration data resource
- `terraform_data.config_file` - Configuration file simulation

## Requirements

- Terraform >= 1.15.0
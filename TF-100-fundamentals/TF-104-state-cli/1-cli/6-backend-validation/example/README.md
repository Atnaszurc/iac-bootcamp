# Backend Validation Examples

This directory contains examples demonstrating the **backend validation** feature introduced in Terraform 1.15.

## Overview

Starting with Terraform 1.15, the `terraform validate` command now checks the `backend` block to ensure:
- The backend type exists
- All required attributes are present
- The backend's own validation logic passes

## Files in This Directory

### Valid Configuration
- **`1-valid-local-backend.tf`** - A valid local backend configuration that passes validation

### Invalid Configurations (`.example` files)
These files demonstrate various validation errors. To test them:
1. Rename the file from `.tf.example` to `.tf`
2. Run `terraform validate`
3. Observe the error message
4. Rename back to `.tf.example` when done

- **`2-invalid-backend-type.tf.example`** - Non-existent backend type
- **`3-missing-required-attribute.tf.example`** - Missing required `bucket` attribute for S3 backend
- **`4-invalid-attribute-value.tf.example`** - Invalid attribute value (empty `workspace_key_prefix`)

## Testing the Examples

### Test Valid Configuration
```bash
# Initialize and validate
terraform init
terraform validate

# Expected output:
# Success! The configuration is valid.
```

### Test Invalid Configurations

#### Example 1: Invalid Backend Type
```bash
# Rename the file
mv 2-invalid-backend-type.tf.example 2-invalid-backend-type.tf

# Run validation
terraform validate

# Expected error:
# Error: Invalid backend type
#   on 2-invalid-backend-type.tf line 9, in terraform:
#    9:   backend "nonexistent" {
# Backend type "nonexistent" is not supported.

# Rename back
mv 2-invalid-backend-type.tf 2-invalid-backend-type.tf.example
```

#### Example 2: Missing Required Attribute
```bash
# Rename the file
mv 3-missing-required-attribute.tf.example 3-missing-required-attribute.tf

# Run validation
terraform validate

# Expected error:
# Error: Missing required argument
#   on 3-missing-required-attribute.tf line 9, in terraform:
#    9:   backend "s3" {
# The argument "bucket" is required, but no definition was found.

# Rename back
mv 3-missing-required-attribute.tf 3-missing-required-attribute.tf.example
```

#### Example 3: Invalid Attribute Value
```bash
# Rename the file
mv 4-invalid-attribute-value.tf.example 4-invalid-attribute-value.tf

# Run validation
terraform validate

# Expected error:
# Error: Invalid backend configuration
#   on 4-invalid-attribute-value.tf line 14, in terraform:
#   14:     workspace_key_prefix = ""
# workspace_key_prefix cannot be an empty string

# Rename back
mv 4-invalid-attribute-value.tf 4-invalid-attribute-value.tf.example
```

## Key Learning Points

1. **Early Error Detection**: Backend validation catches configuration errors before `terraform init`, saving time in CI/CD pipelines

2. **Required Attributes**: Each backend type has specific required attributes that must be present

3. **Validation Logic**: Backends can implement custom validation rules (e.g., non-empty strings, valid regions)

4. **CI/CD Integration**: Use `terraform validate` in CI pipelines to catch backend configuration errors early

## Common Backend Types and Required Attributes

### Local Backend
```hcl
backend "local" {
  path = "terraform.tfstate"  # Optional, defaults to terraform.tfstate
}
```

### S3 Backend
```hcl
backend "s3" {
  bucket = "my-terraform-state"  # Required
  key    = "path/to/state"       # Required
  region = "us-east-1"           # Required
}
```

### Azure Backend
```hcl
backend "azurerm" {
  resource_group_name  = "my-rg"        # Required
  storage_account_name = "mystorageacct" # Required
  container_name       = "tfstate"       # Required
  key                  = "terraform.tfstate" # Required
}
```

### GCS Backend
```hcl
backend "gcs" {
  bucket = "my-terraform-state"  # Required
  prefix = "terraform/state"     # Optional
}
```

## Best Practices

1. **Always Run Validate**: Include `terraform validate` in your CI/CD pipeline before `terraform init`

2. **Test Backend Changes**: When modifying backend configuration, run validation to catch errors early

3. **Document Requirements**: Keep track of required attributes for your chosen backend type

4. **Use Version Constraints**: Specify `required_version = ">= 1.15.0"` to ensure backend validation is available

5. **Validate Before Init**: The validation happens without requiring backend initialization, making it faster

## Troubleshooting

### Error: Backend type not supported
- Check for typos in the backend type name
- Ensure you're using a valid backend type (local, s3, azurerm, gcs, etc.)

### Error: Missing required argument
- Review the backend documentation for required attributes
- Ensure all required attributes are present in your configuration

### Error: Invalid backend configuration
- Check attribute values meet the backend's validation rules
- Review error messages for specific validation failures

## Additional Resources

- [Terraform Backend Configuration](https://www.terraform.io/language/settings/backends/configuration)
- [Backend Types](https://www.terraform.io/language/settings/backends)
- [Terraform Validate Command](https://www.terraform.io/cli/commands/validate)
- [Terraform 1.15 Release Notes](https://github.com/hashicorp/terraform/releases/tag/v1.15.0)

## Next Steps

After completing this section:
1. Review the main [TF-104 README](../../README.md) for more CLI topics
2. Practice with different backend types
3. Integrate backend validation into your CI/CD workflows
4. Explore other Terraform 1.15 features in the training
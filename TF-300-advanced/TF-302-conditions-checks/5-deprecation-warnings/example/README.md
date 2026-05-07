# Deprecation Detection Examples

This directory contains examples demonstrating **enhanced deprecation detection** in Terraform 1.15.

## Overview

Terraform 1.15 improves how deprecation warnings are detected and reported, including provider-specific deprecation messages in the warnings.

## Files in This Directory

- **`main.tf`** - Example configuration demonstrating deprecation detection concepts
- **`tests/basic.tftest.hcl`** - Test file to verify the examples work correctly

## What Gets Created

When you run this example, it creates three documentation files:

1. **`deprecation-detection-demo.txt`** - Overview of deprecation detection in Terraform 1.15
2. **`common-deprecation-patterns.txt`** - Common patterns of deprecations across providers
3. **`migration-checklist.txt`** - Step-by-step checklist for handling deprecations

## Running the Example

### Step 1: Initialize Terraform

```bash
terraform init
```

### Step 2: Review the Plan

```bash
terraform plan
```

This example uses the local provider which doesn't have deprecated features, but demonstrates the workflow and documentation patterns.

### Step 3: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

### Step 4: Review the Created Files

```bash
# View the deprecation detection demo
cat deprecation-detection-demo.txt

# View common patterns
cat common-deprecation-patterns.txt

# View the migration checklist
cat migration-checklist.txt
```

### Step 5: Run Tests

```bash
terraform test
```

Expected output:
```
tests/basic.tftest.hcl... in progress
  run "verify_documentation_files_created"... pass
  run "verify_output_structure"... pass
  run "verify_file_content"... pass
tests/basic.tftest.hcl... tearing down
tests/basic.tftest.hcl... pass
```

### Step 6: Clean Up

```bash
terraform destroy
```

Type `yes` when prompted.

## Understanding Deprecation Warnings

### What You'll See in Real Cloud Providers

When using cloud providers (AWS, Azure, GCP), you might see warnings like:

```
Warning: Argument is deprecated

  on main.tf line 15, in resource "aws_security_group" "example":
  15:   ingress {

Inline ingress and egress rules are deprecated. Use separate 
aws_security_group_rule resources instead. Inline rules will be removed 
in version 6.0.0 of the AWS provider.
```

### Key Components of Deprecation Warnings

1. **Warning Type**: "Argument is deprecated" or "Block is deprecated"
2. **Location**: File name and line number
3. **Context**: Which resource contains the deprecated feature
4. **Provider Message**: Specific guidance from the provider (NEW in 1.15)
5. **Timeline**: When the feature will be removed

## Real-World Example: AWS Security Group Migration

### Before (Deprecated)

```hcl
resource "aws_security_group" "example" {
  name = "example-sg"
  
  # ⚠️ DEPRECATED: Inline rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### After (Recommended)

```hcl
resource "aws_security_group" "example" {
  name = "example-sg"
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}
```

## Best Practices

1. **Run `terraform plan` regularly** to catch deprecations early
2. **Address deprecations promptly** during the transition period
3. **Test migrations** in non-production environments first
4. **Document changes** for your team
5. **Monitor provider changelogs** for upcoming deprecations

## Common Deprecation Scenarios

### Scenario 1: Attribute Replacement
An attribute is replaced by a better alternative.

### Scenario 2: Block Replacement
An entire block type is being phased out.

### Scenario 3: Resource Type Replacement
A resource type is replaced by a new one.

### Scenario 4: Inline to Separate Resources
Inline configurations moved to separate resources.

### Scenario 5: Argument Value Deprecation
Specific values for an argument are deprecated.

## Migration Workflow

1. **Identify**: Run `terraform plan` to see all deprecations
2. **Research**: Read provider documentation for alternatives
3. **Plan**: Create a migration strategy
4. **Test**: Implement changes in a test environment
5. **Verify**: Confirm no deprecation warnings remain
6. **Deploy**: Roll out to production

## Additional Resources

- [Terraform 1.15 Release Notes](https://github.com/hashicorp/terraform/releases/tag/v1.15.0)
- [Provider Deprecation Guidelines](https://developer.hashicorp.com/terraform/plugin/best-practices/deprecations)
- [AWS Provider Changelog](https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md)
- [Azure Provider Changelog](https://github.com/hashicorp/terraform-provider-azurerm/blob/main/CHANGELOG.md)
- [Google Provider Changelog](https://github.com/hashicorp/terraform-provider-google/blob/main/CHANGELOG.md)

## Key Takeaways

1. **Terraform 1.15** improves deprecation detection and reporting
2. **Provider messages** are now included in warnings (major improvement)
3. **Deprecation warnings** help prevent future breaking changes
4. **Address deprecations proactively** to maintain healthy infrastructure code
5. **Test migrations thoroughly** before deploying to production

## Next Steps

After completing this example:
1. Review the main [Section 5 README](../README.md) for comprehensive theory
2. Practice identifying deprecations in your own configurations
3. Set up automated deprecation detection in CI/CD
4. Continue to the next section of TF-302

---

**Remember**: Deprecation warnings are helpful indicators that guide you toward better, more maintainable infrastructure code. Embrace them as opportunities to improve!
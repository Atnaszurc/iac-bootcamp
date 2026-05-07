# Enhanced Deprecation Detection Examples
# Terraform 1.15+
#
# This file demonstrates how Terraform 1.15 detects and reports deprecations
# with enhanced provider messages.

terraform {
  required_version = ">= 1.15.0"
  
  required_providers {
    # Using local provider for demonstration
    # In real scenarios, cloud providers (AWS, Azure, GCP) would show deprecation warnings
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Example 1: Conceptual demonstration of deprecation detection
# Note: The local provider doesn't have deprecated attributes, but this shows the pattern

# In a real cloud provider scenario, you might see:
# resource "aws_security_group" "example" {
#   name = "example-sg"
#   
#   # ⚠️ DEPRECATED: Inline rules are deprecated
#   # Warning: Argument is deprecated
#   #   on main.tf line X, in resource "aws_security_group" "example":
#   # Inline ingress and egress rules are deprecated. Use separate 
#   # aws_security_group_rule resources instead.
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# Example 2: Demonstration with local provider
# This creates files to show the workflow, even though local provider has no deprecations

resource "local_file" "deprecation_example" {
  filename = "${path.module}/deprecation-detection-demo.txt"
  content  = <<-EOT
    # Deprecation Detection in Terraform 1.15+
    
    ## What's New
    
    1. **Improved Detection**: Better identification of deprecated attributes and blocks
    2. **Provider Messages**: Deprecation messages from providers are now included
    3. **Clearer Warnings**: More informative warnings with migration guidance
    
    ## Example Warning Format (from cloud providers)
    
    Warning: Argument is deprecated
    
      on main.tf line 15, in resource "aws_instance" "example":
      15:   associate_public_ip_address = true
    
    The attribute "associate_public_ip_address" is deprecated. 
    Use "network_interface" block with "associate_public_ip_address" instead.
    This attribute will be removed in version 6.0.0 of the AWS provider.
    
    ## Benefits
    
    - Early warning about upcoming breaking changes
    - Clear migration paths provided by providers
    - Time to plan and execute migrations
    - Avoid surprises during provider upgrades
    
    ## Best Practices
    
    1. Run 'terraform plan' regularly to catch deprecations
    2. Address deprecations during the transition period
    3. Test migrations in non-production environments
    4. Document migrations for team knowledge
    5. Monitor provider changelogs for upcoming deprecations
  EOT
}

# Example 3: Documentation file showing common deprecation patterns
resource "local_file" "common_patterns" {
  filename = "${path.module}/common-deprecation-patterns.txt"
  content  = <<-EOT
    # Common Deprecation Patterns Across Providers
    
    ## Pattern 1: Attribute Replacement
    
    OLD (Deprecated):
      resource "provider_resource" "example" {
        old_attribute = "value"
      }
    
    NEW (Recommended):
      resource "provider_resource" "example" {
        new_attribute = "value"
      }
    
    ## Pattern 2: Block Replacement
    
    OLD (Deprecated):
      resource "provider_resource" "example" {
        deprecated_block {
          setting = "value"
        }
      }
    
    NEW (Recommended):
      resource "provider_resource" "example" {
        new_block {
          setting = "value"
        }
      }
    
    ## Pattern 3: Resource Type Replacement
    
    OLD (Deprecated):
      resource "provider_old_resource" "example" {
        name = "example"
      }
    
    NEW (Recommended):
      resource "provider_new_resource" "example" {
        name = "example"
      }
    
    ## Pattern 4: Inline to Separate Resources
    
    OLD (Deprecated):
      resource "provider_resource" "example" {
        name = "example"
        
        inline_rule {
          setting = "value"
        }
      }
    
    NEW (Recommended):
      resource "provider_resource" "example" {
        name = "example"
      }
      
      resource "provider_rule" "example" {
        parent_id = provider_resource.example.id
        setting   = "value"
      }
    
    ## Pattern 5: Argument Value Deprecation
    
    OLD (Deprecated):
      resource "provider_resource" "example" {
        version = "1.0"  # Major.minor format deprecated
      }
    
    NEW (Recommended):
      resource "provider_resource" "example" {
        version = "1.0.5"  # Full semantic version required
      }
  EOT
}

# Example 4: Migration checklist
resource "local_file" "migration_checklist" {
  filename = "${path.module}/migration-checklist.txt"
  content  = <<-EOT
    # Deprecation Migration Checklist
    
    ## Phase 1: Discovery
    [ ] Run 'terraform plan' to identify all deprecations
    [ ] Document each deprecation warning
    [ ] Note the provider message and migration guidance
    [ ] Identify the timeline for removal
    [ ] Assess the impact on your infrastructure
    
    ## Phase 2: Planning
    [ ] Prioritize deprecations by removal timeline
    [ ] Research the recommended alternatives
    [ ] Estimate effort for each migration
    [ ] Create a migration schedule
    [ ] Identify dependencies between migrations
    [ ] Plan testing strategy
    
    ## Phase 3: Implementation
    [ ] Set up a test environment
    [ ] Migrate one resource at a time
    [ ] Run 'terraform plan' after each change
    [ ] Verify no unexpected changes
    [ ] Test functionality after migration
    [ ] Document the changes made
    
    ## Phase 4: Validation
    [ ] Run 'terraform plan' - confirm no deprecation warnings
    [ ] Verify all resources function correctly
    [ ] Check for any side effects
    [ ] Update documentation
    [ ] Communicate changes to team
    
    ## Phase 5: Deployment
    [ ] Deploy to development environment
    [ ] Monitor for issues
    [ ] Deploy to staging environment
    [ ] Perform thorough testing
    [ ] Deploy to production environment
    [ ] Monitor production closely
    
    ## Phase 6: Cleanup
    [ ] Remove old code comments
    [ ] Update team documentation
    [ ] Share lessons learned
    [ ] Update CI/CD pipelines if needed
    [ ] Archive migration notes for future reference
  EOT
}

# Output the file locations
output "example_files" {
  description = "Locations of the deprecation detection example files"
  value = {
    demo_file      = local_file.deprecation_example.filename
    patterns_file  = local_file.common_patterns.filename
    checklist_file = local_file.migration_checklist.filename
  }
}

output "key_points" {
  description = "Key points about deprecation detection in Terraform 1.15"
  value = {
    improvement_1 = "Better detection of deprecated resource attributes and blocks"
    improvement_2 = "Provider deprecation messages now included in warnings"
    improvement_3 = "Clearer warnings with migration guidance"
    benefit_1     = "Proactive identification of deprecated features"
    benefit_2     = "Understanding of why features are deprecated"
    benefit_3     = "Guidance on migration paths"
    benefit_4     = "Avoiding breaking changes in future updates"
  }
}
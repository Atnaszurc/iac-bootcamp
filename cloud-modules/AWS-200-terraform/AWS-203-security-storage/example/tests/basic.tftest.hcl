# Tests for AWS-203: Security & Storage
# Uses mock_provider to test configuration without real AWS credentials.
# Validates S3 bucket, IAM role, and EBS volume configuration.

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/terraform-test"
      user_id    = "AIDAEXAMPLEUSERID"
    }
  }

  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
      state = "available"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

# ---------------------------------------------------------------
# Test 1: Default variables produce a valid plan
# ---------------------------------------------------------------
run "default_variables" {
  command = plan

  assert {
    condition     = aws_s3_bucket.main.bucket == "aws203-dev-123456789012"
    error_message = "S3 bucket name should combine project_name, environment, and account_id"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.main.block_public_acls == true
    error_message = "S3 bucket should block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.main.block_public_policy == true
    error_message = "S3 bucket should block public policies"
  }
}

# ---------------------------------------------------------------
# Test 2: S3 bucket versioning is enabled
# ---------------------------------------------------------------
run "s3_versioning_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.main.versioning_configuration[0].status == "Enabled"
    error_message = "S3 bucket versioning should be enabled"
  }
}

# ---------------------------------------------------------------
# Test 3: S3 encryption is configured
# ---------------------------------------------------------------
run "s3_encryption_configured" {
  command = plan

  assert {
    condition     = one([for r in aws_s3_bucket_server_side_encryption_configuration.main.rule : r.apply_server_side_encryption_by_default[0].sse_algorithm]) == "AES256"
    error_message = "S3 bucket should use AES256 server-side encryption"
  }
}

# ---------------------------------------------------------------
# Test 4: IAM role is configured for EC2
# ---------------------------------------------------------------
run "iam_role_for_ec2" {
  command = plan

  assert {
    condition     = aws_iam_role.ec2_s3_role.name == "aws203-ec2-s3-role"
    error_message = "IAM role name should use project_name prefix"
  }

  assert {
    condition     = aws_iam_instance_profile.ec2_profile.name == "aws203-ec2-profile"
    error_message = "IAM instance profile name should use project_name prefix"
  }
}

# ---------------------------------------------------------------
# Test 5: EBS volume is encrypted with correct size
# ---------------------------------------------------------------
run "ebs_volume_encrypted" {
  command = plan

  assert {
    condition     = aws_ebs_volume.data.encrypted == true
    error_message = "EBS volume should be encrypted"
  }

  assert {
    condition     = aws_ebs_volume.data.size == 20
    error_message = "EBS volume size should be 20 GB by default"
  }

  assert {
    condition     = aws_ebs_volume.data.type == "gp3"
    error_message = "EBS volume type should be gp3"
  }
}

# ---------------------------------------------------------------
# Test 6: Custom EBS size
# ---------------------------------------------------------------
run "custom_ebs_size" {
  command = plan

  variables {
    ebs_size_gb = 50
  }

  assert {
    condition     = aws_ebs_volume.data.size == 50
    error_message = "EBS volume size should reflect the custom variable"
  }
}
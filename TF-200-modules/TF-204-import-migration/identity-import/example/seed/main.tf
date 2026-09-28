# TF-204: create "existing" infrastructure to import
#
# Plays the colleague who built things by hand: a bucket, two IAM roles, a
# policy and a policy attachment in Moto. Delete this configuration's state afterwards, so
# no Terraform configuration manages them any more.
#
#   terraform init
#   terraform apply
#   rm terraform.tfstate*     # the resources still exist in Moto

locals {
  assume_ec2 = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_s3_bucket" "data" {
  bucket = "legacy-data-prod"
}

resource "aws_iam_role" "roles" {
  for_each = toset(["legacy-deployer", "legacy-readonly"])

  name               = each.key
  assume_role_policy = local.assume_ec2
}

resource "aws_iam_policy" "read_logs" {
  name = "legacy-read-logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:GetLogEvents", "logs:DescribeLogStreams"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "read_logs" {
  role       = aws_iam_role.roles["legacy-readonly"].name
  policy_arn = aws_iam_policy.read_logs.arn
}

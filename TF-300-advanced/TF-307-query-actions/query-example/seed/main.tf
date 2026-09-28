# TF-307: create "unmanaged" resources to discover
#
# Plays the colleague who clicked resources together by hand: it creates
# three EC2 instances and a bucket in Moto, and then you delete this
# configuration's state so Terraform no longer knows about them.
#
#   terraform init
#   terraform apply
#   rm terraform.tfstate*     # the resources still exist in Moto

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2 = "http://localhost:5000"
    s3  = "http://localhost:5000"
    sts = "http://localhost:5000"
  }
}

# Moto ships a set of fake AMIs; pick any of them
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon", "099720109477"]
}

resource "aws_instance" "web" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  tags = {
    Name        = "web-${count.index}"
    Environment = "prod"
  }
}

resource "aws_instance" "sandbox" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  tags = {
    Name        = "sandbox"
    Environment = "dev"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "legacy-logs"
}

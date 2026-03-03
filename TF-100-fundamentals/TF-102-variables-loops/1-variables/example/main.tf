terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

provider "local" {}

resource "local_file" "example1" {
  content  = "Hello, Terraform!"
  filename = "${path.module}/hello.txt"
}

resource "local_file" "example2" {
  content  = "This is another file created by Terraform."
  filename = "${path.module}/another_file.txt"
}
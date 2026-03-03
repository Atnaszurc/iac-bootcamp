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
  content  = var.file1_content
  filename = "${path.module}/${var.file1_name}"
}

resource "local_file" "example2" {
  content  = var.file2_content
  filename = "${path.module}/${var.file2_name}"
}

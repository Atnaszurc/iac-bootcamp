terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

provider "local" {}

# Using count
resource "local_file" "example_count" {
  count    = length(var.file_contents)
  content  = var.file_contents[count.index]
  filename = "${path.module}/count_file_${count.index + 1}.txt"
}

# Using for_each
resource "local_file" "example_for_each" {
  for_each = var.file_names
  content  = each.value
  filename = "${path.module}/${each.key}"
}

# Using for_each with a set
resource "local_file" "example_for_each_set" {
  for_each = toset(["apple", "banana", "cherry"])
  content  = "I like ${each.key}"
  filename = "${path.module}/fruit_${each.key}.txt"
}
terraform {
required_providers {
local = {
source  = "hashicorp/local"
version = "~> 2.7"
}
}
}

provider "local" {}

resource "local_file" "example_map" {
for_each = var.file_contents
content  = each.value
filename = "${path.module}/${var.environment}_${each.key}"
}

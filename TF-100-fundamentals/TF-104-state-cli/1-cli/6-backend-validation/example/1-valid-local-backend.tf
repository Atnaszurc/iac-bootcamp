terraform {
  required_version = ">= 1.15.0"

  # A valid backend configuration: state in a local file
  backend "local" {
    path = "terraform.tfstate"
  }
}

resource "terraform_data" "example" {
  input = {
    message = "Backend validation example"
  }
}

output "message" {
  value = terraform_data.example.input.message
}

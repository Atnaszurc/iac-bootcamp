terraform {
  required_version = ">= 1.15.0"

  # Valid local backend configuration
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Simple resource for testing
resource "terraform_data" "example" {
  input = {
    message = "Backend validation example"
  }
}

output "message" {
  value = terraform_data.example.input.message
}
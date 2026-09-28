# TF-305 Section 2: a configuration with its state in S3
#
# Start WITHOUT a backend block (local state), apply, then add backend.tf
# and migrate — see the README. The backend block only holds what is the
# same everywhere; environment-specific settings come from a
# *.s3.tfbackend file passed at init:
#
#   terraform init -backend-config=moto.s3.tfbackend

resource "terraform_data" "app" {
  input = var.app_version

  # Provisioners only run when a resource is created, so replace the
  # resource on every version change...
  triggers_replace = var.app_version

  # ...and make that slow on purpose, so you have time to start a second
  # apply and see the state lock in action
  provisioner "local-exec" {
    command = "sleep ${var.apply_seconds}"
  }
}

variable "app_version" {
  type    = string
  default = "1.0.0"
}

variable "apply_seconds" {
  description = "How long the provisioner keeps the apply (and the lock) busy"
  type        = number
  default     = 20
}

output "workspace" {
  value = terraform.workspace
}

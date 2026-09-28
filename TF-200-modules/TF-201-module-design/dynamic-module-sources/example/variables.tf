# const = true lets a variable be used while Terraform loads the
# configuration (terraform init), so it can appear in a module's source or
# version. Its value must be known then: a default, -var, TF_VAR_ or a
# .tfvars file, never something computed during plan.

variable "environment" {
  description = "dev or prod: picks the network module version"
  type        = string
  default     = "dev"
  const       = true

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "template_module_version" {
  description = "Version of the hashicorp/dir/template registry module"
  type        = string
  default     = "1.0.2"
  const       = true
}

# An ordinary variable: used at plan time, can't appear in source or version
variable "network_cidr" {
  description = "Address range for the lab network"
  type        = string
  default     = "10.30.0.0/16"
}

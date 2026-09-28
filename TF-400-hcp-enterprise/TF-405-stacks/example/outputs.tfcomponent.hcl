# Stack outputs are shown in HCP Terraform for every deployment.
# Unlike root module outputs, they need a type.

output "prefix" {
  type        = string
  description = "The name prefix of this deployment"
  value       = component.naming.prefix
}

output "instances" {
  type        = list(string)
  description = "The app instances this deployment describes"
  value       = component.app.instance_names
}

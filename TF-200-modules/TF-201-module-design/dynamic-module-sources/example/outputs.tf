output "network_module_version" {
  description = "Which version of the network module this environment uses"
  value       = module.network.module_version
}

output "subnets" {
  description = "Subnets planned by the network module"
  value       = module.network.subnets
}

output "motd" {
  description = "The login message rendered by the registry module"
  value       = module.motd.files["motd.txt"].content
}

output "backends" {
  description = "Every VM behind the load balancer, with its pool and weight"
  value       = local.backends
}

output "generations" {
  description = "Current generation of each pool. Changes when a pool is rolled."
  value       = { for pool, m in module.vm_pool : pool => m.generation }
}

output "haproxy_config" {
  description = "Path to the generated HAProxy config"
  value       = local_file.haproxy_cfg.filename
}

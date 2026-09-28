output "vm_name" {
  value = local.vm_name
}

output "description" {
  value = local.description
}

output "image_built" {
  value = "${local.image_built.weekday_name} ${local.image_built.day} ${local.image_built.month_name} ${local.image_built.year} (${local.image_age_days} days ago)"
}

output "tier_cidrs" {
  value = local.tier_cidrs
}

output "snapshots_to_keep" {
  value = local.snapshots_to_keep
}

output "host_name" {
  value = local.host_name
}

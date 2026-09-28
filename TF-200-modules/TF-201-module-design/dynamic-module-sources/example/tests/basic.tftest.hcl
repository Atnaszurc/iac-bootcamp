# Dynamic module sources: tests
#
# Module sources are resolved by `terraform init`, not per run block.
# Setting a const variable in a run block does NOT switch the installed
# module: a run with environment = "prod" would still use the module
# installed for dev, silently. So these tests cover the configuration as
# initialised (the defaults). To test prod, initialise for prod first:
#   terraform init -var environment=prod && terraform test -var environment=prod

run "dev_uses_network_v2" {
  command = plan

  assert {
    condition     = output.network_module_version == "v2"
    error_message = "dev should use network module v2, got ${output.network_module_version}"
  }

  assert {
    condition     = keys(output.subnets) == ["app", "db", "web"]
    error_message = "v2 plans one subnet per tier"
  }
}

run "registry_module_renders_motd" {
  command = plan

  assert {
    condition     = strcontains(output.motd, "planned by network module v2")
    error_message = "The motd should name the network module version: ${output.motd}"
  }
}

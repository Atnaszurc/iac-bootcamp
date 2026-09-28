run "one_instance_per_replica" {
  command = apply

  variables {
    name_prefix = "prod-tender-owl"
    environment = "prod"
    owner       = "platform"
    replicas    = 2
  }

  assert {
    condition     = output.instance_names == ["prod-tender-owl-app-0", "prod-tender-owl-app-1"]
    error_message = "Unexpected instance names: ${jsonencode(output.instance_names)}"
  }
}

run "too_many_replicas" {
  command = plan

  variables {
    name_prefix = "dev-x"
    environment = "dev"
    owner       = "platform"
    replicas    = 10
  }

  expect_failures = [var.replicas]
}

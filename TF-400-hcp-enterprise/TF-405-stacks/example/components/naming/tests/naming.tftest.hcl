# Components are ordinary modules: test them locally, no HCP Terraform needed.

run "prefix_starts_with_environment" {
  command = apply

  variables {
    environment = "dev"
  }

  assert {
    condition     = startswith(output.prefix, "dev-")
    error_message = "The prefix must start with the environment"
  }

  assert {
    condition     = length(split("-", output.prefix)) == 3
    error_message = "Expected <environment>-<word>-<word>"
  }
}

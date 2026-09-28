# One deployment per environment. Each has its own, isolated state.
# Two deployments x 1 billable resource = 2 resources under management.

deployment "dev" {
  inputs = {
    environment = "dev"
    owner       = "platform"
  }
}

deployment "prod" {
  inputs = {
    environment = "prod"
    owner       = "platform"
    replicas    = 2
  }
}

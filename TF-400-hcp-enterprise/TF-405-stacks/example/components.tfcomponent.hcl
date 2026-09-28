# The components of this Stack. Each is an ordinary Terraform module.
#
# Resources under management (RUM) per deployment:
#   naming: 1 (random_pet)
#   app:    0 (terraform_data doesn't count)

component "naming" {
  source = "./components/naming"

  inputs = {
    environment = var.environment
  }

  providers = {
    random = provider.random.this
  }
}

component "app" {
  source = "./components/app"

  # Referencing another component's output creates the dependency:
  # naming is planned and applied first.
  inputs = {
    name_prefix = component.naming.prefix
    environment = var.environment
    owner       = var.owner
    replicas    = var.replicas
  }

  providers = {
    terraform = provider.terraform.this
  }
}

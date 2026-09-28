# Stacks declare providers once, at the top, and pass them to components.
# Modules used as components can't configure providers themselves.

required_providers {
  random = {
    source  = "hashicorp/random"
    version = "~> 3.7"
  }

  # The built-in provider that terraform_data belongs to. In a normal
  # configuration it's implicit; a Stack must declare it and pass it on.
  terraform = {
    source = "terraform.io/builtin/terraform"
  }
}

# The alias ("this") is part of the block header, and arguments go in
# config {}. Neither provider has arguments, so config is empty.
provider "random" "this" {
  config {}
}

provider "terraform" "this" {
  config {}
}

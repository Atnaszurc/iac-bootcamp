# Test helper: generates a throwaway private key for the tests.
# (A regular tls_private_key, whose key IS stored in the test's state.
# That's fine for a key that only exists for the duration of a test.)

terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
    }
  }
}

resource "tls_private_key" "test" {
  algorithm = "ED25519"
}

output "private_key_pem" {
  value     = tls_private_key.test.private_key_pem
  sensitive = true
}

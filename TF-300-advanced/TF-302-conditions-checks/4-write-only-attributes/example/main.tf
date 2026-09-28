# TF-302 Section 4: Write-only attributes (Terraform 1.11+)
#
# Signs a certificate for the lab's web server with a private key that
# Terraform never stores: the key comes in through an ephemeral variable and
# goes into the write-only attribute private_key_pem_wo.
# Provider: hashicorp/tls (runs locally — no credentials)
#
#   openssl genpkey -algorithm ed25519 -out web.key     # the key lives outside Terraform
#   export TF_VAR_private_key_pem="$(cat web.key)"
#   terraform init && terraform apply
#   grep -c "PRIVATE KEY" terraform.tfstate               # 0

terraform {
  required_version = ">= 1.11"
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1" # private_key_pem_wo
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
  }
}

resource "tls_self_signed_cert" "web" {
  # Write-only: accepted during apply, sent to the provider, never stored in
  # state or plan files. It can take an ephemeral value, like this variable.
  private_key_pem_wo = var.private_key_pem

  # Terraform can't see changes to a value it doesn't store, so it can't tell
  # when the key changed. Bump the version to make it use a new key.
  private_key_pem_wo_version = var.key_version

  validity_period_hours = 24 * 90
  allowed_uses          = ["server_auth", "digital_signature", "key_encipherment"]
  dns_names             = [var.hostname]

  subject {
    common_name  = var.hostname
    organization = "iac-bootcamp lab"
  }
}

# The certificate is public, so it's fine in state and on disk
resource "local_file" "cert" {
  filename        = "${path.module}/out/${var.hostname}.crt"
  content         = tls_self_signed_cert.web.cert_pem
  file_permission = "0644"
}

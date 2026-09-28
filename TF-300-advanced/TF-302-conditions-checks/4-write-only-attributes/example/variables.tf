variable "private_key_pem" {
  description = "PEM private key for the certificate. Never stored: pass it with TF_VAR_private_key_pem."
  type        = string
  ephemeral   = true # not stored in state or plan files (Terraform 1.10+)

  validation {
    condition     = can(regex("-----BEGIN (EC |RSA )?PRIVATE KEY-----", var.private_key_pem))
    error_message = "private_key_pem must be a PEM private key (-----BEGIN PRIVATE KEY-----)."
  }
}

variable "key_version" {
  description = "Bump when you rotate the private key"
  type        = number
  default     = 1
}

variable "hostname" {
  type    = string
  default = "web.lab.local"
}

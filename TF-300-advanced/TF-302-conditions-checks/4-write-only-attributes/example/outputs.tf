output "cert_file" {
  value = local_file.cert.filename
}

output "cert_valid_until" {
  value = tls_self_signed_cert.web.validity_end_time
}

# ❌ A write-only attribute can't be read back. This fails with "Output
# refers to sensitive values", and even as a sensitive output it's null.
# output "key" {
#   value = tls_self_signed_cert.web.private_key_pem_wo
# }

output "cert_pem" {
  description = "The certificate (public, safe to output)"
  value       = tls_self_signed_cert.web.cert_pem
}

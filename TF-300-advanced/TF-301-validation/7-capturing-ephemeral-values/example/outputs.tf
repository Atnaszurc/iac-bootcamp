output "credentials_file" {
  description = "File containing the captured password"
  value       = local_sensitive_file.db_credentials.filename
}

output "password_version" {
  description = "Version of the captured password currently in state"
  value       = terraform_data.db_password.store.version
}

# A hash lets you (and the tests) see whether the password changed
# without printing it. Still marked sensitive — hashes of short secrets
# can be brute-forced.
output "password_fingerprint" {
  description = "SHA-256 of the captured password"
  value       = sha256(terraform_data.db_password.store.sensitive_output)
  sensitive   = true
}

# TF-302 Section 4: Write-only attributes — tests
# Uses the real tls and local providers (no credentials, nothing remote).

# Generate a throwaway key with the helper module in tests/setup
run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "sign_certificate" {
  command = apply

  variables {
    private_key_pem = run.setup.private_key_pem
  }

  assert {
    condition     = startswith(tls_self_signed_cert.web.cert_pem, "-----BEGIN CERTIFICATE-----")
    error_message = "A certificate should have been signed"
  }

  # The whole point: the write-only value is not in state
  assert {
    condition     = tls_self_signed_cert.web.private_key_pem_wo == null
    error_message = "A write-only attribute must read back as null"
  }

  assert {
    condition     = tls_self_signed_cert.web.private_key_pem == null
    error_message = "The regular private_key_pem attribute should not be used"
  }
}

run "same_version_keeps_certificate" {
  command = apply

  variables {
    private_key_pem = run.setup.private_key_pem
  }

  assert {
    condition     = tls_self_signed_cert.web.cert_pem == run.sign_certificate.cert_pem
    error_message = "Without a version bump, the certificate must not change"
  }
}

run "rejects_non_key_input" {
  command = plan

  variables {
    private_key_pem = "not a key"
  }

  expect_failures = [var.private_key_pem]
}

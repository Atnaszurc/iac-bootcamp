# TF-302 Section 5: Deprecation warnings — tests
#
# terraform test can't assert on warnings, so these tests check that the
# deprecated configuration and the migrated one (solution/) produce the same
# result: a migration shouldn't change behaviour.
# Uses the real random and null providers (no credentials, nothing remote).

override_resource {
  target = random_string.suffix
  values = {
    result = "abcdefgh"
  }
}

run "deprecated_version" {
  command = apply

  assert {
    condition     = output.vm_names == tomap({ web = "web-abcdefgh", db = "db-abcdefgh" })
    error_message = "The deprecated configuration should still produce the VM names"
  }
}

run "migrated_version" {
  command = apply

  module {
    source = "./solution"
  }

  assert {
    condition     = output.vm_names == { web = "web-abcdefgh", db = "db-abcdefgh" }
    error_message = "The migrated configuration must produce the same VM names"
  }

  assert {
    condition     = random_string.suffix.numeric == false
    error_message = "numeric replaces number"
  }
}

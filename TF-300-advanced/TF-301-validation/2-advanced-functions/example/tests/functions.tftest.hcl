# TF-301 Section 2: Advanced functions — tests
# random is overridden so names are predictable; time runs for real
# (its functions need no configuration and no network).

override_resource {
  target = random_string.suffix
  values = {
    result = "abc123"
  }
}

# The image-age check compares against today's date. Allow ~100 years here so
# the tests don't start failing once the default image_version gets old; the
# old_image test sets its own limit.
variables {
  max_image_age_days = 36500
}

run "naming_chain" {
  command = apply # random_string's result is only known after apply

  assert {
    condition     = output.vm_name == "my-app-dev-abc123"
    error_message = "Spaces and uppercase should become a lowercase, hyphenated name"
  }
}

run "naming_chain_truncates_to_63_without_trailing_hyphen" {
  command = apply

  variables {
    base_name = "${join("", [for i in range(61) : "a"])} x"
  }

  assert {
    condition     = length(output.vm_name) <= 63 && !endswith(output.vm_name, "-")
    error_message = "Names must fit a hostname and not end with a hyphen after truncation"
  }
}

run "labels_to_description" {
  command = plan

  assert {
    condition     = output.description == "owner=devops-team;project=iac-bootcamp;tier=web"
    error_message = "Labels should be sorted, lowercased keys joined with ;"
  }
}

run "image_date_is_parsed" {
  command = plan

  variables {
    image_version = "20260915.1"
  }

  assert {
    condition     = local.image_built.year == 2026 && local.image_built.month_name == "September" && local.image_built.weekday_name == "Tuesday"
    error_message = "time::rfc3339_parse should read the build date from the image version"
  }
}

run "old_image_triggers_check_warning" {
  command = plan

  variables {
    image_version      = "20200101"
    max_image_age_days = 30
  }

  expect_failures = [check.base_image_is_fresh]
}

run "tier_networks" {
  command = plan

  assert {
    condition     = output.tier_cidrs == tomap({ web = "10.140.0.0/24", app = "10.140.1.0/24", db = "10.140.2.0/24" })
    error_message = "Each tier should get its own /24 out of the /22"
  }
}

run "retention_in_snapshots" {
  command = plan

  variables {
    snapshot_retention      = "1h30m"
    snapshot_interval_hours = 1
  }

  assert {
    condition     = output.snapshots_to_keep == 2
    error_message = "1.5 hours at 1 snapshot per hour rounds up to 2 snapshots"
  }
}

run "bad_duration_rejected" {
  command = plan

  variables {
    snapshot_retention = "3 days"
  }

  expect_failures = [var.snapshot_retention]
}

run "host_name_with_lookup_fallbacks" {
  command = apply

  variables {
    service_name = "42-bad-name"
    site         = "Mars base"
  }

  assert {
    condition     = output.host_name == "svc-dev-unk-abc123"
    error_message = "Unknown site should map to 'unk' and an invalid service name to 'svc'"
  }
}

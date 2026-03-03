# Testing Guide — hashi-training

This guide explains the automated test suite for the hashi-training repository.

---

## Overview

All local-provider examples include `terraform test` test files (`*.tftest.hcl`).
These tests run without any cloud credentials — they use only the `hashicorp/local`
provider, which creates files on your local filesystem.

**17 examples are tested automatically.** Examples that require Azure, HCP Terraform,
or other external services are documented but not included in the automated suite.

---

## Quick Start

### Prerequisites

- **Terraform >= 1.6.0** (test framework was introduced in 1.6)
- **Linux, macOS, or WSL2** (Libvirt provider requires Unix-like environment)

> **Windows Users**: You must use WSL2. The Libvirt provider does not work on native Windows.

```bash
# Verify your Terraform version
terraform version
# Should show: Terraform v1.6.0 or higher
```

### Run All Tests

```bash
# From the hashi-training/ directory (in WSL2 if on Windows)
chmod +x scripts/run-tests.sh
./scripts/run-tests.sh
```

### Run a Single Example Manually

```bash
cd TF-100-fundamentals/TF-101-intro-basics/example
terraform init
terraform test
```

---

## Test Runner Script

The test runner script works on Linux, macOS, and WSL2:

| Script | Platform | Usage |
|--------|----------|-------|
| `scripts/run-tests.sh` | Linux / WSL2 / macOS | `./scripts/run-tests.sh [FILTER]` |

### Filtering Examples

Run only a subset of examples by passing a filter string:

```bash
./scripts/run-tests.sh TF-100        # All TF-100 examples (7 tests)
./scripts/run-tests.sh TF-306        # All TF-306 function examples (4 tests)
./scripts/run-tests.sh json-config   # Only the json-config example
./scripts/run-tests.sh --list        # List all testable examples
```

---

## Test Coverage

### TF-100: Fundamentals (7 examples)

| Example | Test File | What's Tested |
|---------|-----------|---------------|
| `TF-101/example` | `tests/basic.tftest.hcl` | Creates hello.txt and null-resource; validates outputs |
| `TF-102/1-variables/example` | `tests/basic.tftest.hcl` | Two hardcoded local_file resources |
| `TF-102/2-loops/example` | `tests/basic.tftest.hcl` | count loop (3 files) + for_each map (2 files) |
| `TF-102/3-env-vars/example` | `tests/basic.tftest.hcl` | count loop + for_each set (fruits) + for_each map |
| `TF-102/4-functions/example` | `tests/basic.tftest.hcl` | for_each map with environment prefix; validation |
| `TF-104/1-cli/example` | `tests/basic.tftest.hcl` | for_each map; environment-prefixed filenames |
| `TF-104/2-state/example` | `tests/basic.tftest.hcl` | for_each map; state inspection scenario |

### TF-200: Modules & Patterns (3 examples)

| Example | Test File | What's Tested |
|---------|-----------|---------------|
| `TF-201/moved-blocks/example` | `tests/basic.tftest.hcl` | Renamed resources (web, api, db); moved blocks |
| `TF-203/json-config/example` | `tests/basic.tftest.hcl` | jsondecode(); enabled/disabled server filtering; deployment manifest |
| `TF-204/removed-blocks/example` | `tests/basic.tftest.hcl` | removed block (no-op); permanent_config resource |

### TF-300: Advanced (7 examples)

| Example | Test File | What's Tested |
|---------|-----------|---------------|
| `TF-301/3-sensitive-values/example` | `tests/basic.tftest.hcl` | Sensitive variables; validation rules; file content |
| `TF-302/3-lifecycle-arguments/example` | `tests/basic.tftest.hcl` | lifecycle meta-arguments; validation; config_version format |
| `TF-305/1-workspaces/example` | `tests/basic.tftest.hcl` | terraform.workspace in default workspace (size=small) |
| `TF-306/1-string-functions/example` | `tests/basic.tftest.hcl` | format(), replace(), split(), join(), regex(), substr() |
| `TF-306/2-collection-functions/example` | `tests/basic.tftest.hcl` | flatten(), merge(), setproduct(), zipmap(), distinct() |
| `TF-306/3-filesystem-functions/example` | `tests/basic.tftest.hcl` | templatefile(), file(), path variables |
| `TF-306/4-encoding-functions/example` | `tests/basic.tftest.hcl` | jsonencode(), yamlencode(), base64encode(), type conversions |

---

## Examples NOT Tested (Require External Services)

These examples are excluded from the automated test suite because they require
credentials or external infrastructure:

### Azure Provider (requires `az login`)
- `TF-103-infrastructure/` — all subdirectories
- `TF-104-state-cli/example/` — top-level example
- `TF-200-modules/TF-202-advanced-patterns/2-canary-deployments/`
- `TF-200-modules/TF-203-yaml-config/example/`

### HCP Terraform (requires `terraform login` + organization)
- `TF-400-hcp-enterprise/` — all examples (use `cloud` block)
- `TF-305-workspaces-remote-state/2-remote-backends/`
- `TF-305-workspaces-remote-state/4-hcp-terraform-state/`

### Remote State (requires running infrastructure)
- `TF-305-workspaces-remote-state/3-remote-state-sharing/` — uses `terraform_remote_state`

---

## How Tests Work

### Test Framework Basics

Terraform's built-in test framework (`terraform test`) was introduced in **Terraform 1.6**.
Test files use the `.tftest.hcl` extension and live in a `tests/` subdirectory.

```hcl
# Example: tests/basic.tftest.hcl

run "creates_config_file" {
  command = apply          # or "plan" for plan-only tests

  variables {
    environment = "test"   # Override variables for this run
  }

  assert {
    condition     = local_file.config.content == "expected content"
    error_message = "Config file content does not match expected value"
  }
}
```

### Key Concepts

| Concept | Description |
|---------|-------------|
| `run` block | A single test case; each `run` is independent |
| `command = apply` | Applies the configuration and checks assertions |
| `command = plan` | Only plans (faster; use for validation testing) |
| `variables {}` | Override variable values for this specific run |
| `assert {}` | A condition that must be true; fails with `error_message` |
| `expect_failures` | Assert that a validation/precondition SHOULD fail |

### `expect_failures` — Testing Validation Rules

Use `expect_failures` to verify that invalid inputs are correctly rejected:

```hcl
run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "invalid-value"
  }

  # This run PASSES if var.environment validation fails
  expect_failures = [var.environment]
}
```

### Sensitive Variables in Tests

Tests can assert on the content of files that contain sensitive values.
The test framework runs in a trusted context — sensitive values are not
redacted in assertions (only in plan/apply output shown to users).

```hcl
run "sensitive_value_is_written_to_file" {
  command = apply

  assert {
    # This works even though db_password is sensitive = true
    condition     = strcontains(local_file.config.content, "db_password")
    error_message = "Config file should contain db_password field"
  }
}
```

---

## Writing New Tests

When adding a new example with `hashicorp/local` provider:

1. **Create the `tests/` directory** inside the `example/` folder
2. **Create `basic.tftest.hcl`** with at least one `run` block
3. **Add the path** to `TESTABLE_EXAMPLES` in both runner scripts

### Test File Template

```hcl
# <Course>/<Section> Test: <brief description>
# Variables: <list variables and their defaults>
# Provider: hashicorp/local (no credentials required)
# Run: terraform test (from the example/ directory)

run "creates_expected_resources" {
  command = apply

  assert {
    condition     = <resource>.<name>.<attribute> == "<expected>"
    error_message = "<description of what should be true>"
  }
}

run "validation_rejects_invalid_input" {
  command = plan

  variables {
    some_var = "invalid"
  }

  expect_failures = [var.some_var]
}
```

### Useful Assertion Patterns

```hcl
# Check file content exactly
condition = local_file.example.content == "exact content"

# Check file content contains a substring
condition = strcontains(local_file.example.content, "substring")

# Check filename ends with expected value
condition = endswith(local_file.example.filename, "expected.txt")

# Check number of resources created
condition = length(local_file.example_map) == 3

# Check map keys
condition = contains(keys(local_file.example_map), "key-name")

# Check output value
condition = output.my_output == "expected"

# Check output length
condition = length(output.my_list) == 5

# Check boolean output
condition = output.success == true
```

---

## Troubleshooting

### `Error: Unsupported argument` in test file

The test framework syntax changed between versions. Ensure you're using Terraform >= 1.6:
```bash
terraform version
```

### `Error: Variables not allowed` 

The `variables {}` block inside a `run` block requires Terraform >= 1.7 for some features.
Use `terraform version` to verify.

### Test passes but files remain on disk

`terraform test` automatically destroys resources after each `run` block.
If files remain, check for `lifecycle { prevent_destroy = true }` in the example.

### `Error: No test files found`

Ensure the test file is in a `tests/` subdirectory (not `test/`) and has the
`.tftest.hcl` extension (not `.tf`).

### Init fails with provider download error

```bash
# Clear the provider cache and retry
rm -rf .terraform .terraform.lock.hcl
terraform init
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Terraform Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.9"

      - name: Run Terraform tests
        working-directory: hashi-training
        run: |
          chmod +x scripts/run-tests.sh
          ./scripts/run-tests.sh
```

### GitLab CI

```yaml
terraform-tests:
  image: hashicorp/terraform:1.9
  script:
    - cd hashi-training
    - chmod +x scripts/run-tests.sh
    - ./scripts/run-tests.sh
```

---

## Related Documentation

- [Terraform Test Framework](https://developer.hashicorp.com/terraform/language/tests) — Official docs
- [TF-303: Test Framework Course](../TF-300-advanced/TF-303-test-framework/README.md) — In-depth training
- [Quick Start Guide](quick-start-guide.md) — Getting started with the training
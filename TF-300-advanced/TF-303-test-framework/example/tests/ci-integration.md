# CI/CD Integration for Terraform Tests

## JUnit XML Output (Terraform 1.11+)

Terraform 1.11 made JUnit XML output generally available (GA). Use the `-junit-xml` flag to produce test results in a format that CI/CD systems can parse and display.

### Basic Usage

```bash
# Run all tests and output JUnit XML
terraform test -junit-xml=results.xml

# Run specific test file with JUnit output
terraform test -filter=tests/basic.tftest.hcl -junit-xml=results.xml

# Run with verbose output AND JUnit XML
terraform test -verbose -junit-xml=results.xml
```

### Sample JUnit XML Output

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="tests/basic.tftest.hcl" tests="8" failures="0" errors="0" time="2.341">
    <testcase name="environment_is_normalised_to_lowercase" time="0.312" />
    <testcase name="service_counts_are_correct" time="0.287" />
    <testcase name="enabled_services_are_correct" time="0.301" />
    <testcase name="config_file_paths_contain_environment" time="0.298" />
    <testcase name="debug_file_not_created_when_disabled" time="0.285" />
    <testcase name="debug_file_created_when_enabled" time="0.291" />
    <testcase name="common_tags_include_required_keys" time="0.278" />
    <testcase name="prod_environment_configuration" time="0.289" />
  </testsuite>
</testsuites>
```

### Failed Test in JUnit XML

```xml
<testcase name="service_counts_are_correct" time="0.287">
  <failure message="Expected 3 total services, got 2">
    Error: Expected 3 total services, got 2

      on tests/basic.tftest.hcl line 73, in run "service_counts_are_correct":
      73:     condition     = output.service_count == 3
  </failure>
</testcase>
```

---

## GitHub Actions Integration

```yaml
# .github/workflows/terraform-test.yml
name: Terraform Tests

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.14"

      - name: Terraform Init
        run: terraform init
        working-directory: TF-303-test-framework/example

      - name: Terraform Test
        run: terraform test -junit-xml=test-results.xml
        working-directory: TF-303-test-framework/example

      - name: Publish Test Results
        uses: EnricoMi/publish-unit-test-result-action@v2
        if: always()   # Run even if tests fail
        with:
          files: TF-303-test-framework/example/test-results.xml
```

---

## Azure DevOps Integration

```yaml
# azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: ubuntu-latest

steps:
  - task: TerraformInstaller@1
    inputs:
      terraformVersion: "~1.14"

  - script: terraform init
    displayName: "Terraform Init"
    workingDirectory: TF-303-test-framework/example

  - script: terraform test -junit-xml=$(Build.ArtifactStagingDirectory)/test-results.xml
    displayName: "Terraform Test"
    workingDirectory: TF-303-test-framework/example

  - task: PublishTestResults@2
    condition: always()
    inputs:
      testResultsFormat: JUnit
      testResultsFiles: "$(Build.ArtifactStagingDirectory)/test-results.xml"
      testRunTitle: "Terraform Tests"
```

---

## Parallel Test Execution (Terraform 1.12+)

Terraform 1.12 added the `-parallelism` flag to `terraform test`, allowing multiple test files to run concurrently.

### Usage

```bash
# Run tests with 4 parallel workers (default is 10)
terraform test -parallelism=4

# Run all tests in parallel (use system default)
terraform test -parallelism=10

# Disable parallelism (sequential execution)
terraform test -parallelism=1

# Combine with JUnit output
terraform test -parallelism=4 -junit-xml=results.xml
```

### When to Use Parallel vs Sequential

| Scenario | Recommendation |
|----------|---------------|
| Unit tests (plan only, mock providers) | ✅ High parallelism (4–10) |
| Integration tests (apply, real resources) | ⚠️ Low parallelism (1–2) — avoid resource conflicts |
| Tests sharing state (`state_key`) | ❌ Sequential (`-parallelism=1`) — state conflicts |
| CI/CD with limited API rate limits | ⚠️ Low parallelism (2–4) |
| Local development | ✅ Default (10) for fast feedback |

### Parallelism Notes

- Parallelism applies **across test files**, not within a single file
- Run blocks within a single `.tftest.hcl` file always execute sequentially
- Use `-parallelism=1` when tests have shared external dependencies
- The `state_key` feature (1.11+) is designed for sequential use within a file

---

## Complete CI Command Reference

```bash
# Standard test run
terraform test

# With JUnit XML (CI/CD)
terraform test -junit-xml=results.xml

# Verbose output (shows all assertions)
terraform test -verbose

# Filter to specific file
terraform test -filter=tests/basic.tftest.hcl

# Filter to specific run block
terraform test -filter=tests/basic.tftest.hcl/service_counts_are_correct

# Parallel execution (1.12+)
terraform test -parallelism=4

# Full CI command
terraform test -parallelism=4 -junit-xml=results.xml -verbose
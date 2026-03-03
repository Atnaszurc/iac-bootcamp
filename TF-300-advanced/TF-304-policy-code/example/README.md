# TF-304: Policy as Code — Example

This example demonstrates OPA (Open Policy Agent) policies for Terraform plan evaluation.

## Structure

```
example/
├── plan.json              # Sample Terraform plan JSON (input for OPA)
├── policies/
│   ├── naming.rego        # Naming convention policies
│   └── security.rego      # Security policies
└── tests/
    ├── naming_test.rego   # OPA tests for naming policies
    └── security_test.rego # OPA tests for security policies
```

## Prerequisites

Install OPA:
```bash
# Linux/macOS
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static
chmod +x opa
sudo mv opa /usr/local/bin/

# macOS (Homebrew)
brew install opa

# Windows (Chocolatey)
choco install open-policy-agent

# Verify
opa version
```

## Running Policy Tests

```bash
# Run all OPA unit tests (no input file needed — tests use inline fixtures)
opa test policies/ tests/ -v

# Expected output:
# data.terraform.naming.test_compliant_resource_has_no_violations: PASS
# data.terraform.naming.test_missing_name_tag_is_violation: PASS
# ...
# PASS: 15/15
```

## Evaluating Policies Against a Plan

```bash
# Step 1: Generate a real Terraform plan JSON
terraform plan -out=tfplan
terraform show -json tfplan > plan.json

# Step 2: Evaluate naming policy violations
opa eval -d policies/ -i plan.json "data.terraform.naming.violations"

# Step 3: Evaluate security policy violations
opa eval -d policies/ -i plan.json "data.terraform.security.violations"

# Step 4: Check if plan is allowed (no violations)
opa eval -d policies/ -i plan.json "data.terraform.naming.allow"
opa eval -d policies/ -i plan.json "data.terraform.security.allow"
```

## Using the Sample plan.json

The included `plan.json` contains **intentional violations** for learning:
- `local_file.insecure_example` has `0777` permissions (security violation)
- `local_file.insecure_example` has `Name = "BadName"` (naming violation)
- `local_file.insecure_example` has `Environment = "production"` (invalid value)
- `local_file.insecure_example` has `ManagedBy = "manual"` (security violation)

```bash
# Evaluate the sample plan — expect violations
opa eval -d policies/ -i plan.json "data.terraform.naming.violations"
opa eval -d policies/ -i plan.json "data.terraform.security.violations"
```

## Integrating with CI/CD

```bash
# Exit with non-zero code if violations exist (for CI/CD gates)
opa eval -d policies/ -i plan.json \
  --fail-defined \
  "data.terraform.naming.deny[_]"

# Or use a combined check script:
NAMING_VIOLATIONS=$(opa eval -d policies/ -i plan.json \
  --format raw "count(data.terraform.naming.violations)")

SECURITY_VIOLATIONS=$(opa eval -d policies/ -i plan.json \
  --format raw "count(data.terraform.security.violations)")

if [ "$NAMING_VIOLATIONS" -gt 0 ] || [ "$SECURITY_VIOLATIONS" -gt 0 ]; then
  echo "Policy violations found! Blocking deployment."
  exit 1
fi
```

## Policy Summary

### naming.rego
| Rule | Description |
|------|-------------|
| Name tag required | All resources must have a `Name` tag |
| Name format | Must match `<env>-<type>-<name>` (e.g. `dev-vm-webserver`) |
| Environment values | Must be one of: `dev`, `staging`, `prod` |

### security.rego
| Rule | Description |
|------|-------------|
| No world-writable | File permissions must not end in `7` or `6` (world-writable) |
| ManagedBy tag | Must be set to `"terraform"` |
| Prod Owner tag | Production resources must have an `Owner` tag |
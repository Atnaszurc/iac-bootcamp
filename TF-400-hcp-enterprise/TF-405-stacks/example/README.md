# TF-405 Terraform Stacks Example

A minimal Stack: two components, two deployments, and **2 resources under management** in total. No cloud account needed. The [module README](../README.md) explains every part and how to build it out.

## Files

| File | What it holds |
|---|---|
| `.terraform-version` | Terraform version HCP Terraform uses (1.16.4) |
| `.terraform.lock.hcl` | Provider lock file, with checksums for Linux, macOS and Windows |
| `variables.tfcomponent.hcl` | `environment` (validated), `owner`, `replicas` |
| `providers.tfcomponent.hcl` | `random`, and the built-in `terraform` provider that `terraform_data` needs |
| `components.tfcomponent.hcl` | `naming` → `app` |
| `outputs.tfcomponent.hcl` | `prefix`, `instances` |
| `deployments.tfdeploy.hcl` | `dev` and `prod` |
| `components/naming/` | `random_pet`: 1 billable resource per deployment |
| `components/app/` | `terraform_data`: not billable |

## Locally

```bash
terraform stacks init
terraform stacks providers-lock
terraform stacks validate
# Success! Terraform Stacks configuration is valid and ready for use within HCP Terraform.

# Components are ordinary modules with ordinary tests
(cd components/naming && terraform init && terraform test)   # 1 passed
(cd components/app && terraform init && terraform test)      # 2 passed
```

Verified with Terraform 1.16.4 and 1.17.0-beta2 (the Stacks plugin was v1.4.0).

## In HCP Terraform

```bash
terraform login
terraform stacks create -organization-name=ORG -project-name=PROJECT -stack-name=tf405
terraform stacks configuration upload -organization-name=ORG -project-name=PROJECT -stack-name=tf405
```

Approve the `dev` and `prod` plans in the UI. To clean up, add `destroy = true` to both deployments, upload and approve, then delete the Stack.

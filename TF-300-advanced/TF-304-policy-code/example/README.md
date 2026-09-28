# TF-304: Policy as Code — Example

OPA policies for a small libvirt configuration. The [module README](../README.md) explains every part; this page is the quick reference.

## Files

| Path | What it is |
|---|---|
| `main.tf`, `variables.tf` | A network, VMs and their data disks (libvirt) |
| `violations.tfvars` | Values that break the policies |
| `compliant.tfvars` | Values that pass them |
| `plan.json` | A real plan: `terraform show -json`, made with `violations.tfvars` (Terraform 1.16.4) |
| `policy/config/data.json` | Allowed forward modes and shared networks: `data.config` |
| `policy/terraform/libvirt/lib/` | Shared helpers: the plan (local or HCP Terraform), changes, units |
| `policy/terraform/libvirt/naming/` | Names and owners |
| `policy/terraform/libvirt/resources/` | Memory, vCPU and disk limits; a `warn` for many vCPUs |
| `policy/terraform/libvirt/network/` | Forward modes; VMs only join known networks |
| `.regal/config.yaml` | Regal (linter) settings |

Each `*_test.rego` sits next to the policy it tests.

## Commands

Needs OPA 1.x (tested with 1.21.0). No Terraform or libvirt needed for these:

```bash
opa test policy -v                     # PASS: 36/36
opa test policy --coverage --format=json | jq .coverage   # 100
regal lint policy                      # No violations found

# All violations in the included plan (9)
opa eval -f raw -d policy -i plan.json '[m | some m in data.terraform.libvirt[_].deny]' | jq -r '.[]'

# Advisories (1)
opa eval -f raw -d policy -i plan.json '[m | some m in data.terraform.libvirt[_].warn]' | jq -r '.[]'

# CI gate: exit code 1 when there are violations
opa eval --fail-defined -d policy -i plan.json 'data.terraform.libvirt[_].deny[_]' > /dev/null
```

Make your own plan (needs Terraform and libvirt; nothing is applied):

```bash
terraform init
terraform plan -var-file=compliant.tfvars -out=tfplan
terraform show -json tfplan > compliant.json
opa eval --fail-defined -d policy -i compliant.json 'data.terraform.libvirt[_].deny[_]'   # exit code 0
```

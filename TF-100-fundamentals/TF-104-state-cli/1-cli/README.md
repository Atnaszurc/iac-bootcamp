# Terraform CLI Commands for Beginners

Objective: Learn and practice essential Terraform CLI commands to manage your infrastructure as code effectively.

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Essential Terraform CLI Commands](#essential-terraform-cli-commands)
   - [1. terraform init](#1-terraform-init)
   - [2. terraform fmt](#2-terraform-fmt)
   - [3. terraform validate](#3-terraform-validate)
   - [4. terraform plan](#4-terraform-plan)
   - [5. terraform apply](#5-terraform-apply)
   - [6. terraform show](#6-terraform-show)
   - [7. terraform output](#7-terraform-output)
   - [8. terraform refresh](#8-terraform-refresh)
   - [9. terraform plan (no changes)](#9-terraform-plan-no-changes)
   - [10. terraform taint](#10-terraform-taint)
   - [11. terraform untaint](#11-terraform-untaint)
   - [12. terraform apply -replace=local_file.example_map[\"file1\"]](#12-terraform-apply-replace-local_file.example_map[\"file1\"])
   - [13. terraform destroy](#13-terraform-destroy)
4. [Additional Exercises](#additional-exercises)
5. [Remember](#remember)

## Essential Terraform CLI Commands:

Use the example/main.tf file or the one you created in the previous exercise for the following steps.

### 1. terraform init
  - Run `terraform init` in your terminal.
  - This command initializes your working directory, downloads required providers, and sets up the backend.
  - Observe the output, noting that it downloads the local provider.

### 2. terraform fmt
  - Run `terraform fmt` in your terminal.
  - This command formats your Terraform configuration files for consistent style.
  - If there are any formatting changes, the command will list the files it modified.

### 3. terraform validate
  - Run `terraform validate` in your terminal.
  - This command checks your configuration for syntax errors and internal consistency.
  - If your configuration is valid, you'll see a success message.

### 4. terraform plan
  - First, set the environment variable:
  - For Linux/macOS: export TF_VAR_environment=dev
  - For Windows: set TF_VAR_environment=dev
  - Run `terraform plan` in your terminal.
  - This command creates an execution plan, showing you what actions Terraform will take.
  - Review the plan, noting the resources that will be created.

### 5. terraform apply    
  - Run `terraform apply` in your terminal.
  - This command applies the changes required to reach the desired state of the configuration.
  - Review the execution plan again and type 'yes' when prompted to create the resources.

Observe the output, including the created files.

### 6. terraform show
  - Run `terraform show` in your terminal.
  - This command provides a human-readable output of the current state.
  - Review the output to see details about the created resources.

### 7. terraform output
  - Run `terraform output` in your terminal.
  - This command displays the values of the outputs defined in your configuration.
  - You should see a list of the created file names.

### 8. terraform refresh
  - Run `terraform refresh` in your terminal.
  - This command updates the state file against real resources in the provider.
  - Observe that no changes are made since the state is already up to date.

### 9. terraform plan (no changes)
  - Run `terraform plan` again.

Observe that Terraform reports no changes are needed, as the current state matches the configuration.

### 10. terraform taint
  - Run `terraform taint local_file.example_map[\"file1.txt\"]` in your terminal. (quotes in resource addresses must be escaped on the command line, so that they will not be interpreted by your shell)
  - This command marks a resource for recreation.
  - Observe that the resource is marked for recreation.
  - However, the resource is not actually recreated until you run `terraform apply`. This can cause issues if you are multiple people working on the same infrastructure.

### 11. terraform untaint
  - Run `terraform untaint local_file.example_map[\"file1\"]` in your terminal.
  - This command unmarks a resource for recreation.
  - Observe that the resource is unmarked for recreation.

### 12. terraform apply -replace
  - Run `terraform apply -replace=local_file.example_map[\"file1.txt\"]`in your terminal.
  - This command replaces the marked resource.
  - Observe that the resource is replaced.
  - Contrary to `terraform taint`, this command actually recreates the resource and the change is visible in the next plan.

### 13. terraform destroy
  - Run `terraform destroy` in your terminal.
  - This command destroys all the resources defined in your Terraform configuration.
  - Review the destruction plan and type 'yes' when prompted to destroy the resources.
  - Verify that the local files have been removed from your directory.

### Additional exercises:
1. Modify the file_contents variable in main.tf to add or remove files.
2. Run terraform plan and terraform apply to see how Terraform handles incremental changes.
3. Change the TF_VAR_environment value (e.g., to "prod") and run terraform plan to see how it affects the planned changes.
Use terraform console to interactively explore and test Terraform expressions. For example:
11. `Run terraform console`
  - Try expressions like `var.file_contents` or `length(var.file_contents)`
  - Exit the console by typing `exit`
12. `Use terraform version to check your Terraform version and list installed providers.`
  - Use `terraform version` to check your Terraform version and list installed providers.


### Remember:
Always run terraform plan before terraform apply to review changes.
Use `terraform fmt` regularly to maintain consistent formatting.
`terraform validate` is useful for catching errors before applying changes.
`terraform destroy` removes all resources, so use it cautiously in production environments.

---

## 🆕 New CLI Commands (Terraform 1.9–1.14)

The following commands and flags were added after the core exercises above. They are covered here as supplemental reference.

### `terraform init -json` (1.9)

Machine-readable JSON output from `terraform init` — useful for CI/CD pipelines:

```bash
terraform init -json
```

```json
{
  "@level": "info",
  "@message": "Terraform has been successfully initialized!",
  "type": "init_summary",
  "init_reason": "providers",
  "providers": {
    "registry.terraform.io/hashicorp/local": {
      "installed_version": "2.7.0"
    }
  }
}
```

**Use case**: Parse init output in automation scripts without screen-scraping.

---

### `terraform console` Multi-Line Input (1.9)

Starting in Terraform 1.9, `terraform console` supports **multi-line input**. You can now paste or type multi-line expressions directly:

```bash
terraform console
```

```hcl
# Multi-line expression — press Enter twice (blank line) to evaluate
> [
    for i in range(3) :
    "server-${i}"
  ]
tolist([
  "server-0",
  "server-1",
  "server-2",
])
```

Previously, you had to write the entire expression on one line. Multi-line input makes complex `for` expressions and object literals much easier to test interactively.

---

### `terraform modules -json` (1.10)

List all modules used in the current configuration in machine-readable JSON format:

```bash
terraform modules -json
```

```json
{
  "format_version": "1.0",
  "modules": [
    {
      "key": "network",
      "source": "./modules/network",
      "version": ""
    },
    {
      "key": "vm",
      "source": "./modules/vm",
      "version": ""
    }
  ]
}
```

**Use case**: Audit which modules are in use, generate dependency graphs, or feed into CI/CD tooling.

---

### `terraform stacks` (1.13)

Terraform Stacks is a new orchestration layer for managing multiple configurations as a unit. The `terraform stacks` command is the entry point:

```bash
# Stacks require HCP Terraform — not available in local/OSS Terraform
terraform stacks validate
terraform stacks plan
terraform stacks apply
```

> **Note**: Stacks use `.tfstack.hcl` and `.tfdeploy.hcl` file types. They are covered in depth in **TF-405: Terraform Stacks** (TF-400 series). Stacks require HCP Terraform and are not available in the open-source CLI alone.

---

### `terraform query` (1.14)

Query existing infrastructure using **list resources** (`.tfquery.hcl` files):

```bash
# Run a query against existing infrastructure
terraform query

# Generate import configuration from query results
terraform query -generate-config-out=imported.tf
```

> **Note**: `terraform query` requires providers that implement list resources. It is covered in depth in **TF-307: Query & Actions** (TF-300 series).
>
> 📝 The Terraform 1.16 `query` reference page calls this flag `-generate-config`. Terraform 1.16 and 1.17 only accept `-generate-config-out`.

---

### ⚠️ Deprecated: `-state` Flag (1.10)

The `-state` flag on `terraform plan`, `terraform apply`, and `terraform refresh` was **deprecated in Terraform 1.10**:

```bash
# ❌ DEPRECATED (1.10+) — do not use in new configurations
terraform plan -state=custom.tfstate
terraform apply -state=custom.tfstate

# ✅ Use workspaces or backend configuration instead
terraform workspace select my-workspace
terraform apply
```

**Migration**: If you were using `-state` to point to a custom state file, migrate to using a properly configured backend or workspaces.

---

### ⚠️ Deprecated: DynamoDB State Locking for S3 Backend (1.11)

The `dynamodb_table` argument in the S3 backend is **deprecated in Terraform 1.11** in favour of native S3 state locking:

```hcl
# ❌ DEPRECATED approach (still works, but will be removed in a future version)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"  # deprecated
  }
}

# ✅ MODERN approach — S3 native locking (Terraform 1.11+)
terraform {
  backend "s3" {
    bucket       = "my-terraform-state"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true  # S3 native locking — no DynamoDB needed
  }
}
```


---

### `terraform validate` — Backend Validation (1.15)

Since **Terraform 1.15**, `terraform validate` checks the `backend` block too, without needing `terraform init`:

```hcl
terraform {
  backend "s4" { # typo: should be "s3"
    bucket = "my-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
```

```bash
terraform validate
# Error: Unsupported backend type
#   on main.tf line 2, in terraform:
#    2:   backend "s4" { # typo: should be "s3"
# There is no backend type named "s4".
```

It checks that the backend **type** exists and that there is only one `backend` block. It does **not** check the arguments inside the block: a backend block may be a *partial configuration*, with values such as `bucket` supplied later by `terraform init -backend-config=...`, and `validate` can't know about those. (1.15.0 did check the arguments; 1.15.1 removed that again because it broke `-backend-config` workflows.)

So a missing `bucket`, a misspelt argument or a wrong type passes `validate` and is caught by `terraform init`, locally, before it contacts any storage:

```bash
terraform validate
# Success! The configuration is valid.
terraform init -input=false
# Error: Missing Required Value
#   on main.tf line 2, in terraform:
#    2:   backend "s3" {
# The attribute "bucket" is required by the backend.
```

> **Deep dive**: See [`6-backend-validation/`](./6-backend-validation/) for a hands-on with every case, what gets checked where, and how to use it in CI. No cloud account needed.

> **Deep dive**: See **TF-305 Section 2** for a full walkthrough of S3 backend configuration and the migration from DynamoDB locking to native S3 locking.

---

## 🆕 CLI Additions in Terraform 1.16

| Command | What's new | Covered in |
|---------|-----------|------------|
| `terraform state show -json ADDRESS` | One resource from state as JSON | [Section 2: State](../2-state/README.md#task-4-show-a-specific-resource) |
| `terraform workspace list -json` | Workspaces and the current one as JSON | [TF-305 Section 1](../../../TF-300-advanced/TF-305-workspaces-remote-state/1-workspaces/README.md#machine-readable-workspace-list-terraform-116) |
| `terraform console -scope=module.NAME` | Evaluate expressions inside a child module | [Section 5: Console](../5-terraform-console/README.md#-evaluating-inside-a-child-module--scope-terraform-116) |

---

## 🧪 Beta: `terraform plan -minimal-refresh` (Terraform 1.17)

> ⚠️ **Terraform 1.17 is in beta** (1.17.0-beta2 at the time of writing). Flags can still change before the final release. Terraform 1.16 rejects this flag: `flag provided but not defined: -minimal-refresh`.

By default, every plan first **refreshes** every resource — one or more API calls each — to detect changes made outside Terraform. On large configurations that's most of the plan time.

`-minimal-refresh` skips the refresh for resources whose configuration hasn't changed:

1. Terraform compares configuration with the **prior state** (no API calls)
2. Resources with **no planned change** are not refreshed
3. Resources **with** a planned change are refreshed and planned again with fresh data

### The Trade-Off: Drift Goes Unnoticed

Try it with this section's example on Terraform 1.17:

```bash
cd example
export TF_VAR_environment=dev
terraform apply -auto-approve

# Change a file behind Terraform's back
echo "tampered" > dev_file1.txt

terraform plan -minimal-refresh
# No changes. Your infrastructure matches the configuration.   ← drift missed

terraform plan
#   # local_file.example_map["file1.txt"] will be created
# Plan: 1 to add, 0 to change, 0 to destroy.                  ← drift found
```

### Rules

| Combination | Result |
|-------------|--------|
| `-minimal-refresh` | Refresh only resources with planned changes |
| `-minimal-refresh -refresh=false` | ❌ Error — mutually exclusive |
| `-minimal-refresh -refresh-only` | ❌ Error — only valid in normal or destroy mode |

### When to Use It

| Use `-minimal-refresh` | Use a normal plan |
|------------------------|-------------------|
| Fast feedback while iterating on a large configuration | Before every `apply` to a shared environment |
| Pull-request plans where only changed resources matter | Scheduled drift detection |
| | Right after upgrading provider versions — Terraform needs a full refresh to populate new schema fields |

Compared with `-refresh=false`, which skips refresh for **everything**, `-minimal-refresh` still refreshes what you're about to change, so the plan for those resources is based on real data.

## Testing Considerations

### Using command = apply in Tests

This module's tests use `command = apply` instead of `command = plan` because the infrastructure resources create values that are unknown until after the apply phase.

**Why apply is required**:
- Resource IDs are generated during creation
- Computed attributes are only known after apply
- Output values depend on created resources

**When to use plan vs apply**:
- **Use `command = plan`**: When testing static values, data sources, or validation logic
- **Use `command = apply`**: When testing resource creation, outputs, or computed values

`hcl
# Example test structure
run "test_infrastructure" {
  command = apply  # Required for resource testing
  
  assert {
    condition     = output.resource_id != ""
    error_message = "Resource ID should be generated"
  }
}
`

**Note**: Using `command = apply` means tests will create actual infrastructure, so ensure proper cleanup in test teardown.

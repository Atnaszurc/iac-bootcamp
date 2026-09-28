# Section 5: Deprecation Warnings

**Terraform Version**: 1.15+  
**Duration**: 20 minutes  
**Difficulty**: Intermediate

---

## 📋 Overview

Providers deprecate things all the time: an argument gets a better name, a resource is replaced by a new one, a data source becomes unnecessary. A deprecated feature keeps working for a while, and Terraform warns you about it on every plan. Then, in some future major version, it's gone and your configuration breaks.

Terraform 1.15 made these warnings more useful:

1. **Provider messages**: the provider's own explanation of what to use instead is shown in the warning
2. **Follow the value**: when a deprecated value flows into something else (an output, another resource), Terraform warns *there* too, and says where the deprecation originates
3. **Clearer warnings** with the exact file and line

This section uses real deprecations in the `random` and `null` providers, so you can see real warnings and do a real migration without any cloud account.

---

## 🎯 Learning Objectives

By the end of this section, you will be able to:

- ✅ Read a deprecation warning and find the replacement
- ✅ Follow a "Deprecated value used" warning back to its origin
- ✅ Migrate deprecated arguments and data sources without changing infrastructure
- ✅ Detect deprecation warnings reliably in CI

---

## 📚 Theory

### What is Deprecation?

Deprecation marks a feature as "still works, but will be removed". It's a transition period: the old and new ways exist side by side, so you can migrate at your own pace.

### Deprecation Lifecycle

```
v3.4: numeric added, number deprecated  →  warnings on every plan
v3.x: both work                         →  your window to migrate
v4.0: number removed                    →  configuration breaks
```

The window can be long, but it ends. A plan that's full of deprecation warnings is a plan with a deadline you can't see.

### Where Do Warnings Come From?

Providers mark attributes, blocks and whole resources as deprecated in their schema, with a message. You can see them yourself:

```bash
terraform providers schema -json | jq '.provider_schemas[].resource_schemas.random_string.block.attributes.number'
# { "deprecated": true, "description": "... **NOTE**: This is deprecated, use `numeric` instead.", ... }
```

Your own modules can deprecate variables and outputs too, with the `deprecated` argument (Terraform 1.15+): see [TF-102 Section 6](../../../TF-100-fundamentals/TF-102-variables-loops/6-deprecated-attribute/README.md).

---

## ⚠️ Reading the Warnings

The [`example/`](./example/) configuration works, but uses two deprecated things:

```hcl
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  number  = false # deprecated
}

data "null_data_source" "names" { # deprecated
  inputs = {
    web = "web-${random_string.suffix.result}"
    db  = "db-${random_string.suffix.result}"
  }
}

output "vm_names" {
  value = data.null_data_source.names.outputs
}
```

```bash
cd example
terraform init
terraform apply
```

### 1. A deprecated argument

```
Warning: Attribute Deprecated

  with random_string.suffix,
  on main.tf line 32, in resource "random_string" "suffix":
  32:   number  = false # deprecated

**NOTE**: This is deprecated, use `numeric` instead.
```

The last line is the provider's own message: it tells you the replacement.

### 2. A deprecated data source

```
Warning: Deprecated

  with data.null_data_source.names,
  on main.tf line 36, in data "null_data_source" "names":

The null_data_source was historically used to construct intermediate values
to re-use elsewhere in configuration, the same can now be achieved using
locals or the terraform_data resource type in Terraform 1.4 and later.
```

### 3. A deprecated value, used elsewhere

```
Warning: Deprecated value used

  on main.tf line 44, in output "vm_names":
  44:   value = data.null_data_source.names.outputs

  The deprecation originates from data.null_data_source.names
```

Nothing is wrong with the output itself, but it depends on something deprecated. In a large configuration this tells you everything you'll have to touch when you migrate.

### "(and 2 more similar warnings elsewhere)"

Terraform folds repeated warnings together. To see every single one, use JSON output:

```bash
terraform plan -json | jq -r 'select(.type == "diagnostic" and .diagnostic.severity == "warning") | .diagnostic.summary'
# Attribute Deprecated
# Deprecated
# Deprecated value used
# Deprecated value used
```

---

## 🛠️ Migrating

### Step 1: Replace the argument

```hcl
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = false # was: number
}
```

### Step 2: Replace the data source with locals

```hcl
locals {
  vm_names = {
    web = "web-${random_string.suffix.result}"
    db  = "db-${random_string.suffix.result}"
  }
}

output "vm_names" {
  value = local.vm_names
}
```

Remove the `null` provider from `required_providers` too: nothing uses it any more.

### Step 3: Verify

```bash
terraform init
terraform plan
# No changes. Your infrastructure matches the configuration.
```

No warnings, and **no changes**. That's what a good migration looks like: same infrastructure, same values (compare `terraform output` before and after), newer code. If the plan wants to *replace* something, stop and read the provider's upgrade guide before applying.

The finished version is in [`example/solution/`](./example/solution/). The tests (`terraform test`) run both versions and check they produce the same VM names.

---

## 🎯 Best Practices

### 1. Address Deprecations Promptly

- ❌ Ignoring warnings leads to breaking changes at the worst moment: when you need to upgrade for another reason
- ✅ Migrate during the deprecation period
- ✅ Treat a new deprecation warning like a failing test: fix it in the same change that introduced it

### 2. Use Version Constraints

Pin providers so a major version (the one that *removes* deprecated features) never arrives unannounced:

```hcl
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7" # any 3.x from 3.7, never 4.0
    }
  }
}
```

Then upgrade major versions deliberately, with a clean plan (no deprecation warnings) as the starting point.

### 3. Read the Upgrade Guides

Before a major provider upgrade, read the provider's changelog and upgrade guide. Deprecations you've already migrated won't break; the guide tells you what else changes.

### 4. Automate Detection

Fail CI when a plan has deprecation warnings. Use JSON output: the human-readable output folds warnings together, and the headings vary ("Attribute Deprecated", "Deprecated", "Deprecated value used"), which makes `grep` fragile.

```yaml
# .github/workflows/terraform.yml
name: Terraform Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.16.4
          terraform_wrapper: false # raw JSON output for jq

      - run: terraform init

      - name: Fail on deprecation warnings
        run: |
          terraform plan -json > plan.jsonl
          jq -r 'select(.type == "diagnostic" and .diagnostic.severity == "warning")
                 | select(.diagnostic.summary | test("deprecat"; "i"))
                 | "\(.diagnostic.summary): \(.diagnostic.range.filename // "?"):\(.diagnostic.range.start.line // "?")"' plan.jsonl > deprecations.txt
          if [ -s deprecations.txt ]; then
            cat deprecations.txt
            exit 1
          fi
```

---

## 🔧 Practical Exercises

### Exercise 1: Read the Warnings

1. Run `terraform apply` in `example/`
2. For each warning, write down: what is deprecated, and what the provider says to use instead
3. Run the `jq` command from [above](#and-2-more-similar-warnings-elsewhere) and compare the count with what the normal output shows

### Exercise 2: Migrate Without Changes

1. Note the output of `terraform output vm_names`
2. Migrate `main.tf` (without looking at `solution/`)
3. `terraform plan` must show no warnings and no changes, and `terraform output vm_names` must be unchanged

### Exercise 3: Find Deprecations Before They Warn

Deprecated things you don't use yet don't warn. List everything deprecated in the providers you use:

```bash
terraform providers schema -json | jq -r '
  .provider_schemas | to_entries[] | .key as $p
  | (.value.resource_schemas // {}) + (.value.data_source_schemas // {}) | to_entries[] | .key as $r
  | (if .value.block.deprecated then "\($p) \($r) (whole resource)" else empty end),
    (.value.block.attributes // {} | to_entries[] | select(.value.deprecated) | "\($p) \($r).\(.key)")'
```

---

## 📖 Additional Resources

- [Provider Deprecation Guidelines](https://developer.hashicorp.com/terraform/plugin/best-practices/deprecations)
- [Terraform Upgrade Guides](https://developer.hashicorp.com/terraform/language/upgrade-guides)
- [random provider changelog](https://github.com/hashicorp/terraform-provider-random/blob/main/CHANGELOG.md)
- [`terraform_data` resource](https://developer.hashicorp.com/terraform/language/resources/terraform-data) — the replacement for `null_resource` and `null_data_source`

---

## 🎓 Key Takeaways

1. **Deprecation warnings are deadlines**, not noise
2. **Provider messages** (1.15+) tell you the replacement; "Deprecated value used" tells you everywhere it matters
3. **A good migration changes code, not infrastructure**: aim for "No changes"
4. **Detect warnings with `-json`** in CI, not with `grep`

---

## ✅ Section Checklist

- [ ] Identify deprecation warnings in `terraform plan` output
- [ ] Follow a "Deprecated value used" warning to its origin
- [ ] Migrate a deprecated argument and a deprecated data source
- [ ] Verify a migration with a clean plan and unchanged outputs
- [ ] Detect deprecation warnings in CI

---

## 🔜 Next Steps

Continue to **TF-303** for the Terraform test framework.

# TF-307: List Resources, terraform query & Actions

**Course**: TF-300 Testing, Validation & Policy  
**Module**: TF-307  
**Duration**: 1.5 hours  
**Prerequisites**: TF-306 (Functions Deep Dive), TF-204 (Import & Migration)  
**Difficulty**: Advanced  
**Terraform Version**: 1.14+ (both features GA in 1.14); destroy-time triggers, `on_failure` and `caller` require **1.16+**

---

## 📋 Table of Contents

1. [Overview](#-overview)
2. [Part 1: List Resources & terraform query](#-part-1-list-resources--terraform-query)
   - [What Are List Resources?](#what-are-list-resources)
   - [The `.tfquery.hcl` File](#the-tfqueryhcl-file)
   - [The `terraform query` Command](#the-terraform-query-command)
   - [Generating Import Configuration](#generating-import-configuration)
   - [Hands-On: Discovering Unmanaged Resources](#hands-on-discovering-unmanaged-resources)
3. [Part 2: Actions](#-part-2-actions)
   - [What Are Actions?](#what-are-actions)
   - [Action Syntax](#action-syntax)
   - [Triggering Actions from Resources](#triggering-actions-from-resources)
   - [The `caller` Symbol (1.16+)](#the-caller-symbol-116)
   - [Handling Failures with `on_failure` (1.16+)](#handling-failures-with-on_failure-116)
   - [Manual Invocation](#manual-invocation)
   - [Actions vs local-exec vs terraform_data](#actions-vs-local-exec-vs-terraform_data)
   - [Hands-On: Actions with the local Provider](#hands-on-actions-with-the-local-provider)
   - [Real-World Examples: AWS Actions](#real-world-examples-aws-actions)
4. [Checkpoint Quiz](#-checkpoint-quiz)
5. [Additional Resources](#-additional-resources)

---

## 🎯 Overview

Terraform 1.14 introduced two features that extend Terraform beyond the traditional create/read/update/delete (CRUD) lifecycle:

1. **List resources** (`*.tfquery.hcl`) + **`terraform query`**: Search existing infrastructure without managing it — for discovering unmanaged resources and generating import configuration in bulk.

2. **Actions**: Provider-defined operations that run outside the CRUD lifecycle — invoking a Lambda function, stopping an instance, running a local command — either triggered by resource lifecycle events or invoked manually.

Terraform 1.16 extended actions with **destroy-time triggers**, **`on_failure`** handling and the **`caller`** symbol.

Both features require **provider support**. Check your provider's documentation for the list resources and actions it implements.

**Examples in this module**:

| Directory | What it shows | Needs |
|-----------|---------------|-------|
| [`query-example/`](./query-example/) | `list` blocks, `terraform query` and bulk import | Docker (runs Moto, a local AWS mock) |
| [`example/`](./example/) | Actions with triggers, `caller`, `on_failure` and `-invoke` | Nothing — uses the `hashicorp/local` provider |

### Why Moto?

Everything else in this course runs on providers that need no account. `terraform query` is the exception: it only works with providers that implement *list resources*, and at the time of writing that's the big cloud providers (AWS, Azure, Google). None of the local providers (`local`, `random`, `docker`, `kubernetes`, `libvirt`, ...) implement one.

So Part 1 uses the real AWS provider against [Moto](https://github.com/getmoto/moto), an open-source server that imitates the AWS APIs. It runs in a Docker container on your machine, needs no AWS account, and costs nothing. Terraform can't tell the difference: the provider sends the same API calls it would send to AWS, just to `http://localhost:5000` instead.

What this means for you:
- ✅ The `list` blocks, `terraform query` and generated configuration are exactly what you'd get against real AWS
- ✅ Nothing you do can create a bill
- ⚠️ The provider block has a few Moto-only settings (fake keys, `endpoints`, `skip_*`). Remove them to point the same configuration at a real AWS account
- ⚠️ Moto keeps everything in memory. Restart the container and your "infrastructure" is gone

---

## 📋 Part 1: List Resources & terraform query

### What Are List Resources?

A **list resource** queries existing infrastructure **without managing it**. Unlike data sources, list resources return many results and exist specifically for discovery and bulk import.

Key characteristics:
- **Read-only**: List resources never create, update, or delete infrastructure
- **Not stored in state**: Results are computed each time you run `terraform query`
- **Provider-defined**: Providers implement list resources per resource type (the AWS provider 6.x implements over 200)
- **Identity-based**: By default each result is a [resource identity](https://developer.hashicorp.com/terraform/language/import#resource-identity) — the minimum needed to import it

### The `.tfquery.hcl` File

Queries live in files with the `.tfquery.hcl` extension in your root module directory. They are **ignored by `terraform plan` and `terraform apply`**.

A query file may contain **only** these blocks:
- `list`
- `provider`
- `variable`
- `locals`

> ⚠️ **No `terraform` block.** Provider requirements (`required_providers`) belong in your regular `.tf` configuration — the query file reuses them. Putting a `terraform {}` block in a `.tfquery.hcl` file is an error.

**`main.tf`** — the standard configuration:

```hcl
terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

**`discover.tfquery.hcl`** — the query:

```hcl
variable "environment_tag" {
  type    = string
  default = "prod"
}

list "aws_instance" "tagged" {
  provider = aws
  limit    = 50 # default is 100 results per list block

  config {
    filter {
      name   = "tag:Environment"
      values = [var.environment_tag]
    }
    filter {
      name   = "instance-state-name"
      values = ["running"]
    }
  }
}
```

### Structure of a `list` Block

```hcl
list "<TYPE>" "<LABEL>" {
  provider         = <provider>[.<alias>] # which provider configuration to use
  include_resource = false                # true = fetch all attributes, not just identity
  limit            = 100                  # maximum results (default 100)
  count            = <number>             # or for_each — not both

  config {
    # Provider-specific arguments — see your provider's docs for the list resource
  }
}
```

The key rule: **provider-specific arguments (like AWS `filter` blocks) go inside `config {}`**, while Terraform's own arguments (`provider`, `include_resource`, `limit`, `count`/`for_each`) sit at the top level.

### The `terraform query` Command

```bash
# Run every list block in the *.tfquery.hcl files
terraform query

# Machine-readable output for scripting
terraform query -json

# Pass values to variables declared in the query file
terraform query -var 'environment_tag=staging'
```

Each result shows the list block address (`list.aws_instance.tagged`) and the identity of the resource it found; providers may add a short description.

### Generating Import Configuration

`terraform query` can write `import` and `resource` blocks for everything it finds:

```bash
terraform query -generate-config-out=generated.tf
```

> 📝 **Docs erratum**: The Terraform 1.16 `terraform query` reference page shows this flag as `-generate-config`. That is wrong — both Terraform 1.16 and 1.17 only accept `-generate-config-out` (the bulk-import guide uses the correct name).

The target file must **not** already exist — delete it before running the command again.

The bulk-import workflow:

1. **Search**: write `list` blocks in a `.tfquery.hcl` file
2. **Generate**: `terraform query -generate-config-out=generated.tf`
3. **Import**: copy the `import` and `resource` blocks you want from `generated.tf` into your configuration, then run `terraform apply`
4. **Clean up**: delete `generated.tf`; remove the `import` blocks or keep them as a record of where the resources came from

> 💡 `terraform plan -generate-config-out=FILE` still exists too — it generates `resource` blocks for `import` blocks you wrote by hand (see [TF-204](../../TF-200-modules/TF-204-import-migration/README.md)). `terraform query` generates the `import` blocks as well.

### Comparison: List Resources vs Data Sources

| Feature | Data Source | List Resource |
|---------|------------|---------------|
| **Returns** | A single object (or one aggregate) | Many results |
| **Stored in state** | Yes (refreshed each plan) | No |
| **Used in plan/apply** | Yes | No (`terraform query` only) |
| **Purpose** | Reference existing infra | Discover infra to import |
| **File type** | `.tf` | `.tfquery.hcl` |
| **Import generation** | No | Yes (`-generate-config-out`) |

### Hands-On: Discovering Unmanaged Resources

**Directory**: [`query-example/`](./query-example/)

**Step 1 — Start Moto** (see [Why Moto?](#why-moto)):

```bash
docker run -d --name moto -p 5000:5000 motoserver/moto:latest
```

**Step 2 — Create some "forgotten" infrastructure.** The `seed/` configuration plays the colleague who built things by hand: three EC2 instances (two tagged `Environment = prod`, one `dev`) and an S3 bucket. Deleting its state afterwards means no Terraform configuration manages them any more:

```bash
cd query-example/seed
terraform init
terraform apply
rm terraform.tfstate*
cd ..
```

**Step 3 — Discover them**:

```bash
terraform init
terraform validate -query   # -query also validates *.tfquery.hcl files
terraform query
# list.aws_s3_bucket.all      account_id=,bucket=legacy-logs,region=us-east-1   legacy-logs
# list.aws_instance.tagged    account_id=,id=i-92932b16a6a4429e0,region=us-east-1   web-0 (i-92932b16a6a4429e0)
# list.aws_instance.tagged    account_id=,id=i-b49a9900a2b0d36b3,region=us-east-1   web-1 (i-b49a9900a2b0d36b3)

terraform query -var 'environment_tag=dev'   # now only "sandbox"
```

Each result is a **resource identity**: the handful of values needed to import it (`account_id` is empty because Moto doesn't have a real account).

**Step 4 — Generate import configuration**:

```bash
terraform query -generate-config-out=generated.tf
terraform plan
```

The plan fails:

```
Error: Conflicting configuration arguments
  on generated.tf line 47, in resource "aws_instance" "tagged_0":
  "ipv6_address_count": conflicts with ipv6_addresses
```

This is not a Moto quirk; you'd get the same against real AWS. Generated configuration writes out *every* attribute the provider reads back, including pairs you're only allowed to set one of. In each `aws_instance` block in `generated.tf`, delete:
- `ipv6_address_count` and `ipv6_addresses`
- the whole `primary_network_interface { ... }` block

**Step 5 — Import**:

```bash
terraform plan
# Plan: 3 to import, 0 to add, 2 to change, 0 to destroy.
```

Look at the "2 to change": the only differences are `user_data_replace_on_change` and `timeouts`, settings that exist only in Terraform. Nothing about the instances themselves changes.

```bash
terraform apply
terraform plan
# No changes. Your infrastructure matches the configuration.
```

The three resources are now managed by this configuration. In a real project you'd move the blocks from `generated.tf` into your own files, give them better names than `tagged_0`, and delete what you don't need.

**Exercise 1**: Break the query on purpose and read the errors:
- Move a `filter` block out of `config {}` to the top level of the `list` block
- Add a `terraform { required_version = ">= 1.14" }` block to `discover.tfquery.hcl`

**Exercise 2**: Add `include_resource = true` to the `tagged` list block and run `terraform query -json`. What extra information do you get, and why is it off by default?

**Clean up**: `docker rm -f moto` (Moto keeps everything in memory, so that's all there is to it).

---

## ⚡ Part 2: Actions

### What Are Actions?

An **action** is a provider-defined operation that runs outside the CRUD lifecycle. Actions don't create anything in state — they *do* something:
- Invoke a Lambda function after it's deployed
- Publish an SNS notification when infrastructure changes
- Back up a DynamoDB table before it is destroyed (1.16+)
- Invalidate a CloudFront cache after a deploy
- Run a local command (`hashicorp/local` provider)

AWS provider 6.x ships actions such as `aws_lambda_invoke`, `aws_sns_publish`, `aws_cloudfront_create_invalidation`, `aws_ec2_stop_instance`, `aws_dynamodb_create_backup` and `aws_codebuild_start_build`.

### Action Syntax

```hcl
action "<TYPE>" "<LABEL>" {
  provider = <provider>.<alias> # optional
  count    = <number>           # optional — or for_each

  config {
    # Provider-specific arguments — see your provider's docs
  }
}
```

The action block only **declares** the operation. Nothing runs until either:
1. a resource's `lifecycle { action_trigger { ... } }` fires it, or
2. you invoke it manually with `-invoke`.

### Triggering Actions from Resources

Triggers are declared **on the resource**, inside its `lifecycle` block — not on the action:

```hcl
resource "local_file" "service_config" {
  # ...

  lifecycle {
    action_trigger {
      events    = [after_create, after_update]
      condition = var.environment == "prod" # optional
      actions   = [action.local_command.audit_deploy]
    }
  }
}
```

| Argument | Required | Description |
|----------|----------|-------------|
| `events` | Yes | Lifecycle events that fire the actions |
| `actions` | Yes | Ordered list of actions to invoke |
| `condition` | No | Expression that must be `true` for the actions to run |
| `on_failure` | No (1.16+) | `halt` (default), `continue` or `taint` |

A resource can have several `action_trigger` blocks — for example one for deploy events and one for destroy events.

### Available Events

| Event | When it fires | Version |
|-------|---------------|---------|
| `before_create` | Before Terraform creates the resource | 1.14+ |
| `after_create` | After Terraform creates the resource | 1.14+ |
| `before_update` | Before Terraform updates the resource in place | 1.14+ |
| `after_update` | After Terraform updates the resource in place | 1.14+ |
| `before_destroy` | Before Terraform destroys the resource | **1.16+** |
| `after_destroy` | After Terraform destroys the resource | **1.16+** |

> ⚠️ **There is no `after_apply` event.** To run after any change, list `[after_create, after_update]`.

> 💡 **Replacement = destroy + create.** When a change forces replacement (like changing a `local_file`'s content), Terraform fires the `*_destroy` and `*_create` events — **not** `*_update`. You'll see this in the hands-on.

### The `caller` Symbol (1.16+)

Inside an action's `config` block, `caller` refers to **the resource instance whose `action_trigger` invoked the action**. One action can then serve every instance of a `for_each` resource:

```hcl
resource "local_file" "service_config" {
  for_each = var.services
  filename = "${local.out_dir}/${each.key}.conf"
  # ...

  lifecycle {
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.local_command.audit_deploy]
    }
  }
}

action "local_command" "audit_deploy" {
  config {
    command   = "sh"
    arguments = ["-c", "echo \"deployed $1\" >> out/audit.log", "sh", caller.filename]
  }
}
```

Without `caller` you would need one action per instance, each referencing `local_file.service_config["api"]`, `local_file.service_config["worker"]`, and so on.

`caller` is only available when a trigger invokes the action. An action you only invoke manually must reference resources directly.

> ⚠️ If a triggered action references its triggering resource by name (e.g. `aws_lambda_function.api.function_name`), Terraform 1.16 warns: *"The triggering resource object can be accessed via the "caller" symbol to avoid unexpected graph cycles."* Use `caller` instead.

### Handling Failures with `on_failure` (1.16+)

| Value | Behavior |
|-------|----------|
| `halt` | **Default.** Stop the apply and report an error. The resource is not tainted. |
| `continue` | Log the error as a warning and keep applying. |
| `taint` | Stop the apply, report an error, and taint the resource so the next apply replaces it. |

```hcl
lifecycle {
  action_trigger {
    events     = [before_destroy]
    actions    = [action.local_command.backup_config]
    on_failure = continue # a failed backup must not block the destroy
  }
}
```

Choosing a value:
- **`halt`** — the action is a gate (e.g. a smoke test must pass)
- **`continue`** — the action is best-effort (notifications, logging)
- **`taint`** — a failed action means the resource itself is broken (e.g. a post-create bootstrap)

### Manual Invocation

Run a single action without applying anything else:

```bash
# Preview: Terraform plans ONLY the action and excludes everything else
terraform plan -invoke=action.local_command.health_check

# Run it
terraform apply -invoke=action.local_command.health_check

# Actions with count/for_each: address one instance
terraform apply -invoke='action.aws_lambda_invoke.warm_up["eu"]'
```

Use `-invoke` for:
- One-off operational tasks (health checks, cache invalidation)
- Testing an action before wiring it to a trigger

> 📝 `-invoke` works for CLI-driven workspaces. Terraform Stacks do not support it — use `action_trigger` there.

### Actions vs local-exec vs terraform_data

| Feature | `local-exec` provisioner | `terraform_data` + provisioner | Actions |
|---------|--------------------------|--------------------------------|---------|
| **Defined by** | Terraform core | Terraform core | The provider |
| **Trigger** | Resource create (or destroy with `when = destroy`) | `triggers_replace` changes | `action_trigger` events + `condition` |
| **Manual invocation** | No | No (only via `-replace`) | Yes (`-invoke`) |
| **Visible in plan** | No | As a resource replacement | Yes — listed as actions to invoke |
| **Failure control** | `on_failure = continue/fail` | `on_failure = continue/fail` | `on_failure = halt/continue/taint` |
| **Use case** | Legacy glue scripts | Glue scripts tied to value changes | Provider operations and day-2 tasks |

> **Migration path**: Prefer an action when your provider implements one for the operation. For arbitrary local scripts, the `hashicorp/local` provider's `local_command` action gives you plan visibility and `-invoke`; `local-exec` and `terraform_data` remain valid.

### Hands-On: Actions with the local Provider

**Directory**: [`example/`](./example/) — no cloud credentials needed.

The example writes one config file per service and wires three `local_command` actions to them. Every action appends a line to `out/audit.log`, so you can see exactly when each one ran.

| Action | Invoked by | Shows |
|--------|-----------|-------|
| `audit_deploy` | `after_create`, `after_update` | `caller` reused across `for_each` instances |
| `backup_config` | `before_destroy` + `on_failure = continue` | 1.16 destroy-time triggers |
| `health_check` | Manual only (`-invoke`) | Actions without triggers |

**Step 1 — Create**:
```bash
cd example
terraform init
terraform plan    # note the "Actions to be invoked" section for each file
terraform apply
cat out/audit.log
# 2026-...Z deployed ./out/api.conf
# 2026-...Z deployed ./out/worker.conf
```

**Step 2 — Change the content**:
```bash
terraform apply -var app_version=1.1.0
cat out/audit.log
```
❓ Why did you get `backed up` + `deployed` lines, not an update? (Hint: `local_file` content changes force replacement — see [Available Events](#available-events).)

**Step 3 — Invoke manually**:
```bash
terraform plan  -var app_version=1.1.0 -invoke=action.local_command.health_check
terraform apply -var app_version=1.1.0 -invoke=action.local_command.health_check
tail -1 out/audit.log   # health check passed
```

**Step 4 — Destroy**:
```bash
terraform destroy -var app_version=1.1.0
ls out/   # the *.bak files were written by the before_destroy action
```

**Step 5 — Experiment with `on_failure`**:
1. Change `backup_config` so it always fails: replace the command string with `"exit 1"`.
2. Run `terraform apply` then `terraform destroy`. The destroy succeeds with a warning (`continue`).
3. Change `on_failure` to `halt` and repeat. The destroy now stops with an error.
4. Try `taint` on the `after_create` trigger with a failing `audit_deploy`, then run `terraform plan` — the file is marked for replacement.

**Step 6 — Run the tests**:
```bash
terraform test
```

### Real-World Examples: AWS Actions

These snippets use actions that exist in AWS provider 6.x, to show what actions look like in a real cloud setup. You can try the SNS one for free against Moto: reuse the provider block from `query-example/`, add `sns = var.moto_endpoint` to its `endpoints`, create an `aws_sns_topic`, and run `terraform apply -invoke=action.aws_sns_publish.deployed`. The Lambda, DynamoDB and CloudFront examples haven't been tested against Moto.

**Warm up a Lambda function after every deploy**:

```hcl
resource "aws_lambda_function" "api" {
  # ...

  lifecycle {
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.aws_lambda_invoke.warm_up, action.aws_sns_publish.deployed]
    }
  }
}

action "aws_lambda_invoke" "warm_up" {
  config {
    function_name = caller.function_name
    payload       = jsonencode({ action = "warm_up" })
  }
}

action "aws_sns_publish" "deployed" {
  config {
    topic_arn = aws_sns_topic.deployments.arn
    subject   = "Deployment complete"
    message   = "Deployed ${caller.function_name} version ${caller.version}"
  }
}
```

**Back up a DynamoDB table before it is destroyed (1.16+)**:

```hcl
resource "aws_dynamodb_table" "orders" {
  # ...

  lifecycle {
    action_trigger {
      events     = [before_destroy]
      actions    = [action.aws_dynamodb_create_backup.final]
      on_failure = halt # never destroy the table without a backup
    }
  }
}

action "aws_dynamodb_create_backup" "final" {
  config {
    table_name  = caller.name
    backup_name = "${caller.name}-final"
  }
}
```

**Invalidate the CDN cache on demand**:

```hcl
action "aws_cloudfront_create_invalidation" "cache_bust" {
  config {
    distribution_id = aws_cloudfront_distribution.main.id
    paths           = ["/*"]
  }
}
```

```bash
terraform apply -invoke=action.aws_cloudfront_create_invalidation.cache_bust
```

---

## 📝 Checkpoint Quiz

### Question 1: List Resources
**What is the primary purpose of list resources?**

A) To replace data sources for all use cases  
B) To discover existing infrastructure for bulk import  
C) To create multiple resources with a single block  
D) To list all resources in the Terraform state

<details>
<summary>Click to reveal answer</summary>

**Answer: B) To discover existing infrastructure for bulk import**

List resources search existing infrastructure without managing it. `terraform query` evaluates them, not `terraform plan/apply`.
</details>

---

### Question 2: Query Files
**Which of these blocks is NOT allowed in a `.tfquery.hcl` file?**

A) `list`  
B) `variable`  
C) `terraform`  
D) `provider`

<details>
<summary>Click to reveal answer</summary>

**Answer: C) `terraform`**

Query files may contain only `list`, `provider`, `variable` and `locals` blocks. Provider requirements come from the `terraform` block in your `.tf` configuration.
</details>

---

### Question 3: terraform query flag
**Which flag makes `terraform query` write import configuration to a file?**

A) `-import`  
B) `-generate-config-out=<file>`  
C) `-out=<file>`  
D) `-export`

<details>
<summary>Click to reveal answer</summary>

**Answer: B) `-generate-config-out=<file>`**

```bash
terraform query -generate-config-out=generated.tf
```

The file must not already exist. It contains `import` and `resource` blocks for every result.
</details>

---

### Question 4: Where Triggers Live
**Where do you declare that an action should run after a resource is created?**

A) In a `triggers` map inside the `action` block  
B) In an `action_trigger` block inside the resource's `lifecycle` block  
C) In a `provisioner` block  
D) With a `depends_on` on the action

<details>
<summary>Click to reveal answer</summary>

**Answer: B) In an `action_trigger` block inside the resource's `lifecycle` block**

```hcl
lifecycle {
  action_trigger {
    events  = [after_create]
    actions = [action.aws_lambda_invoke.warm_up]
  }
}
```

The `action` block holds only the provider configuration (`config {}`) and meta-arguments.
</details>

---

### Question 5: caller
**An action is triggered by a resource with `for_each` over three keys. How does the action know which instance triggered it?**

A) It can't — you need three separate action blocks  
B) Through `each.key` inside the action  
C) Through the `caller` symbol, which refers to the triggering resource instance  
D) Through `self`

<details>
<summary>Click to reveal answer</summary>

**Answer: C) Through the `caller` symbol**

Since Terraform 1.16, `caller` is available in an action's `config` block when the action is invoked by an `action_trigger`. One action block can therefore serve every instance.
</details>

---

### Question 6: on_failure
**A `before_destroy` action sends a notification. You don't want a notification outage to block destroys. Which `on_failure` value do you use?**

A) `halt`  
B) `continue`  
C) `taint`  
D) `ignore`

<details>
<summary>Click to reveal answer</summary>

**Answer: B) `continue`**

`continue` logs the failure as a warning and carries on. `halt` (the default) would stop the apply; `taint` also stops and marks the resource for replacement.
</details>

---

### Question 7: Manual Invocation
**How do you run only the `health_check` action of type `local_command`?**

A) `terraform invoke action.local_command.health_check`  
B) `terraform apply -invoke=action.local_command.health_check`  
C) `terraform run action.local_command.health_check`  
D) `terraform action local_command.health_check`

<details>
<summary>Click to reveal answer</summary>

**Answer: B) `terraform apply -invoke=action.local_command.health_check`**

`-invoke` plans and runs only that action — every other change in the configuration is excluded. Use `terraform plan -invoke=...` to preview it.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [Import resources in bulk](https://developer.hashicorp.com/terraform/language/import/bulk)
- [`list` block reference](https://developer.hashicorp.com/terraform/language/block/tfquery/list)
- [Query configuration files](https://developer.hashicorp.com/terraform/language/files/tfquery)
- [terraform query command](https://developer.hashicorp.com/terraform/cli/commands/query)
- [Invoke an action](https://developer.hashicorp.com/terraform/language/invoke-actions)
- [`action` block reference](https://developer.hashicorp.com/terraform/language/block/action)
- [`lifecycle` meta-argument (action_trigger)](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle)

### Related Courses
- **Previous**: [TF-306: Functions Deep Dive](../TF-306-functions/README.md)
- **Related**: [TF-204: Import & Migration](../../TF-200-modules/TF-204-import-migration/README.md) — import blocks and migration strategies
- **Related**: [TF-101: Intro & Basics](../../TF-100-fundamentals/TF-101-intro-basics/README.md) — `terraform_data` and `local-exec` (compare with actions)

### Provider Support
- [hashicorp/local](https://registry.terraform.io/providers/hashicorp/local/latest/docs) — `local_command` action (2.6.0+)
- [hashicorp/aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) — list resources and actions; look for the "List Resources" and "Actions" sections in the docs navigation

---

*Part of the [Hashi-Training](../../README.md) curriculum — TF-300: Testing, Validation & Policy*

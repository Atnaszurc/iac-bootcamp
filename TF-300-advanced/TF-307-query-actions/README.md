# TF-307: List Resources, terraform query & Actions

**Course**: TF-300 Testing, Validation & Policy  
**Module**: TF-307  
**Duration**: 1.5 hours  
**Prerequisites**: TF-306 (Functions Deep Dive), TF-204 (Import & Migration)  
**Difficulty**: Advanced  
**Terraform Version**: 1.14+ (both features GA in 1.14)

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Part 1: List Resources & terraform query](#part-1-list-resources--terraform-query)
   - [What Are List Resources?](#what-are-list-resources)
   - [The `.tfquery.hcl` File](#the-tfqueryhcl-file)
   - [The `terraform query` Command](#the-terraform-query-command)
   - [Generating Import Configuration](#generating-import-configuration)
   - [Hands-On: Discovering Unmanaged Resources](#hands-on-discovering-unmanaged-resources)
3. [Part 2: Actions Block](#part-2-actions-block)
   - [What Are Actions?](#what-are-actions)
   - [Actions vs local-exec vs null_resource](#actions-vs-local-exec-vs-null_resource)
   - [Action Triggers](#action-triggers)
   - [Manual Invocation](#manual-invocation)
   - [Hands-On: Using Actions](#hands-on-using-actions)
4. [Checkpoint Quiz](#checkpoint-quiz)
5. [Additional Resources](#additional-resources)

---

## 🎯 Overview

Terraform 1.14 introduced two significant new features that expand what Terraform can do beyond the traditional create/read/update/delete (CRUD) lifecycle:

1. **List Resources** (`*.tfquery.hcl`) + **`terraform query`**: Query existing infrastructure without managing it — useful for discovering unmanaged resources and generating import configurations.

2. **Actions block**: Provider-defined imperative operations that run outside the normal CRUD lifecycle — useful for operations like invoking a Lambda function, restarting a service, or triggering a deployment.

Both features require **provider support** — not all providers implement them yet. Check your provider's documentation to see which resources support list resources and actions.

---

## 📋 Part 1: List Resources & terraform query

### What Are List Resources?

A **list resource** is a new resource type (alongside `resource`, `data`, and `ephemeral`) that queries existing infrastructure **without managing it**. Unlike data sources, list resources can return multiple results and are designed specifically for discovery and import workflows.

Key characteristics:
- **Read-only**: List resources never create, update, or delete infrastructure
- **Not stored in state**: Results are computed at query time, not persisted
- **Provider-defined**: Providers must implement list resources for their resource types
- **Used with `terraform query`**: The `terraform query` command evaluates list resources

### The `.tfquery.hcl` File

List resources are defined in files with the `.tfquery.hcl` extension. These files are **separate from your main Terraform configuration** — they don't affect `terraform plan` or `terraform apply`.

```hcl
# example.tfquery.hcl

# List all EC2 instances in the account (provider must support this)
list "aws_instance" "all_instances" {
  # Optional: filter criteria (provider-defined)
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# List all S3 buckets
list "aws_s3_bucket" "all_buckets" {
  # No filter — list all buckets
}
```

### Structure of a `.tfquery.hcl` File

```hcl
# The list block syntax:
list "<resource_type>" "<name>" {
  # Provider-defined filter arguments (optional)
  # These vary by resource type and provider
}
```

The file must also have a `terraform` block with provider requirements (or inherit from the main configuration):

```hcl
# query.tfquery.hcl

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
  region = "us-east-1"
}

# List all EC2 instances tagged with Environment=prod
list "aws_instance" "prod_instances" {
  filter {
    name   = "tag:Environment"
    values = ["prod"]
  }
}
```

### The `terraform query` Command

```bash
# Run all list resources in .tfquery.hcl files
terraform query

# Output is a JSON-like summary of discovered resources
# Example output:
# list.aws_instance.prod_instances:
#   i-0abc123def456789a (t3.medium, us-east-1a)
#   i-0def456abc789012b (t3.large, us-east-1b)
```

#### Flags

```bash
# Generate import blocks for discovered resources
terraform query -generate-config-out=imported.tf

# Output in JSON format (for scripting)
terraform query -json

# Target a specific list resource
terraform query -target=list.aws_instance.prod_instances
```

### Generating Import Configuration

The most powerful use of `terraform query` is generating import configuration for unmanaged resources:

```bash
# Step 1: Define what to discover in a .tfquery.hcl file
# (see example above)

# Step 2: Run query to discover resources
terraform query

# Step 3: Generate import blocks + resource stubs
terraform query -generate-config-out=imported.tf

# Step 4: Review the generated file
cat imported.tf
```

The generated `imported.tf` will contain:

```hcl
# Auto-generated by terraform query -generate-config-out
# Review and adjust before running terraform apply

import {
  to = aws_instance.prod_instances_0
  id = "i-0abc123def456789a"
}

resource "aws_instance" "prod_instances_0" {
  # (populated by terraform plan after import)
}

import {
  to = aws_instance.prod_instances_1
  id = "i-0def456abc789012b"
}

resource "aws_instance" "prod_instances_1" {
  # (populated by terraform plan after import)
}
```

```bash
# Step 5: Run plan to populate resource configurations
terraform plan -generate-config-out=resources.tf

# Step 6: Review and clean up generated resources
# Step 7: Apply to bring resources under management
terraform apply
```

### Comparison: List Resources vs Data Sources

| Feature | Data Source | List Resource |
|---------|------------|---------------|
| **Returns** | Single result | Multiple results |
| **Stored in state** | No | No |
| **Used in plan/apply** | Yes | No (query only) |
| **Purpose** | Reference existing infra | Discover/enumerate infra |
| **Command** | `terraform plan/apply` | `terraform query` |
| **File type** | `.tf` | `.tfquery.hcl` |
| **Import generation** | No | Yes (`-generate-config-out`) |

### Hands-On: Discovering Unmanaged Resources

> **Note**: This exercise requires a provider that implements list resources. As of Terraform 1.14, provider support is still rolling out. Check your provider's changelog for list resource support.

**Conceptual Exercise** (no provider required):

1. **Scenario**: Your team has EC2 instances that were created manually (not via Terraform). You want to bring them under Terraform management.

2. **Create the query file**:

```hcl
# discover-ec2.tfquery.hcl

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

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# Discover all running EC2 instances not tagged as managed by Terraform
list "aws_instance" "unmanaged" {
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
  filter {
    name   = "tag:ManagedBy"
    values = ["!Terraform"]  # Instances NOT tagged as managed
  }
}
```

3. **Run the query**:
```bash
terraform query
```

4. **Generate import configuration**:
```bash
terraform query -generate-config-out=imported-instances.tf
```

5. **Review and apply**:
```bash
terraform plan -generate-config-out=instance-configs.tf
# Review generated configs, clean up, then:
terraform apply
```

---

## ⚡ Part 2: Actions Block

### What Are Actions?

An **action** is a provider-defined **imperative operation** that runs outside the normal Terraform CRUD lifecycle. Actions are for operations that:
- Don't fit the create/read/update/delete model
- Need to happen in response to resource changes
- Can be triggered manually or automatically

Examples of what actions enable:
- Invoke an AWS Lambda function after it's deployed
- Restart a service after configuration changes
- Trigger a database backup before destroying a resource
- Send a notification when infrastructure changes
- Run a health check after deployment

### What Are Actions?

```hcl
# Actions block syntax (Terraform 1.14+)
action "<provider_action_type>" "<name>" {
  # Provider-defined arguments

  # Trigger configuration
  triggers = {
    after_create = <resource_reference>
    after_update = <resource_reference>
    before_destroy = <resource_reference>
  }
}
```

### Actions vs local-exec vs null_resource

| Feature | `local-exec` provisioner | `null_resource` | Actions |
|---------|------------------------|-----------------|---------|
| **Runs on** | Local machine | Local machine | Provider-side |
| **Provider support** | Not needed | Not needed | **Required** |
| **Trigger control** | Resource lifecycle | `triggers` map | `triggers` block |
| **Manual invocation** | No | No | Yes (`-invoke`) |
| **State tracking** | No | Yes (null resource) | Yes |
| **Recommended** | Legacy | Legacy | Modern (1.14+) |
| **Use case** | Local scripts | Arbitrary triggers | Provider operations |

> **Migration path**: Actions are the modern replacement for many `null_resource` + `local-exec` patterns, but only when the provider implements the action. For local scripts, `local-exec` or `terraform_data` are still appropriate.

### Action Triggers

Actions can be triggered by resource lifecycle events:

```hcl
# Trigger after a resource is created or updated
action "aws_lambda_invoke" "warm_up" {
  function_name = aws_lambda_function.api.function_name
  payload       = jsonencode({ action = "warm_up" })

  triggers = {
    # Run after the Lambda function is created
    after_create = aws_lambda_function.api

    # Run after the Lambda function is updated
    after_update = aws_lambda_function.api
  }
}

# Trigger before a resource is destroyed
action "aws_rds_snapshot" "pre_destroy_backup" {
  db_instance_identifier = aws_db_instance.main.id
  snapshot_identifier    = "${aws_db_instance.main.id}-pre-destroy"

  triggers = {
    # Run before the RDS instance is destroyed
    before_destroy = aws_db_instance.main
  }
}
```

### Available Trigger Types

| Trigger | When it runs |
|---------|-------------|
| `after_create` | After the referenced resource is created |
| `after_update` | After the referenced resource is updated |
| `after_apply` | After any create or update of the referenced resource |
| `before_destroy` | Before the referenced resource is destroyed |

### Manual Invocation

Actions can also be invoked manually using the `-invoke` flag:

```bash
# Manually invoke a specific action
terraform apply -invoke=action.aws_lambda_invoke.warm_up

# Invoke multiple actions
terraform apply -invoke=action.aws_lambda_invoke.warm_up -invoke=action.aws_sns_publish.notify

# Invoke with auto-approve
terraform apply -invoke=action.aws_lambda_invoke.warm_up -auto-approve
```

This is useful for:
- Running one-off operations (database migrations, cache invalidation)
- Testing actions before enabling automatic triggers
- Operational tasks that don't fit the normal apply workflow

### Full Example: Lambda Deployment with Actions

```hcl
# main.tf

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

# Lambda function
resource "aws_lambda_function" "api" {
  function_name = "${var.project_name}-api"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  filename      = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

# Action: Warm up Lambda after deployment
# (provider must support aws_lambda_invoke action)
action "aws_lambda_invoke" "warm_up" {
  function_name = aws_lambda_function.api.function_name
  payload       = jsonencode({
    action = "warm_up"
    count  = 5
  })

  triggers = {
    # Automatically warm up after every create or update
    after_apply = aws_lambda_function.api
  }
}

# Action: Send deployment notification
action "aws_sns_publish" "deploy_notification" {
  topic_arn = aws_sns_topic.deployments.arn
  message   = "Lambda ${aws_lambda_function.api.function_name} deployed successfully"
  subject   = "Deployment Complete"

  triggers = {
    after_apply = aws_lambda_function.api
  }
}
```

```bash
# Normal apply — actions run automatically after Lambda is created/updated
terraform apply

# Manual warm-up (e.g., after a cold start issue)
terraform apply -invoke=action.aws_lambda_invoke.warm_up -auto-approve
```

### Example: Database Backup Before Destroy

```hcl
# Action: Take snapshot before destroying RDS instance
action "aws_rds_create_db_snapshot" "pre_destroy" {
  db_instance_identifier = aws_db_instance.main.id
  db_snapshot_identifier = "${aws_db_instance.main.id}-final-${formatdate("YYYYMMDD", timestamp())}"

  triggers = {
    before_destroy = aws_db_instance.main
  }
}
```

```bash
# When you run terraform destroy, the snapshot action runs first
terraform destroy
# Output:
# action.aws_rds_create_db_snapshot.pre_destroy: Running...
# action.aws_rds_create_db_snapshot.pre_destroy: Complete
# aws_db_instance.main: Destroying...
```

### Hands-On: Designing Actions

> **Note**: Actions require provider support. As of Terraform 1.14, provider support is rolling out. This exercise is conceptual — design the action configuration for your use case.

**Exercise**: Design actions for a web application deployment:

**Scenario**: You have an ECS service that needs to:
1. Run database migrations after the task definition is updated
2. Send a Slack notification after deployment
3. Invalidate a CloudFront cache after deployment

**Design the actions**:

```hcl
# 1. Database migration action
action "aws_ecs_run_task" "db_migrate" {
  cluster         = aws_ecs_cluster.main.arn
  task_definition = aws_ecs_task_definition.migrate.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs.id]
  }

  triggers = {
    # Run migrations after the app task definition is updated
    after_update = aws_ecs_task_definition.app
  }
}

# 2. Slack notification (via SNS → Lambda → Slack)
action "aws_sns_publish" "deploy_notify" {
  topic_arn = aws_sns_topic.deployments.arn
  message   = jsonencode({
    service     = aws_ecs_service.app.name
    environment = var.environment
    status      = "deployed"
  })

  triggers = {
    after_apply = aws_ecs_service.app
  }
}

# 3. CloudFront cache invalidation
action "aws_cloudfront_create_invalidation" "cache_bust" {
  distribution_id = aws_cloudfront_distribution.main.id
  paths           = ["/*"]

  triggers = {
    after_apply = aws_ecs_service.app
  }
}
```

---

## 📝 Checkpoint Quiz

### Question 1: List Resources
**What is the primary purpose of list resources in Terraform 1.14?**

A) To replace data sources for all use cases  
B) To discover and enumerate existing infrastructure for import workflows  
C) To create multiple resources with a single block  
D) To list all resources in the Terraform state

<details>
<summary>Click to reveal answer</summary>

**Answer: B) To discover and enumerate existing infrastructure for import workflows**

List resources query existing infrastructure without managing it. They are designed for discovery — finding unmanaged resources that you want to bring under Terraform management. They are evaluated by `terraform query`, not `terraform plan/apply`.
</details>

---

### Question 2: File Extension
**What file extension is used for list resource definitions?**

A) `.tf`  
B) `.tfvars`  
C) `.tfquery.hcl`  
D) `.tflist.hcl`

<details>
<summary>Click to reveal answer</summary>

**Answer: C) `.tfquery.hcl`**

List resources are defined in `.tfquery.hcl` files, which are separate from the main Terraform configuration (`.tf` files). They are only evaluated by `terraform query`.
</details>

---

### Question 3: terraform query flag
**Which flag generates import blocks from `terraform query` results?**

A) `-import`  
B) `-generate-config-out=<file>`  
C) `-out=<file>`  
D) `-export`

<details>
<summary>Click to reveal answer</summary>

**Answer: B) `-generate-config-out=<file>`**

```bash
terraform query -generate-config-out=imported.tf
```

This generates import blocks and resource stubs for all discovered resources, which can then be used with `terraform plan` and `terraform apply` to bring them under management.
</details>

---

### Question 4: Actions
**What is the key difference between an Actions block and a `local-exec` provisioner?**

A) Actions run on the local machine; local-exec runs on the provider  
B) Actions are provider-defined operations; local-exec runs arbitrary local commands  
C) Actions are faster than local-exec  
D) There is no difference — they are equivalent

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Actions are provider-defined operations; local-exec runs arbitrary local commands**

Actions are implemented by the provider and run provider-side operations (like invoking a Lambda or creating a snapshot). `local-exec` runs arbitrary shell commands on the machine running Terraform. Actions require provider support; `local-exec` does not.
</details>

---

### Question 5: Manual Invocation
**How do you manually invoke an action named `warm_up` of type `aws_lambda_invoke`?**

A) `terraform invoke action.aws_lambda_invoke.warm_up`  
B) `terraform apply -invoke=action.aws_lambda_invoke.warm_up`  
C) `terraform run action.aws_lambda_invoke.warm_up`  
D) `terraform action aws_lambda_invoke.warm_up`

<details>
<summary>Click to reveal answer</summary>

**Answer: B) `terraform apply -invoke=action.aws_lambda_invoke.warm_up`**

The `-invoke` flag on `terraform apply` manually triggers a specific action without running a full apply. Multiple `-invoke` flags can be specified to run multiple actions.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [List Resources](https://developer.hashicorp.com/terraform/language/resources/syntax#list-resources)
- [terraform query command](https://developer.hashicorp.com/terraform/cli/commands/query)
- [Actions](https://developer.hashicorp.com/terraform/language/resources/syntax#actions)
- [terraform apply -invoke](https://developer.hashicorp.com/terraform/cli/commands/apply#invoke)

### Related Courses
- **Previous**: [TF-306: Functions Deep Dive](../TF-306-functions/README.md)
- **Related**: [TF-204: Import & Migration](../../TF-200-modules/TF-204-import-migration/README.md) — import blocks and migration strategies
- **Related**: [TF-101: Intro & Basics](../../TF-100-fundamentals/TF-101-intro-basics/README.md) — `terraform_data` and `local-exec` (compare with Actions)

### Provider Support
Both list resources and actions require provider support. Check these resources:
- [AWS Provider Changelog](https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md) — search for "list resource" and "action"
- [Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) — look for resources with "List" or "Action" sections

---

*Part of the [Hashi-Training](../../README.md) curriculum — TF-300: Testing, Validation & Policy*
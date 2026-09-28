# TF-405: Terraform Stacks

**Course**: TF-400 HCP Terraform & Enterprise Features  
**Module**: TF-405  
**Duration**: 1.5 hours  
**Prerequisites**: TF-401 (HCP Terraform Fundamentals), TF-402 (Remote Runs & VCS Integration)  
**Difficulty**: Expert  
**Terraform Version**: 1.13+ for the `terraform stacks` CLI (examples verified with 1.16.4 and 1.17.0-beta2)  
**Requires**: HCP Terraform to deploy. Writing, validating and testing a Stack works locally.

---

## 📋 Table of Contents

1. [HCP Terraform and Cost](#-hcp-terraform-and-cost)
2. [What Are Terraform Stacks?](#-what-are-terraform-stacks)
3. [Stacks vs Workspaces](#-stacks-vs-workspaces)
4. [Files of a Stack](#-files-of-a-stack)
5. [Components](#-components)
6. [Providers](#-providers)
7. [Deployments](#-deployments)
8. [The `terraform stacks` CLI](#-the-terraform-stacks-cli)
9. [Hands-On](#-hands-on)
10. [Building It Out](#-building-it-out)
11. [Deployment Groups and Auto-Approval](#-deployment-groups-and-auto-approval)
12. [Changes in Terraform 1.15 and 1.16](#-changes-in-terraform-115-and-116)
13. [When to Use Stacks](#-when-to-use-stacks)
14. [Checkpoint Quiz](#-checkpoint-quiz)
15. [Additional Resources](#-additional-resources)

---

## 💳 HCP Terraform and Cost

Stacks run in **HCP Terraform** (and in Terraform Enterprise). The `terraform stacks` CLI can write, format and validate a Stack on your machine, but only HCP Terraform plans and applies it.

HCP Terraform bills by **resources under management (RUM)**: every managed resource in state counts, in workspaces and Stacks alike. These don't count:

- `terraform_data` and `null_resource`
- data sources
- locals, variables and outputs

A Stack multiplies resources: every **deployment** has its own copy of every component. A Stack with 3 components of 10 resources each, deployed to 5 environments, is 150 resources.

That's why the example in this module is deliberately tiny: **one billable resource per deployment** (a `random_pet`), everything else `terraform_data`, and two deployments. **2 resources under management in total**, and no cloud account needed. You add real infrastructure yourself in [Building It Out](#-building-it-out), knowing what each addition costs.

> **Tiers**: According to HCP Terraform's documentation, Stacks are available on every edition, including Free (which is limited to 500 managed resources). Auto-approval rules for deployment groups need the Premium edition. Pricing changes; check the [pricing page](https://www.hashicorp.com/products/terraform/pricing) for your organisation.

---

## 🎯 What Are Terraform Stacks?

A **Stack** deploys a set of Terraform modules (**components**) together, as one unit, and repeats that unit as many times as you need (**deployments**): per environment, region or account.

Without Stacks, deploying the same infrastructure to dev and prod means:

- a workspace (or a configuration) per environment, sometimes per piece of infrastructure
- passing outputs from one workspace to the next yourself (`terraform_remote_state`, run triggers)
- a pipeline that applies things in the right order

With a Stack:

- **one configuration** describes the components and how they connect
- **deployments** say where and how often to deploy it, each with its own isolated state
- HCP Terraform works out the order from the references between components
- a change to the configuration creates a plan for **every** deployment

---

## 🔄 Stacks vs Workspaces

| | Workspaces | Stacks |
|---|---|---|
| **Unit** | One root module | Several components (modules) together |
| **Repeat for environments** | One workspace per environment | One deployment per environment, same configuration |
| **Passing values between parts** | Remote state, run triggers | Component references: `component.naming.prefix` |
| **Order of applies** | You arrange it | Inferred from references |
| **State** | One per workspace | One per deployment |
| **Where it runs** | Locally, any backend, or HCP Terraform | HCP Terraform (and Terraform Enterprise) |
| **Policies** | Sentinel, OPA, Terraform policy | Terraform policy only (see TF-304) |
| **Complexity** | Low | Higher |

**Choose workspaces** for a single configuration, or when you don't use HCP Terraform.
**Choose Stacks** when several pieces must be deployed together, repeatedly, and you're tired of wiring workspaces together.

---

## 📄 Files of a Stack

| File | What it holds |
|---|---|
| `*.tfcomponent.hcl` | The **component configuration**: `required_providers`, `provider`, `variable`, `component`, `output`, `locals`, `removed`. Replaces the root module. Split it over as many files as you like. |
| `*.tfdeploy.hcl` | The **deployment configuration**: `deployment`, `deployment_group`, `deployment_auto_approve`, `identity_token`, `store`, `publish_output`, `upstream_input`, `locals` |
| `.terraform-version` | The Terraform version HCP Terraform uses for this Stack. Required. |
| `.terraform.lock.hcl` | Provider lock file. Required: a Stack can't run without it. Commit it. |
| `components/*/` | Ordinary Terraform modules, one per component |

> **Older material uses `.tfstack.hcl`.** That was the extension during the Stacks beta. Since general availability, Stacks only read `.tfcomponent.hcl`; a `.tfstack.hcl` file is ignored. The beta's separate `tfstacks` CLI is replaced by `terraform stacks`, and `orchestrate` blocks by deployment groups. See [Update from beta to GA](https://developer.hashicorp.com/terraform/language/stacks/update-GA).

The example:

```
example/
├── .terraform-version            # 1.16.4
├── .terraform.lock.hcl           # generated by terraform stacks providers-lock
├── variables.tfcomponent.hcl     # environment, owner, replicas
├── providers.tfcomponent.hcl     # random + the built-in terraform provider
├── components.tfcomponent.hcl    # naming → app
├── outputs.tfcomponent.hcl       # prefix, instances
├── deployments.tfdeploy.hcl      # dev, prod
└── components/
    ├── naming/                   # random_pet: 1 billable resource
    │   ├── main.tf
    │   └── tests/naming.tftest.hcl
    └── app/                      # terraform_data: 0 billable resources
        ├── main.tf
        └── tests/app.tftest.hcl
```

---

## 🧩 Components

A `component` block turns a module into part of the Stack: its source, its inputs, and the providers it gets.

```hcl
# components.tfcomponent.hcl

component "naming" {
  source = "./components/naming"

  inputs = {
    environment = var.environment
  }

  providers = {
    random = provider.random.this
  }
}

component "app" {
  source = "./components/app"

  # Referencing another component's output creates the dependency:
  # naming is planned and applied first.
  inputs = {
    name_prefix = component.naming.prefix
    environment = var.environment
    owner       = var.owner
    replicas    = var.replicas
  }

  providers = {
    terraform = provider.terraform.this
  }
}
```

- **`inputs`** set the module's variables. `var.*` here are the Stack's variables (from `variables.tfcomponent.hcl`), which each deployment sets.
- **`component.<name>.<output>`** reads another component's output. There's no `depends_on`: the reference is the dependency.
- **The module itself** is a normal module: `variable`, `resource`, `output`. The only rule is that it doesn't configure providers (it may declare `required_providers`).
- `component` also supports `for_each`, for example one component instance per region.

Stack outputs work like root module outputs, but need a `type`:

```hcl
# outputs.tfcomponent.hcl

output "prefix" {
  type        = string
  description = "The name prefix of this deployment"
  value       = component.naming.prefix
}
```

---

## 🔌 Providers

Providers in a Stack are different from providers in a normal configuration:

```hcl
# providers.tfcomponent.hcl

required_providers {
  random = {
    source  = "hashicorp/random"
    version = "~> 3.7"
  }

  # The built-in provider that terraform_data belongs to. In a normal
  # configuration it's implicit; a Stack must declare it and pass it on.
  terraform = {
    source = "terraform.io/builtin/terraform"
  }
}

provider "random" "this" {
  config {}
}

provider "terraform" "this" {
  config {}
}
```

- **One `required_providers` block per Stack**, at the top level. A second one is an error; add new providers to the existing block.
- **The alias is in the block header**: `provider "random" "this"`. Components refer to it as `provider.random.this`.
- **Arguments go in a `config` block.** `random` has none, so `config {}` is empty; an AWS provider would put `region` and its authentication there.
- **Components get providers explicitly**, through `providers = { ... }`. Nothing is inherited.
- **`terraform_data` needs the built-in `terraform` provider**, declared and passed like any other. Without it, validation fails with *"The root module for component.app requires a provider configuration named "terraform" for provider "terraform.io/builtin/terraform""*. Most documentation examples don't mention it, because they only use cloud providers.
- `provider` blocks support `for_each`, for a provider configuration per region.

---

## 🚀 Deployments

```hcl
# deployments.tfdeploy.hcl

deployment "dev" {
  inputs = {
    environment = "dev"
    owner       = "platform"
  }
}

deployment "prod" {
  inputs = {
    environment = "prod"
    owner       = "platform"
    replicas    = 2
  }
}
```

Each `deployment` block is one copy of the whole Stack, with its own inputs and its own state. A Stack can have up to 20 deployments.

Other blocks in `.tfdeploy.hcl` files:

- **`identity_token`**: an OIDC token for a cloud provider, so no credentials are stored (see [Building It Out](#-building-it-out))
- **`store "varset"`**: read values from an HCP Terraform variable set
- **`deployment_group`** and **`deployment_auto_approve`**: auto-approval rules (see [Deployment Groups](#-deployment-groups-and-auto-approval))
- **`publish_output`** and **`upstream_input`**: pass values from one Stack to another in the same project
- **`destroy = true`** in a `deployment` block: destroy that deployment's infrastructure

---

## 💻 The `terraform stacks` CLI

The `terraform stacks` commands are part of the Terraform CLI since 1.13 (Terraform downloads a Stacks plugin the first time you use them).

**Local, no HCP Terraform needed:**

```bash
terraform stacks init            # download providers and modules
terraform stacks providers-lock  # write .terraform.lock.hcl (for HCP Terraform's linux_amd64 and your machine)
terraform stacks validate        # check the configuration
terraform stacks fmt             # format .tfcomponent.hcl and .tfdeploy.hcl files
```

**Against HCP Terraform** (after `terraform login`):

```bash
terraform stacks create -organization-name=ORG -project-name=PROJECT -stack-name=NAME
terraform stacks configuration upload   # upload this directory; starts a run per deployment
terraform stacks deployment-run list    # runs and their status
terraform stacks deployment-run approve-all-plans
terraform stacks list                   # Stacks in the organisation or project
```

The commands that target a Stack take `-organization-name`, `-project-name` and `-stack-name`, or read them from `TF_STACKS_ORGANIZATION_NAME`, `TF_STACKS_PROJECT_NAME` and `TF_STACKS_STACK_NAME`. You can also connect the Stack to a VCS repository instead of uploading.

There is no `terraform stacks plan` or `apply`: HCP Terraform plans every deployment when a configuration arrives, and applies what you approve.

---

## 🔬 Hands-On

### Part 1: Local (no HCP Terraform, no cost)

```bash
cd example

terraform stacks init
terraform stacks providers-lock
terraform stacks validate
# Success! Terraform Stacks configuration is valid and ready for use within HCP Terraform.
```

Components are ordinary modules, so you can test them the ordinary way:

```bash
cd components/app
terraform init
terraform test
# Success! 2 passed, 0 failed.
```

Now break things, one at a time, and run `terraform stacks validate` after each:

1. Remove the `providers` argument from `component "app"`. What does the error say, and why does `terraform_data` need a provider at all?
2. Rename `components.tfcomponent.hcl` to `components.tfstack.hcl` (the beta extension). What happens to `component.naming` references?
3. Add `provider "random" {}` to `components/naming/main.tf`.
4. In `deployments.tfdeploy.hcl`, set `environment = "qa"` for `dev`.

<details>
<summary>What you should see</summary>

1. *Missing required provider configuration*: the module uses `terraform_data`, which belongs to the built-in `terraform` provider, and in a Stack every provider is passed explicitly.
2. *Reference to undeclared component*: the file is no longer read, so `component "naming"` doesn't exist, and the outputs that reference it fail.
3. *Inline provider configuration not allowed*: a component module gets all its providers from the Stack. (You may also see an internal error about an "unconfigured provider" next to it; the inline provider is the cause.)
4. **Nothing**: `validate` passes. It checks the configuration, not the values deployments pass in. The `validation` rule on `var.environment` is checked when HCP Terraform plans the deployment. Local validation isn't a substitute for looking at the plans.

</details>

### Part 2: Deploy to HCP Terraform (2 resources under management)

1. Log in and create the Stack (or create it in the UI: **Projects → New → Stack**):
   ```bash
   terraform login
   export TF_STACKS_ORGANIZATION_NAME=<your org>
   export TF_STACKS_PROJECT_NAME=<your project>
   export TF_STACKS_STACK_NAME=tf405
   terraform stacks create -organization-name=$TF_STACKS_ORGANIZATION_NAME \
     -project-name=$TF_STACKS_PROJECT_NAME -stack-name=$TF_STACKS_STACK_NAME
   ```
2. Upload the configuration:
   ```bash
   terraform stacks configuration upload
   ```
3. In the HCP Terraform UI, open the Stack: there's a plan for `dev` and one for `prod`. Look at the order: `naming` first, then `app`. Approve both (or `terraform stacks deployment-run approve-all-plans`).
4. Look at each deployment's outputs: different prefixes, and `prod` has two instances.
5. Change `owner` for `prod` only, and upload again. Which deployments get a plan with changes? Which components change?
6. Check **Usage** in your organisation settings: the Stack adds 2 managed resources.

### Part 3: Clean up

Destroy the deployments **before** you delete the Stack; deleting a Stack leaves its resources behind, unmanaged.

1. Add `destroy = true` to both `deployment` blocks and upload. Approve the destroy plans.
2. Delete the Stack: the project's **Settings → Destruction and Deletion → Delete stack**.

---

## 🏗️ Building It Out

The example is small on purpose. Add real infrastructure deliberately, one resource at a time, and count what each addition costs you: **every billable resource times every deployment**.

### Example: an S3 bucket per deployment (+1 resource per deployment)

This needs an AWS account, and an IAM role that trusts HCP Terraform's OIDC tokens. The [Authenticate a Stack](https://developer.hashicorp.com/terraform/language/stacks/deploy/authenticate) page has a complete Terraform configuration that creates that role; run it once in a workspace or locally.

1. A new component, `components/bucket/main.tf`:
   ```hcl
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 6.0"
       }
     }
   }

   variable "name_prefix" {
     type = string
   }

   resource "aws_s3_bucket" "this" {
     bucket_prefix = "${var.name_prefix}-"
     force_destroy = true
   }

   output "bucket" {
     value = aws_s3_bucket.this.bucket
   }
   ```
2. Add `aws` to the **existing** `required_providers` block in `providers.tfcomponent.hcl`:
   ```hcl
     aws = {
       source  = "hashicorp/aws"
       version = "~> 6.0"
     }
   ```
3. A new file, `aws.tfcomponent.hcl`: the provider, its inputs, the component and an output:
   ```hcl
   variable "aws_region" {
     type    = string
     default = "eu-north-1"
   }

   variable "aws_role_arn" {
     type = string
   }

   variable "aws_token" {
     type      = string
     ephemeral = true
   }

   provider "aws" "this" {
     config {
       region = var.aws_region
       assume_role_with_web_identity {
         role_arn           = var.aws_role_arn
         web_identity_token = var.aws_token
       }
     }
   }

   component "bucket" {
     source = "./components/bucket"

     inputs = {
       name_prefix = component.naming.prefix
     }

     providers = {
       aws = provider.aws.this
     }
   }

   output "bucket" {
     type  = string
     value = component.bucket.bucket
   }
   ```
4. In `deployments.tfdeploy.hcl`, an identity token, passed to every deployment:
   ```hcl
   identity_token "aws" {
     audience = ["aws.workload.identity"]
   }

   locals {
     aws_role_arn = "arn:aws:iam::123456789012:role/stacks-my-org-my-project-tf405"
   }

   deployment "dev" {
     inputs = {
       environment  = "dev"
       owner        = "platform"
       aws_role_arn = local.aws_role_arn
       aws_token    = identity_token.aws.jwt
     }
   }
   # ...and the same two inputs for prod
   ```
5. `terraform stacks init`, `terraform stacks providers-lock` (the lock file now includes `aws`), `terraform stacks validate`, and upload.

The Stack is now at 4 resources under management (2 per deployment), and 2 real S3 buckets. `force_destroy = true` lets the destroy step remove buckets that still have objects in them.

Other ways to grow it, cheapest first:

- More `terraform_data` in `app` (free): model your application's configuration before paying for anything.
- A third deployment (`staging`): +1 resource, or +2 with the bucket.
- `for_each` on `component "bucket"` over a list of regions, with `provider "aws"` `for_each` too: +1 resource per region per deployment.

---

## 🚦 Deployment Groups and Auto-Approval

> Running auto-approval rules needs the HCP Terraform **Premium** edition.

By default, every deployment run waits for approval (except plans with no changes: the built-in `empty_plan` rule). With deployment groups you can approve some plans automatically:

```hcl
# deployments.tfdeploy.hcl

deployment_auto_approve "no_destroys" {
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Plan removes ${context.plan.changes.remove} resources."
  }
}

deployment_group "dev" {
  auto_approve_checks = [deployment_auto_approve.no_destroys]
}

deployment "dev" {
  inputs = {
    environment = "dev"
    owner       = "platform"
  }
  deployment_group = deployment_group.dev
}
```

Here, `dev` plans are approved automatically unless they destroy something. A deployment group holds one deployment for now. A deployment without a group gets a default group, which can't have custom rules.

These replace the beta's `orchestrate "auto_approve"` blocks.

---

## 🆕 Changes in Terraform 1.15 and 1.16

From the Terraform changelogs:

**1.15**
- **Input variable validation for Stacks** ([#38240](https://github.com/hashicorp/terraform/issues/38240)): `validation` blocks on Stack variables, like the one on `environment` in the example. As Part 1 shows, `terraform stacks validate` doesn't check deployment values against them; HCP Terraform does when it plans.
- **Progress events for failed plans** ([#38039](https://github.com/hashicorp/terraform/issues/38039)): when a plan fails, HCP Terraform still shows which components were planned.
- **No-op reporting** ([#38049](https://github.com/hashicorp/terraform/issues/38049)): components without changes report a no-op plan and apply, which fixes confusing displays for destroy plans.
- Output values are included in plan descriptions of component instances ([#38360](https://github.com/hashicorp/terraform/issues/38360)).

**1.16**
- `terraform stacks` finds your HCP Terraform hostname from `terraform login` credentials when `TF_STACKS_HOSTNAME` isn't set ([#38896](https://github.com/hashicorp/terraform/issues/38896)).
- Validation checks that the lock file's provider versions match the configuration ([#38829](https://github.com/hashicorp/terraform/issues/38829)).
- Actions in Stacks get the `caller` symbol (see TF-307).

---

## ✅ When to Use Stacks

**Good fit:**
- The same set of components deployed to several environments, regions or accounts
- Components that depend on each other's outputs, and must be applied in order
- A platform team offering a standard Stack that product teams deploy

**Not a good fit:**
- A single configuration: a workspace is simpler
- No HCP Terraform (or Terraform Enterprise)
- Workspaces that rely on Sentinel or OPA policy sets: those don't apply to Stacks (Terraform policy does)
- Learning Terraform: master modules, state and workspaces first

---

## 📝 Checkpoint Quiz

### Question 1: What is a Terraform Stack?

A) A way to stack multiple providers in one configuration  
B) A set of components (modules) deployed together, repeated as deployments, orchestrated by HCP Terraform  
C) A replacement for Terraform modules  
D) A CI/CD pipeline for Terraform

<details>
<summary>Show Answer</summary>

**B.** Components are ordinary modules; the Stack connects them and HCP Terraform deploys the whole set once per deployment.

</details>

---

### Question 2: File types

**Which file extensions does a Stack use since general availability?**

<details>
<summary>Show Answer</summary>

`.tfcomponent.hcl` for the component configuration (components, providers, variables, outputs) and `.tfdeploy.hcl` for the deployment configuration. `.tfstack.hcl` was the beta extension and is no longer read.

</details>

---

### Question 3: Providers

**A component module uses only `terraform_data`. Does its `component` block need a `providers` argument?**

<details>
<summary>Show Answer</summary>

Yes. `terraform_data` belongs to the built-in `terraform` provider (`terraform.io/builtin/terraform`). In a Stack, every provider a component uses must be declared in `required_providers`, configured with a `provider` block, and passed in `providers`.

</details>

---

### Question 4: Cost

**A Stack has 3 components with 4, 6 and 0 billable resources (the last one is only `terraform_data`). It has 4 deployments. How many resources under management does it add?**

<details>
<summary>Show Answer</summary>

(4 + 6 + 0) × 4 = **40**. Every deployment has its own copy of every component. `terraform_data` doesn't count.

</details>

---

### Question 5: Validation

**`terraform stacks validate` succeeds. Can a deployment still fail its variable validation?**

<details>
<summary>Show Answer</summary>

Yes. `validate` checks the configuration, not the values in `deployment` blocks. A deployment that passes `environment = "qa"` to a variable that only allows `dev`, `staging` and `prod` passes `validate`, and fails when HCP Terraform plans it.

</details>

---

## 📚 Additional Resources

### Official Documentation
- [Stacks overview](https://developer.hashicorp.com/terraform/language/stacks)
- [Define component configuration](https://developer.hashicorp.com/terraform/language/stacks/component/config)
- [Declare providers](https://developer.hashicorp.com/terraform/language/stacks/component/declare-providers)
- [Define deployment configuration](https://developer.hashicorp.com/terraform/language/stacks/deploy/config)
- [Authenticate a Stack](https://developer.hashicorp.com/terraform/language/stacks/deploy/authenticate)
- [Set conditions for deployment runs](https://developer.hashicorp.com/terraform/language/stacks/deploy/conditions)
- [Update from beta to GA](https://developer.hashicorp.com/terraform/language/stacks/update-GA)
- [`terraform stacks` CLI](https://developer.hashicorp.com/terraform/cli/commands/stacks)
- [Destroy a Stack](https://developer.hashicorp.com/terraform/cloud-docs/stacks/destroy)
- [Tutorial: Deploy a Stack with HCP Terraform](https://developer.hashicorp.com/terraform/tutorials/cloud/stacks-deploy)

### Related Courses
- **Previous**: [TF-404: Sentinel Policy as Code](../TF-404-sentinel-policies/README.md)
- **Related**: [TF-304: Policy as Code](../../TF-300-advanced/TF-304-policy-code/README.md) (Terraform policy is the framework that applies to Stacks)
- **Related**: [TF-403: Security & Access](../TF-403-security-access/README.md) (dynamic credentials)

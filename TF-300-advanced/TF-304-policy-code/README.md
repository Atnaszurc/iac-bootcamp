# TF-304: Policy as Code (OPA/Rego)

**Course**: TF-300 Advanced Terraform  
**Module**: TF-304  
**Duration**: 1.5 hours  
**Prerequisites**: TF-303 (Terraform Test Framework)  
**Tools**: [Open Policy Agent](https://www.openpolicyagent.org/) 1.x (tested with 1.21.0), optionally [Regal](https://www.openpolicyagent.org/projects/regal) (the Rego linter). Terraform and libvirt only if you want to make your own plans.

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Policy vs Validation](#policy-vs-validation)
4. [Where Policies Run](#where-policies-run)
5. [Installing OPA](#installing-opa)
6. [Rego in OPA 1.x](#rego-in-opa-1x)
7. [The Terraform Plan as Input](#the-terraform-plan-as-input)
8. [The Example Policies](#the-example-policies)
9. [Testing Policies](#testing-policies)
10. [Linting with Regal](#linting-with-regal)
11. [Enforcement: deny, warn and CI](#enforcement-deny-warn-and-ci)
12. [HCP Terraform: OPA, Sentinel and Terraform Policy](#hcp-terraform-opa-sentinel-and-terraform-policy)
13. [Best Practices](#best-practices)
14. [Hands-On Labs](#hands-on-labs)
15. [Checkpoint Quiz](#checkpoint-quiz)
16. [Additional Resources](#additional-resources)

---

## Course Overview

Policy as Code means writing your organisation's rules ("production VMs need at least 2 vCPUs", "no open networks", "every VM has an owner") as code that checks every Terraform plan automatically, before anything is applied.

This module uses **Open Policy Agent (OPA)** and its language, **Rego**. OPA is open source and free, and it doesn't need any cloud account: it reads the JSON version of a Terraform plan and tells you what's wrong with it.

### What You'll Build

Everything is in [`example/`](./example/):

- A small libvirt configuration (a network, three VMs and their disks), and a **real** `plan.json` made from it
- Three policy packages: naming and ownership, resource limits, networks
- A shared helper package that works both locally and in HCP Terraform
- 36 policy tests with 100% coverage, and a clean Regal lint

---

## Learning Objectives

By the end of this module, you will be able to:

1. ✅ Explain what policy adds on top of variable validation and conditions
2. ✅ Write Rego in the OPA 1.x syntax (`if`, `contains`, `some ... in`, `every`)
3. ✅ Read a Terraform plan's JSON and find what a policy should check
4. ✅ Evaluate policies against a plan, locally and in CI
5. ✅ Test policies with `opa test`, and lint them with Regal
6. ✅ Avoid the classic policy bug: a rule that silently passes on an undefined value
7. ✅ Compare OPA, Sentinel and Terraform policy in HCP Terraform

---

## Policy vs Validation

TF-301 and TF-302 put rules *inside* the configuration: variable validation, preconditions, postconditions, checks. Policies live *outside* it.

| Aspect | Validation and conditions (TF-301/302) | Policy (TF-304) |
|--------|-------------------------|-----------------|
| **Written by** | The module author | Often a platform, security or compliance team |
| **Lives in** | The Terraform configuration | A separate policy repository |
| **Checks** | One module's inputs and results | The whole plan, across every module and team |
| **Can be skipped by** | Editing the module | Only whoever runs the pipeline or owns the policy set |
| **Sees** | Values in the module | Everything in the plan: every resource, the actions (create, delete, replace), before and after values |

They complement each other. A module validates what it can know about itself ("memory must be a positive number"). A policy enforces what the organisation decides ("production VMs need 2 GiB"), whatever module the VM comes from.

---

## Where Policies Run

| Where | Framework | How it's enforced |
|---|---|---|
| Your machine, CI pipeline | **OPA** (`opa eval`, `opa test`) | Your pipeline fails the build when `deny` isn't empty. This module. |
| HCP Terraform / Terraform Enterprise | **OPA** policy sets | Advisory or mandatory, per policy |
| HCP Terraform / Terraform Enterprise | **Sentinel** | Advisory, soft mandatory or hard mandatory |
| HCP Terraform | **Terraform policy** (beta) | HCL-based; the only framework that also works with Stacks |

The policies you write here run in HCP Terraform too, with one difference covered in [HCP Terraform](#hcp-terraform-opa-sentinel-and-terraform-policy). HCP Terraform itself is the subject of the TF-400 series.

---

## Installing OPA

OPA is a single binary.

**Linux**:
```bash
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static
chmod +x opa
sudo mv opa /usr/local/bin/
```

**macOS**:
```bash
brew install opa
```

**Windows (PowerShell)**: download `opa_windows_amd64.exe`, rename it to `opa.exe`, and put it in a folder on your `PATH`:
```powershell
Invoke-WebRequest -Uri https://openpolicyagent.org/downloads/latest/opa_windows_amd64.exe -OutFile opa.exe
```

**Verify**:
```bash
opa version
# Version: 1.21.0
```

You need **OPA 1.0 or later**. Everything in this module uses the 1.x syntax, which OPA 0.x doesn't accept by default.

**Regal** (optional, recommended) is installed the same way, from its [GitHub releases](https://github.com/open-policy-agent/regal/releases) or with `brew install regal`.

---

## Rego in OPA 1.x

Rego is a declarative language: you describe what must be true about the input, and OPA works out the answer. It is built for JSON, which is exactly what a Terraform plan is.

### The 1.x syntax

OPA 1.0 (December 2024) made the modern syntax mandatory. Most Rego you'll find online, and older versions of this course, use the old one:

```rego
# OPA 1.x rejects this (v0 syntax)
package terraform.libvirt.old

deny[msg] {
	resource := input.resource_changes[_]
	resource.type == "libvirt_domain"
	msg := sprintf("%s", [resource.address])
}
```

```
$ opa check old.rego
2 errors occurred during loading:
old.rego:3: rego_parse_error: `if` keyword is required before rule body
old.rego:3: rego_parse_error: `contains` keyword is required for partial set rules
```

The same rule in the 1.x syntax:

```rego
package terraform.libvirt.old

deny contains msg if {
	some resource in input.resource_changes
	resource.type == "libvirt_domain"
	msg := sprintf("%s", [resource.address])
}
```

What changed:

| v0 | 1.x | Meaning |
|---|---|---|
| `deny[msg] { ... }` | `deny contains msg if { ... }` | A rule that builds a **set** |
| `allow { ... }` | `allow if { ... }` | Every rule body needs `if` |
| `import future.keywords.if` | (nothing) | The keywords are built in |
| `import rego.v1` | (nothing) | Only needed for code that must run on OPA 0.x *and* 1.x |
| `x := input.list[_]` | `some x in input.list` | Iteration; the old form still works, the new one is clearer |

To migrate old policies, `opa fmt --v0-v1 old.rego` rewrites them. To run old policies unchanged, `opa eval --v0-compatible ...`. See [Upgrading to v1.0](https://www.openpolicyagent.org/docs/v0-upgrade).

### The basics

```rego
package example

# A constant
max_vcpu := 8

# A boolean rule: true when every line of the body is true
is_prod if input.environment == "prod"

# Without a default, a rule whose body fails is *undefined*, not false.
# default gives it a value in that case.
default allow := false

allow if {
	input.vcpu <= max_vcpu
	input.memory_mib >= 512
}

# A set rule: one element for every way the body succeeds
too_big contains name if {
	some vm in input.vms
	vm.vcpu > max_vcpu
	name := vm.name
}

# FOR ALL
all_small if {
	every vm in input.vms {
		vm.vcpu <= max_vcpu
	}
}

# A function
mib(gib) := gib * 1024

# Membership in a set
allowed_modes := {"nat", "route"}

mode_ok if input.mode in allowed_modes
```

Try any of this in the [Rego Playground](https://play.openpolicyagent.org/), or with `opa eval`:

```bash
echo '{"vms": [{"name": "a", "vcpu": 2}, {"name": "b", "vcpu": 12}]}' > input.json
opa eval -d example.rego -i input.json 'data.example.too_big'
```

### Undefined: the most important idea in Rego

If a value doesn't exist, Rego doesn't raise an error. The expression is **undefined**, the rule body fails, and the rule doesn't fire.

That's convenient, and it is also the most common policy bug:

```rego
package example

# A network without a forward block has no input.forward.mode at all.
# The comparison is undefined, so this rule never fires for it:
# a silent pass.
deny contains "isolated networks are not allowed" if {
	input.forward.mode == "none"
}

# Say what a missing value means, with object.get and a default...
forward_mode := object.get(input, ["forward", "mode"], "isolated")

deny contains "isolated networks are not allowed" if {
	forward_mode == "isolated"
}

# ...or test for it with `not`: `not input.description` is true when
# input.description is undefined (or false)
deny contains "every VM needs a description" if {
	not input.description
}
```

Careful with `not` around a **function call**: in `not contains(input.description, "owner=")`, OPA evaluates `input.description` first. If it's undefined, the whole line is undefined, and the rule doesn't fire. [Quiz question 3](#question-3-undefined) is about exactly that.

When you write a policy, always ask: *what happens if this attribute is missing, null, or in a unit I didn't expect?* The example's resource-limits policy has a whole rule just for that.

---

## The Terraform Plan as Input

OPA reads JSON, so you convert the plan:

```bash
terraform plan -out=tfplan
terraform show -json tfplan > plan.json
```

The part policies use most is `resource_changes`: one entry for every resource Terraform will touch. This is one entry from [`example/plan.json`](./example/plan.json), trimmed:

```json
{
  "address": "libvirt_domain.vm[\"web\"]",
  "mode": "managed",
  "type": "libvirt_domain",
  "name": "vm",
  "index": "web",
  "change": {
    "actions": ["create"],
    "before": null,
    "after": {
      "name": "prod-web",
      "memory": 1,
      "memory_unit": "GiB",
      "vcpu": 1,
      "description": "owner=data-team environment=prod",
      "running": null,
      "uuid": null
    },
    "after_unknown": {
      "uuid": true,
      "id": true
    }
  }
}
```

What to know:

- **`change.actions`** is a list: `["create"]`, `["update"]`, `["delete"]`, `["no-op"]`, `["read"]` (data sources), or `["delete", "create"]` / `["create", "delete"]` for a replacement.
- **`change.after`** is the resource after apply. It's `null` for a delete; use `change.before` there.
- **Values that are only known after apply** (`uuid` here) are `null` in `after`, and `true` in `after_unknown`. A policy can't check a value nobody knows yet.
- **Attributes you didn't set** are there too, as `null` (`running` here). They're never missing.
- **`mode`** is `managed` for resources and `data` for data sources.
- **Units are as written.** This VM has `memory = 1` with `memory_unit = "GiB"`. A policy that reads `memory` as MiB would think it has 1 MiB. Without `memory_unit`, libvirt reads memory as **KiB**.

Other top-level keys: `planned_values` (the whole planned state, by module), `configuration` (the configuration itself, including expressions), `variables`, `output_changes`, `prior_state`. See [JSON output format](https://developer.hashicorp.com/terraform/internals/json-format).

---

## The Example Policies

```
example/
├── main.tf, variables.tf        # a network, VMs and their disks
├── violations.tfvars            # values that break the policies
├── compliant.tfvars             # values that pass them
├── plan.json                    # real plan: terraform show -json, with violations.tfvars
├── .regal/config.yaml           # linter settings
└── policy/
    ├── config/data.json         # data the policies read: data.config
    └── terraform/libvirt/
        ├── lib/lib.rego         # shared helpers (+ lib_test.rego)
        ├── naming/naming.rego   # names and owners (+ naming_test.rego)
        ├── resources/resources.rego  # memory, vCPU, disk limits (+ test)
        └── network/network.rego      # forward modes, which networks VMs join (+ test)
```

Each package lives in a directory with the same path, and each test sits next to the policy it tests, in a package with a `_test` suffix. This follows the [Rego style guide](https://www.openpolicyagent.org/docs/style-guide).

### Try it first

You don't need Terraform or libvirt for this: `plan.json` is included.

```bash
cd example

opa eval -f pretty -d policy -i plan.json 'data.terraform.libvirt.network.deny'
```

```json
[
  "libvirt_domain.vm[\"db\"]: network \"legacy-lab\" is neither in this plan nor a shared network [\"default\"]",
  "libvirt_network.app: forward mode \"open\" is not allowed, use one of [\"nat\", \"route\", \"isolated\"]"
]
```

- `-d policy` loads every `.rego` and `data.json` file under `policy/`.
- `-i plan.json` is the input.
- The query asks for the `deny` set of one package. `data.terraform.libvirt[_].deny[_]` asks for every package at once.

All violations, one per line:

```bash
opa eval -f raw -d policy -i plan.json '[m | some m in data.terraform.libvirt[_].deny]' | jq -r '.[]' | sort
```

```
libvirt_domain.vm["Batch_01"]: 12 vCPUs is above the maximum of 8
libvirt_domain.vm["Batch_01"]: 32768 MiB of memory is above the maximum of 16384 MiB
libvirt_domain.vm["Batch_01"]: VM name "prod-Batch_01" must be <environment>-<name> in lowercase, like prod-web
libvirt_domain.vm["db"]: network "legacy-lab" is neither in this plan nor a shared network ["default"]
libvirt_domain.vm["web"]: production VMs need at least 2 vCPUs (has 1)
libvirt_domain.vm["web"]: production VMs need at least 2048 MiB of memory (has 1024)
libvirt_network.app: forward mode "open" is not allowed, use one of ["nat", "route", "isolated"]
libvirt_network.app: network name "prod-app" must be net-<environment>-<name>, like net-prod-app
libvirt_volume.data["Batch_01"]: 250 GiB disk is above the maximum of 100 GiB
```

Open [`violations.tfvars`](./example/violations.tfvars) and match each message to the line that caused it.

### `lib`: helpers every policy uses

```rego
package terraform.libvirt.lib

# The plan. `terraform show -json` output is the input itself;
# HCP Terraform wraps it as input.plan, next to input.run.
# This makes every policy work in both places.
plan := object.get(input, "plan", input)

# Resources that will exist after apply: created, updated or replaced.
# Deletes are left out, and so are no-ops (nothing changes, nothing to check).
changes contains rc if {
	some rc in plan.resource_changes
	rc.mode == "managed"
	some action in rc.change.actions
	action in {"create", "update"}
}
```

`lib.rego` also converts sizes (`mib(2, "GiB") == 2048`), knows libvirt's default units, and gets the environment from a name. Every other package imports it with `import data.terraform.libvirt.lib`.

### `naming`: names and owners

```rego
package terraform.libvirt.naming

import data.terraform.libvirt.lib

vm_name_pattern := `^(dev|staging|prod)(-[a-z0-9]+)+$`

deny contains msg if {
	some rc in lib.changes
	rc.type == "libvirt_domain"
	not regex.match(vm_name_pattern, rc.change.after.name)

	msg := sprintf(
		"%s: VM name %q must be <environment>-<name> in lowercase, like prod-web",
		[rc.address, rc.change.after.name],
	)
}
```

The pattern is a raw string (backticks), so backslashes don't need escaping. libvirt has no tags, so the policy also requires `owner=<team>` in every VM's `description`.

### `resources`: limits, in the right unit

The same VM can be written as `memory = 2, memory_unit = "GiB"`, `memory = 2048, memory_unit = "MiB"` or `memory = 2097152` (no unit: KiB). The policy converts everything to MiB first:

```rego
package terraform.libvirt.resources

import data.terraform.libvirt.lib

vms contains vm if {
	some rc in lib.changes
	rc.type == "libvirt_domain"

	vm := {
		"address": rc.address,
		"name": rc.change.after.name,
		"vcpu": rc.change.after.vcpu,
		"memory_mib": lib.mib(rc.change.after.memory, lib.unit(rc.change.after.memory_unit, "KiB")),
	}
}

deny contains msg if {
	some vm in vms
	vm.memory_mib > 16384
	msg := sprintf("%s: %d MiB of memory is above the maximum of 16384 MiB", [vm.address, vm.memory_mib])
}
```

What if someone writes `memory_unit = "gigs"`? `lib.unit` is undefined for a unit it doesn't know, so `memory_mib` is undefined, so the VM isn't in `vms` at all, and **every limit silently passes**. That's why the real `resources.rego` has a rule that denies unknown units. Look for that pattern in every policy you write.

`resources.rego` also has a `warn` rule: more than 4 vCPUs is allowed, but reported.

### `network`: data from outside the policy

```rego
package terraform.libvirt.network

import data.config
import data.terraform.libvirt.lib

forward_mode(network) := object.get(network, ["forward", "mode"], "isolated")

deny contains msg if {
	some rc in lib.changes
	rc.type == "libvirt_network"
	mode := forward_mode(rc.change.after)
	not mode in config.allowed_forward_modes

	msg := sprintf(
		"%s: forward mode %q is not allowed, use one of %v",
		[rc.address, mode, config.allowed_forward_modes],
	)
}
```

`data.config` comes from [`policy/config/data.json`](./example/policy/config/data.json). OPA loads a `data.json` file under the path of its directory: `policy/config/data.json` becomes `data.config`. Lists that change more often than the rules (allowed modes, shared networks, approved images) belong in data, not in code.

The second rule in `network.rego` is a **cross-resource** check: a VM may only join a network that is in the same plan, or one of the shared networks from the data file.

"In the same plan" hides a trap, and the first version of this policy fell into it. It collected networks from `lib.changes`, which leaves out no-ops. On the *first* plan everything is being created, so it worked. On the next plan, after an apply, the network already exists: its action is `["no-op"]`, and a new VM joining it was denied. That's why `known_networks` looks at all of `resource_changes`, and why `network_test.rego` has a test with an existing network. Test your policies against a second plan, not only against a fresh one.


### Make your own plan

With Terraform and libvirt set up (see [`docs/libvirt-setup.md`](../../docs/libvirt-setup.md)):

```bash
cd example
terraform init
terraform plan -var-file=violations.tfvars -out=tfplan
terraform show -json tfplan > plan.json
opa eval -f pretty -d policy -i plan.json 'data.terraform.libvirt[_].deny'
```

Nothing is applied: OPA only needs the plan. Try `compliant.tfvars`: every `deny` set is empty.

---

## Testing Policies

Policies are code: they have bugs, and they need tests. OPA has a test runner built in.

```bash
cd example
opa test policy -v
```

```
policy/terraform/libvirt/naming/naming_test.rego:
data.terraform.libvirt.naming_test.test_good_vm_name: PASS (5.1ms)
...
--------------------------------------------------------------------------------
PASS: 36/36
```

A test is a rule whose name starts with `test_`. It passes when its body is true. `with input as` replaces the input for one expression:

```rego
package terraform.libvirt.resources_test

import data.terraform.libvirt.resources

vm(name, memory, unit, vcpu) := {"resource_changes": [{
	"address": "libvirt_domain.this",
	"mode": "managed",
	"type": "libvirt_domain",
	"change": {
		"actions": ["create"],
		"after": {"name": name, "memory": memory, "memory_unit": unit, "vcpu": vcpu},
	},
}]}

test_units_are_normalised if {
	# 2 GiB is 2048 MiB: enough for production
	count(resources.deny) == 0 with input as vm("prod-web", 2, "GiB", 2)
}

test_default_unit_is_not_mib if {
	# The classic mistake: memory = 2048 without a unit is 2 MiB, not 2 GiB
	plan := vm("dev-web", 2048, null, 1)

	resources.deny == {"libvirt_domain.this: 2 MiB of memory is below the minimum of 512 MiB"} with input as plan
}
```

Some habits worth copying from the example tests:

- **Compare the whole set of messages**, not `count(deny) > 0`. A count passes when the *wrong* rule fires.
- **Test the pass case too.** A policy that denies everything passes every "should fail" test.
- **Test the edges:** missing attributes, `null`, other units, deletes, the HCP Terraform input wrapper (`lib_test.rego`).
- **Replace data** the same way: `with data.config.allowed_forward_modes as ["open"]` (see `network_test.rego`).
- **Build fixtures with small functions** (`vm(...)`, `volume(...)`) instead of copying JSON into every test.

### Coverage

```bash
opa test policy --coverage --format=json | jq '.coverage'
# 100
```

Coverage shows which lines of the policies ran during the tests. The `not_covered` ranges in the JSON output point at rules no test reaches.

---

## Linting with Regal

`opa check --strict` finds errors (unused variables, unused imports, shadowed names). [Regal](https://www.openpolicyagent.org/projects/regal) goes further: it checks the [Rego style guide](https://www.openpolicyagent.org/docs/style-guide) and catches likely bugs.

```bash
cd example
opa fmt --list policy        # files that need formatting (none)
opa check --strict policy
regal lint policy
# 8 files linted. No violations found.
```

Writing the example, Regal caught, among other things:

- `plan := input.plan if input.plan`: a *redundant existence check*, replaced by `object.get(input, "plan", input)`
- two `deny` rules separated by a helper: a *messy rule*, so the helpers moved up
- a test helper called `net`, which *shadows a built-in* function
- test lines longer than 120 characters

`.regal/config.yaml` tells Regal that `data.config` is real (it comes from a JSON file, which Regal doesn't read). Most editors have a Regal plugin (VS Code: "OPA" extension) that shows the same findings as you type.

---

## Enforcement: deny, warn and CI

OPA itself doesn't block anything. It answers queries; your pipeline decides what to do with the answer. The example uses two rule names:

- **`deny`**: violations. The pipeline fails.
- **`warn`**: advisories. The pipeline prints them and carries on.

```bash
opa eval -f raw -d policy -i plan.json '[m | some m in data.terraform.libvirt[_].warn]' | jq -r '.[]'
# libvirt_domain.vm["Batch_01"]: 12 vCPUs, are you sure? Most lab VMs need 4 or fewer
```

`--fail-defined` makes `opa eval` exit with 1 when the query has any result:

```bash
opa eval --fail-defined -d policy -i plan.json 'data.terraform.libvirt[_].deny[_]' > /dev/null
echo $?
# 1 with violations.tfvars, 0 with compliant.tfvars
```

A GitHub Actions job:

```yaml
jobs:
  policy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install OPA
        run: |
          curl -sSL -o opa https://openpolicyagent.org/downloads/v1.21.0/opa_linux_amd64_static
          chmod +x opa && sudo mv opa /usr/local/bin/

      - name: Test the policies
        run: opa test policy

      # plan.json comes from an earlier step: terraform plan + terraform show -json
      - name: Warnings
        run: opa eval -f raw -d policy -i plan.json '[m | some m in data.terraform.libvirt[_].warn]' | jq -r '.[]'

      - name: Violations
        run: |
          opa eval -f raw -d policy -i plan.json '[m | some m in data.terraform.libvirt[_].deny]' | jq -r '.[]'
          opa eval --fail-defined -d policy -i plan.json 'data.terraform.libvirt[_].deny[_]' > /dev/null
```

An "override with approval" (what Sentinel calls *soft mandatory*) isn't something a policy can decide by itself: the plan has no field that says "approved". In a pipeline, that's a manual approval step that lets the job continue despite a failed `deny`. In HCP Terraform it's built in, as the next section shows.

---

## HCP Terraform: OPA, Sentinel and Terraform Policy

HCP Terraform (and Terraform Enterprise) run policies on every run, and show the results in the UI.

### OPA in HCP Terraform

You connect a policy set (a VCS repository with your `.rego` files) and, for each policy, give the **query**, for example `data.terraform.libvirt.naming.deny`. An empty result means the policy passes.

Two differences from running OPA yourself:

1. **The input is wrapped.** HCP Terraform passes `{"plan": <the plan JSON>, "run": <run details>}`. Your rules must read `input.plan.resource_changes`, not `input.resource_changes`. The example's `lib.plan` handles both, and `lib_test.rego` tests it. `input.run` gives you the workspace, organisation, project and more, for rules like "no auto-apply workspaces".
2. **Enforcement levels** are set per policy:
   - **advisory**: failures are reported, the run continues
   - **mandatory**: failures stop the run; users with *Manage Policy Overrides* permission can override

### Sentinel

Sentinel is HashiCorp's own policy language. In HCP Terraform it has three enforcement levels: **advisory**, **soft mandatory** (overridable) and **hard mandatory**. The forward-mode rule in Sentinel:

```sentinel
import "tfplan/v2" as tfplan

allowed_modes = ["nat", "route"]

# libvirt networks that will exist after apply
networks = filter tfplan.resource_changes as _, rc {
	rc.mode is "managed" and
		rc.type is "libvirt_network" and
		(rc.change.actions contains "create" or rc.change.actions contains "update")
}

main = rule {
	all networks as _, rc {
		rc.change.after.forward.mode in allowed_modes
	}
}
```

This was tested with the free Sentinel CLI (`sentinel test`, v0.41.0), with mocks made from this module's `plan.json`: `main` is `false` for the violations plan and `true` for the compliant one.

### Terraform policy (beta)

HCP Terraform also has a newer, HCL-based framework, **Terraform policy**. It's the only one of the three that works with **Stacks** (Sentinel and OPA policy sets only apply to workspaces). It's in beta and needs a Terraform 1.16 pre-release in HCP Terraform; see [Define policies for the Terraform policy framework](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement/define-policies/terraform-policy).

### Which one?

| | OPA | Sentinel | Terraform policy |
|---|---|---|---|
| **Language** | Rego | Sentinel | HCL |
| **Runs locally** | Yes, free and open source | Yes, free CLI | In HCP Terraform |
| **HCP Terraform** | Advisory, mandatory | Advisory, soft mandatory, hard mandatory | Advisory, mandatory overridable, mandatory |
| **Stacks** | No | No | Yes |
| **Beyond Terraform** | Kubernetes, APIs, CI, anything JSON | HashiCorp products | Terraform only |
| **Choose it when** | You want one policy language for everything, or no HCP Terraform | You're all-in on HCP Terraform and want pre-written policy libraries | You use Stacks, or want policies in HCL |

---

## Best Practices

1. **Write actionable messages.** Include the resource address, the value found and what's allowed: `libvirt_domain.vm["web"]: production VMs need at least 2 vCPUs (has 1)`.
2. **Handle undefined on purpose.** Missing attributes, `null`, unknown units: decide what they mean (`object.get` with a default, or a rule that denies them), and test it.
3. **Normalise before you compare.** Units, case, list-or-single-value: convert once, in a helper.
4. **Keep data out of rules.** Allowed values, approved images, shared networks go in `data.json`.
5. **One concern per package**, and a package path that matches the directory.
6. **Test both directions**, and compare exact message sets.
7. **Lint.** `opa fmt`, `opa check --strict` and Regal in CI, like any other code.
8. **Use `warn` before `deny`.** Roll a new rule out as advisory, fix what it finds, then make it mandatory.
9. **Write for the wrapped input** (`input.plan`) if the policies might ever run in HCP Terraform.

---

## Hands-On Labs

All labs work in [`example/`](./example/). Labs 1 and 2 need only OPA; making new plans needs Terraform and libvirt.

### Lab 1: Read, fix, re-check (20 minutes)

1. Run the policy tests and the lint: `opa test policy -v`, `regal lint policy`.
2. Evaluate the included plan and list every violation (the command is in [Try it first](#try-it-first)).
3. Copy `violations.tfvars` to `mine.tfvars` and fix it, one violation at a time, **without** looking at `compliant.tfvars`.
4. After each fix, make a new plan and evaluate it:
   ```bash
   terraform plan -var-file=mine.tfvars -out=tfplan && terraform show -json tfplan > mine.json
   opa eval --fail-defined -d policy -i mine.json 'data.terraform.libvirt[_].deny[_]'
   ```
5. You're done when `--fail-defined` exits with 0. Is there still a warning?

No libvirt? Edit `plan.json` with `jq` instead, for example: `jq '(.resource_changes[] | select(.type == "libvirt_network") | .change.after.forward.mode) = "nat"' plan.json > fixed.json`.

### Lab 2: Write a policy, test first (25 minutes)

**Rule**: every volume must be `qcow2` (`change.after.target.format.type`). A volume with no format set is a violation too.

1. Create `policy/terraform/libvirt/storage/storage_test.rego` with three tests: a qcow2 volume passes, a `raw` volume is denied, a volume with `target = null` is denied. Run `opa test policy`: they fail.
2. Create `storage.rego` and make the tests pass.
3. Run `regal lint policy` and fix what it finds.
4. Evaluate `plan.json`: the example's volumes are all qcow2, so the result is `[]`.

<details>
<summary>Solution</summary>

```rego
# METADATA
# title: Storage
# description: All volumes are qcow2
package terraform.libvirt.storage

import data.terraform.libvirt.lib

# METADATA
# title: qcow2 volumes
# entrypoint: true
deny contains msg if {
	some rc in lib.changes
	rc.type == "libvirt_volume"
	format := object.get(rc.change.after, ["target", "format", "type"], "not set")
	format != "qcow2"

	msg := sprintf("%s: volume format is %q, must be qcow2", [rc.address, format])
}
```

```rego
package terraform.libvirt.storage_test

import data.terraform.libvirt.storage

volume(target) := {"resource_changes": [{
	"address": "libvirt_volume.this",
	"mode": "managed",
	"type": "libvirt_volume",
	"change": {"actions": ["create"], "after": {"target": target}},
}]}

test_qcow2 if {
	count(storage.deny) == 0 with input as volume({"format": {"type": "qcow2"}})
}

test_raw if {
	plan := volume({"format": {"type": "raw"}})

	storage.deny == {`libvirt_volume.this: volume format is "raw", must be qcow2`} with input as plan
}

test_no_format if {
	storage.deny == {`libvirt_volume.this: volume format is "not set", must be qcow2`} with input as volume(null)
}
```

Why `object.get` with a default, instead of `rc.change.after.target.format.type != "qcow2"`? With `target = null`, that path is undefined, the comparison is undefined, and the volume would silently pass. `test_no_format` catches exactly that bug.

</details>

### Lab 3: Protect production from destroys (25 minutes)

**Rule**: a plan must never delete or replace a production VM (name starting with `prod-`).

This one is different: `lib.changes` leaves deletes out on purpose. And for a delete, `change.after` is `null`.

1. Write the tests first: deleting `prod-web` is denied, replacing it (`["delete", "create"]`) is denied, `["create", "delete"]` (create before destroy) is denied, deleting `dev-web` is allowed.
2. Write `policy/terraform/libvirt/protect/protect.rego`.
3. Bonus: check it against a real plan. Apply `compliant.tfvars` (it needs a storage pool called `default`, see [`docs/libvirt-setup.md`](../../docs/libvirt-setup.md)). Then copy it to `renamed.tfvars`, rename the `web` key to `web2`, and plan with that file. Terraform plans to delete `libvirt_domain.vm["web"]` (prod-web) and create `vm["web2"]`, and your policy denies it. Run `terraform destroy -var-file=compliant.tfvars` afterwards.


<details>
<summary>Solution</summary>

```rego
# METADATA
# title: Protect production
# description: Production VMs are never destroyed or replaced by a plan
package terraform.libvirt.protect

import data.terraform.libvirt.lib

# METADATA
# title: No deleting prod VMs
# entrypoint: true
deny contains msg if {
	# Not lib.changes: that leaves deletes out on purpose
	some rc in lib.plan.resource_changes
	rc.type == "libvirt_domain"
	"delete" in rc.change.actions

	# after is null for a delete, so the name comes from before
	lib.environment(rc.change.before.name) == "prod"

	msg := sprintf("%s: plan wants to %v production VM %q", [rc.address, rc.change.actions, rc.change.before.name])
}
```

```rego
package terraform.libvirt.protect_test

import data.terraform.libvirt.protect

vm_change(name, actions) := {"resource_changes": [{
	"address": "libvirt_domain.this",
	"mode": "managed",
	"type": "libvirt_domain",
	"change": {"actions": actions, "before": {"name": name}, "after": null},
}]}

test_delete_prod if {
	count(protect.deny) == 1 with input as vm_change("prod-web", ["delete"])
}

test_replace_prod if {
	plan := vm_change("prod-web", ["delete", "create"])

	protect.deny == {`libvirt_domain.this: plan wants to ["delete", "create"] production VM "prod-web"`} with input as plan
}

test_create_before_destroy_prod if {
	count(protect.deny) == 1 with input as vm_change("prod-web", ["create", "delete"])
}

test_delete_dev if {
	count(protect.deny) == 0 with input as vm_change("dev-web", ["delete"])
}
```

Terraform has its own guard for this: `lifecycle { prevent_destroy = true }`. The difference is who controls it. `prevent_destroy` is in the module, and whoever edits the module can remove it. The policy is outside, owned by someone else, and applies to every module at once.

</details>

---

## Checkpoint Quiz

### Question 1: Policy vs validation
**A module validates `memory_mb > 0`. Why would you also want a policy for memory?**

<details>
<summary>Show Answer</summary>

The module's validation is the module author's rule, and only applies to that module. An organisational rule ("production VMs need 2 GiB") should apply to every VM from every module, and shouldn't be removable by editing one module. That's what a policy, owned outside the configuration, gives you.

</details>

---

### Question 2: Rego syntax
**In OPA 1.x, what does `deny contains msg if { ... }` define?**

A) A function named deny  
B) A set of violation messages: one element for every way the body succeeds  
C) A boolean that's true if any message exists  
D) Nothing: it's the old syntax

<details>
<summary>Show Answer</summary>

**B.** `contains` makes a *set* rule (a "partial set rule"). Every combination of values that makes the body true adds one `msg` to `deny`. The old way to write the same thing was `deny[msg] { ... }`, which OPA 1.x rejects.

</details>

---

### Question 3: Undefined
**This rule is meant to deny VMs without an owner. A VM has no `description` at all. What happens?**

```rego
package quiz

deny contains "VM needs an owner" if {
	not contains(input.description, "owner=")
}
```

<details>
<summary>Show Answer</summary>

It does **not** fire: the VM silently passes. OPA evaluates the reference `input.description` before it negates anything. The reference is undefined, so the whole line is undefined, and the rule body fails. `not` only turns undefined into true when the undefined thing *is* the expression, as in `not input.description`.

The fix is to decide what "missing" means before the negation:

```rego
package quiz

deny contains "VM needs an owner" if {
	description := object.get(input, "description", "")
	not contains(description, "owner=")
}
```

In a real Terraform plan this particular case is rarer than it looks: attributes you don't set are in `change.after` as `null`, and `null` *is* defined (`contains(null, ...)` is undefined, so `not` makes it true). It bites with hand-written test input, nested objects that are `null` themselves, and HCP Terraform's `input.plan` wrapper.

</details>

---

### Question 4: Units
**A VM has `memory = 2048` and no `memory_unit`. A policy reads `memory` and checks it's at least 512. Does it pass?**

<details>
<summary>Show Answer</summary>

It passes, but it shouldn't. libvirt's default memory unit is **KiB**, so this VM has 2 MiB of memory. The policy has to take `memory_unit` into account, as `lib.mib` does in the example.

</details>

---

### Question 5: The workflow
**What is the correct order?**

A) `terraform apply` → `opa eval` → `terraform plan`  
B) `terraform plan -out=tfplan` → `terraform show -json tfplan > plan.json` → `opa eval` → `terraform apply tfplan`  
C) `opa eval` → `terraform plan` → `terraform apply`  
D) `terraform validate` → `opa eval` → `terraform apply`

<details>
<summary>Show Answer</summary>

**B.** OPA checks the saved plan, and you apply *that* plan, so what was checked is exactly what gets applied.

</details>

---

### Question 6: HCP Terraform
**Your policies work locally with `opa eval -i plan.json`. In HCP Terraform, every `deny` is empty, even for bad plans. Why?**

<details>
<summary>Show Answer</summary>

HCP Terraform wraps the plan: the input is `{"plan": ..., "run": ...}`. Rules that read `input.resource_changes` find nothing (it's undefined), so they never fire. Read `input.plan.resource_changes`, or use a helper like the example's `lib.plan` that works both ways.

</details>

---

## Additional Resources

### OPA and Rego
- [Policy Language](https://www.openpolicyagent.org/docs/policy-language): the Rego reference
- [Policy Testing](https://www.openpolicyagent.org/docs/policy-testing)
- [Terraform](https://www.openpolicyagent.org/docs/terraform): OPA's own Terraform tutorial
- [Upgrading to v1.0](https://www.openpolicyagent.org/docs/v0-upgrade)
- [Rego Style Guide](https://www.openpolicyagent.org/docs/style-guide)
- [Regal](https://www.openpolicyagent.org/projects/regal)
- [Rego Playground](https://play.openpolicyagent.org/)

### Terraform
- [JSON Output Format](https://developer.hashicorp.com/terraform/internals/json-format): every field of `plan.json`
- [Policy enforcement in HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement)
- [Define OPA policies for HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement/define-policies/opa)
- [Sentinel](https://developer.hashicorp.com/sentinel/docs)

### Tools
- [Conftest](https://www.conftest.dev/): runs Rego policies against configuration files, including plan JSON

---

## Summary

✅ **Policy vs validation**: policies check the whole plan, from outside the configuration  
✅ **Rego 1.x**: `if`, `contains`, `some ... in`, `every`; `opa fmt --v0-v1` for old code  
✅ **The plan JSON**: `resource_changes`, `actions`, `before`/`after`, unknown values, units as written  
✅ **Undefined**: the silent pass, and how to prevent it  
✅ **Testing and linting**: `opa test`, exact message sets, coverage, Regal  
✅ **Enforcement**: `deny`/`warn`, `--fail-defined` in CI; advisory and mandatory in HCP Terraform  
✅ **OPA, Sentinel and Terraform policy**: what each is for

### What's Next?

- **TF-305**: Workspaces and Remote State
- **TF-400**: HCP Terraform, where policy sets run on every run; **TF-404** covers Sentinel in depth

---

**Course**: TF-300 Advanced Terraform  
**Module**: TF-304 - Policy as Code (OPA/Rego)  
**Duration**: 1.5 hours  
**Last Updated**: 2026-09-28

# Check Blocks with Assertions

## Introduction

Terraform 1.5 introduced `check` blocks: assertions that live outside any single resource and run at the end of **every** plan and apply. Unlike [preconditions and postconditions](../1-pre-postconditions/README.md), a failing check doesn't stop anything. It prints a warning and Terraform carries on.

That makes checks the tool for questions like "is the website up?", "is the host running out of room?" or "does a certificate expire soon?": things worth hearing about on every run, but not worth blocking a deployment for.

**Example**: [`example/`](./example/) — a libvirt VM running nginx and the checks from this lesson, verified on a real libvirt host, with 4 tests that run without libvirt (`terraform test`).

## Table of Contents
- [Basic Structure](#basic-structure)
- [Example: Is the Website Up?](#example-is-the-website-up)
- [Example: Host Headroom](#example-host-headroom)
- [Checks vs Conditions](#checks-vs-conditions)
- [Best Practices](#best-practices)
- [Task 1: Web Health Check](#task-1-web-health-check)
- [Task 2: Host Headroom](#task-2-host-headroom)
- [Task 3: Check or Precondition?](#task-3-check-or-precondition)
- [Task 4: Checks and Drift](#task-4-checks-and-drift)
- [Task 5: Testing Checks](#task-5-testing-checks)
- [Bonus Task: Certificate Expiry](#bonus-task-certificate-expiry)

## Basic Structure

```hcl
check "name_of_check" {
  # Optional: one scoped data source
  data "<type>" "<name>" {
    # ...
  }

  # One or more assertions
  assert {
    condition     = <boolean expression>
    error_message = "Message shown as a warning if the condition is false"
  }
}
```

A check can have **one scoped data source**. It is read as part of the check, and if reading it fails (a timeout, a connection refused), that becomes a warning too instead of an error.

## Example: Is the Website Up?

The example VM installs nginx through cloud-init and gets a fixed address from a DHCP host entry. This check calls it with the `hashicorp/http` provider:

```hcl
check "web_health" {
  data "http" "home" {
    url = "http://${local.vm_ip}/"
    retry { attempts = 2 }
    depends_on = [libvirt_domain.web]
  }

  assert {
    condition     = data.http.home.status_code == 200
    error_message = "http://${local.vm_ip}/ returned ${data.http.home.status_code}, expected 200."
  }

  assert {
    condition     = strcontains(data.http.home.response_body, var.vm_name)
    error_message = "The page doesn't mention ${var.vm_name}: is this the right server?"
  }
}
```

On the first `terraform apply` the VM exists, but cloud-init is still installing nginx:

```
Warning: Error making request
  GET http://10.160.0.10/ giving up after 3 attempt(s)

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
```

The apply succeeds with a warning. A minute later, `terraform plan` runs the check again and it passes.

## Example: Host Headroom

```hcl
data "libvirt_node_info" "host" {}

check "host_memory_headroom" {
  assert {
    condition     = data.libvirt_node_info.host.memory_total_kb / 1024 - var.memory_mb >= var.min_host_headroom_mb
    error_message = "After this VM, the host has less than ${var.min_host_headroom_mb} MiB left for other VMs."
  }
}
```

A check doesn't need its own data source: it can use anything in the configuration.

## Checks vs Conditions

| | Variable `validation` | `precondition` / `postcondition` | `check` |
|---|---|---|---|
| Attached to | A variable | A resource, data source or output | Nothing: stands alone |
| On failure | Error: stops the run | Error: stops the run | **Warning**: run continues |
| Runs | Plan | Plan and/or apply | End of every plan and apply |
| Use for | Bad input | Assumptions a resource depends on | Ongoing health and hygiene |

## Best Practices

1. Use checks for things you want to *know*, conditions for things that must *stop* the run.
2. Put slow or flaky lookups (HTTP calls, APIs) in a scoped data source, so a timeout warns instead of failing the plan.
3. Include the actual value in the message: `returned ${data.http.home.status_code}`.
4. Read warnings. A check nobody looks at is decoration; in CI, consider failing the pipeline on check warnings.

## Task 1: Web Health Check

Add the `web_health` check from [the example above](#example-is-the-website-up) and apply. Watch it warn during the first apply, then run `terraform plan` a minute later.

Then try the second assertion: change the page by setting a different `runcmd` in cloud-init, replace the VM (`terraform apply -replace=libvirt_domain.web`), and see which assertion fires.

## Task 2: Host Headroom

Add the `host_memory_headroom` check, then run:

```bash
terraform plan -var memory_mb=16384 -var min_host_headroom_mb=65536
```

The plan shows the warning, but still plans the VM.

## Task 3: Check or Precondition?

Move the headroom rule into a `precondition` on `libvirt_domain.web` and run the same plan. What changes? Which one would you want:
- on a shared lab server, where other people's VMs need room?
- on your own laptop, where you know what you're doing?

There's no single right answer, which is exactly why Terraform has both.

## Task 4: Checks and Drift

With the example applied, stop the VM behind Terraform's back and plan:

```bash
virsh -c qemu:///system destroy tf302-web
terraform plan
```

```
  # libvirt_domain.web will be updated in-place
      ~ running     = false -> true

Warning: Check block assertion known after apply
```

Terraform notices the VM isn't running (drift) and plans to start it. The web check *doesn't* warn about the site being down: its data source depends on the VM, which has a pending change, so the check is deferred until after apply. Run `terraform apply` and watch it warn while nginx starts again.

## Task 5: Testing Checks

Look at `example/tests/checks.tftest.hcl`. Two rules about checks in `terraform test`:

1. A failing check **fails the test run**, unless the run lists it: `expect_failures = [check.web_health]`.
2. A check still *known after apply* at the end of a `plan` run also fails it. The web check reads from the VM, so the tests use `command = apply`, which is safe because both providers are mocked.

`override_data` replaces the HTTP response, so the tests can simulate a healthy server, a `502`, and the wrong server answering:

```hcl
run "web_server_unhealthy" {
  command = apply

  override_data {
    target = data.http.home # a data source inside a check keeps its normal address
    values = {
      status_code   = 502
      response_body = "Bad Gateway"
    }
  }

  expect_failures = [check.web_health]
}
```

> ⚠️ Don't use `plan_options { target = [...] }` to narrow a check test down. Checks outside the target are *skipped*, so a test that expects a check to pass would pass without the check ever running.

## Bonus Task: Certificate Expiry

Generate a self-signed certificate with the `hashicorp/tls` provider and warn when it expires within 30 days. `provider::time::rfc3339_parse()` (see [TF-301 Section 2](../../TF-301-validation/2-advanced-functions/README.md)) turns the timestamps into numbers you can compare.

### Example
```hcl
terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

resource "tls_private_key" "web" {
  algorithm = "ED25519"
}

resource "tls_self_signed_cert" "web" {
  private_key_pem       = tls_private_key.web.private_key_pem
  validity_period_hours = var.cert_valid_hours
  allowed_uses          = ["server_auth"]
  subject {
    common_name = "tf302-web"
  }
}

check "certificate_not_expiring" {
  assert {
    condition = (
      provider::time::rfc3339_parse(tls_self_signed_cert.web.validity_end_time).unix -
      provider::time::rfc3339_parse(plantimestamp()).unix
    ) > 30 * 86400
    error_message = "The web certificate expires on ${tls_self_signed_cert.web.validity_end_time}, less than 30 days from now."
  }
}
```

```bash
terraform apply -var cert_valid_hours=240
# Warning: Check block assertion failed
#   The web certificate expires on 2026-10-08T15:03:20+02:00, less than 30 days from now.
```

This is the classic use of a check: nothing is broken *yet*, but someone should renew that certificate.

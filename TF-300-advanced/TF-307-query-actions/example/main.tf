# TF-307 Part 2: Actions
# Demonstrates: action blocks, lifecycle action_trigger, the caller symbol,
#               destroy-time triggers and on_failure (Terraform 1.16+)
# Provider: hashicorp/local (local_command action — no cloud credentials)
# Run: terraform init && terraform apply
#
# Every action in this file appends a line to out/audit.log so you can see
# exactly when Terraform invoked it. Run `cat out/audit.log` after each step.

terraform {
  required_version = ">= 1.16"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.6" # local_command action added in 2.6.0
    }
  }
}

locals {
  out_dir   = "${path.module}/out"
  audit_log = "${local.out_dir}/audit.log"
}

# ─────────────────────────────────────────────────────────────────────────────
# Managed resources: one config file per service
# Each instance triggers the same actions through lifecycle.action_trigger.
# ─────────────────────────────────────────────────────────────────────────────

resource "local_file" "service_config" {
  for_each = var.services

  filename = "${local.out_dir}/${each.key}.conf"
  content  = <<-EOT
    service     = ${each.key}
    port        = ${each.value.port}
    environment = ${var.environment}
    version     = ${var.app_version}
  EOT

  lifecycle {
    # Record every create and update in the audit log
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.local_command.audit_deploy]
    }

    # Destroy-time events are new in Terraform 1.16.
    # on_failure = continue: a failed backup logs a warning but does not
    # block the destroy (the default, halt, would stop the apply).
    action_trigger {
      events     = [before_destroy]
      actions    = [action.local_command.backup_config]
      on_failure = continue
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Actions
# Arguments for the provider go inside the config block.
# `caller` (Terraform 1.16+) is the resource instance whose action_trigger
# invoked the action, so one action block serves every for_each instance.
# ─────────────────────────────────────────────────────────────────────────────

action "local_command" "audit_deploy" {
  config {
    command = "sh"
    arguments = [
      "-c",
      "mkdir -p \"$(dirname \"$2\")\" && echo \"$(date -u +%Y-%m-%dT%H:%M:%SZ) deployed $1\" >> \"$2\"",
      "sh",
      caller.filename,
      local.audit_log,
    ]
  }
}

action "local_command" "backup_config" {
  config {
    command = "sh"
    arguments = [
      "-c",
      "cp \"$1\" \"$1.bak\" && echo \"$(date -u +%Y-%m-%dT%H:%M:%SZ) backed up $1\" >> \"$2\"",
      "sh",
      caller.filename,
      local.audit_log,
    ]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Manual-only action: not referenced by any action_trigger.
# Run it with: terraform apply -invoke=action.local_command.health_check
# `caller` is not available here because no resource invokes this action.
# ─────────────────────────────────────────────────────────────────────────────

action "local_command" "health_check" {
  config {
    command = "sh"
    arguments = [
      "-c",
      "for f in \"$@\"; do test -s \"$f\" || { echo \"missing: $f\" >&2; exit 1; }; done; echo \"$(date -u +%Y-%m-%dT%H:%M:%SZ) health check passed\" >> ${local.audit_log}",
      "sh",
      "${local.out_dir}/api.conf",
      "${local.out_dir}/worker.conf",
    ]
  }
}

# Policy: naming.rego
# ====================
# Enforces naming conventions for Terraform-managed resources.
#
# Rules:
#   - All resources must have a "Name" tag
#   - Resource names must follow the pattern: <env>-<type>-<name>
#   - Environment must be one of: dev, staging, prod
#
# Usage:
#   opa eval -d policies/ -i plan.json "data.terraform.naming.violations"

package terraform.naming

import rego.v1

# ─── Allowed environments ────────────────────────────────────────────────────

allowed_environments := {"dev", "staging", "prod"}

# ─── Helper: extract all planned resource changes ────────────────────────────

resource_changes := input.resource_changes

# ─── Rule: all resources must have a Name tag ────────────────────────────────

violations contains msg if {
    some change in resource_changes
    change.change.actions != ["delete"]
    not change.change.after.tags.Name
    msg := sprintf(
        "Resource '%s' (%s) is missing required 'Name' tag",
        [change.address, change.type]
    )
}

# ─── Rule: Name tag must follow <env>-<type>-<name> pattern ─────────────────

violations contains msg if {
    some change in resource_changes
    change.change.actions != ["delete"]
    name := change.change.after.tags.Name
    not regex.match(`^(dev|staging|prod)-[a-z]+-[a-z0-9-]+$`, name)
    msg := sprintf(
        "Resource '%s' has invalid Name tag '%s'. Must match pattern: <env>-<type>-<name> (e.g. dev-vm-webserver)",
        [change.address, name]
    )
}

# ─── Rule: environment tag must be an allowed value ──────────────────────────

violations contains msg if {
    some change in resource_changes
    change.change.actions != ["delete"]
    env := change.change.after.tags.Environment
    env != null
    not env in allowed_environments
    msg := sprintf(
        "Resource '%s' has invalid Environment tag '%s'. Must be one of: %v",
        [change.address, env, allowed_environments]
    )
}

# ─── Summary ─────────────────────────────────────────────────────────────────

deny := violations

allow if {
    count(violations) == 0
}
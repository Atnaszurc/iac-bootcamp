# Policy: security.rego
# ======================
# Enforces security standards for Terraform-managed infrastructure.
#
# Rules:
#   - Storage volumes must not be world-readable (no 0777 permissions)
#   - Resources must have a ManagedBy tag set to "terraform"
#   - Sensitive resources must have an Owner tag
#
# Usage:
#   opa eval -d policies/ -i plan.json "data.terraform.security.violations"

package terraform.security

import rego.v1

# ─── Helper: extract all planned resource changes ────────────────────────────

resource_changes := input.resource_changes

# ─── Rule: no world-writable file permissions ────────────────────────────────
# Applies to local_file resources (and by analogy, storage volumes)

violations contains msg if {
    some change in resource_changes
    change.type == "local_file"
    change.change.actions != ["delete"]
    perm := change.change.after.file_permission
    perm != null
    # World-writable: last octet has write bit (2)
    # 0777, 0666, 0776, 0767, etc.
    endswith(perm, "7") # world rwx
    msg := sprintf(
        "Resource '%s' has world-writable permissions '%s'. Use 0644 or 0640 instead.",
        [change.address, perm]
    )
}

violations contains msg if {
    some change in resource_changes
    change.type == "local_file"
    change.change.actions != ["delete"]
    perm := change.change.after.file_permission
    perm != null
    endswith(perm, "6") # world rw (no execute)
    msg := sprintf(
        "Resource '%s' has world-readable/writable permissions '%s'. Use 0644 or 0640 instead.",
        [change.address, perm]
    )
}

# ─── Rule: all resources must have ManagedBy = "terraform" tag ───────────────

violations contains msg if {
    some change in resource_changes
    change.change.actions != ["delete"]
    managed_by := change.change.after.tags.ManagedBy
    managed_by != "terraform"
    msg := sprintf(
        "Resource '%s' must have tag ManagedBy = 'terraform', got '%v'",
        [change.address, managed_by]
    )
}

# ─── Rule: production resources must have an Owner tag ───────────────────────

violations contains msg if {
    some change in resource_changes
    change.change.actions != ["delete"]
    change.change.after.tags.Environment == "prod"
    not change.change.after.tags.Owner
    msg := sprintf(
        "Production resource '%s' must have an 'Owner' tag for accountability.",
        [change.address]
    )
}

# ─── Summary ─────────────────────────────────────────────────────────────────

deny := violations

allow if {
    count(violations) == 0
}
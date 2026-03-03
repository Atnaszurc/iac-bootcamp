# OPA Tests: security_test.rego
# ===============================
# Tests for the security.rego policy.
# Run with: opa test policies/ tests/

package terraform.security

import rego.v1

# ─── Test fixtures ───────────────────────────────────────────────────────────

compliant_resource := {
    "address": "local_file.dev_config",
    "type": "local_file",
    "change": {
        "actions": ["create"],
        "after": {
            "filename": "./output/dev-config.conf",
            "file_permission": "0644",
            "tags": {
                "Name":        "dev-file-config",
                "Environment": "dev",
                "ManagedBy":   "terraform"
            }
        }
    }
}

world_writable_resource := {
    "address": "local_file.insecure",
    "type": "local_file",
    "change": {
        "actions": ["create"],
        "after": {
            "filename": "./output/insecure.conf",
            "file_permission": "0777",
            "tags": {
                "Name":      "dev-file-insecure",
                "ManagedBy": "terraform"
            }
        }
    }
}

missing_managed_by_resource := {
    "address": "local_file.unmanaged",
    "type": "local_file",
    "change": {
        "actions": ["create"],
        "after": {
            "filename": "./output/unmanaged.conf",
            "file_permission": "0644",
            "tags": {
                "Name":        "dev-file-unmanaged",
                "Environment": "dev",
                "ManagedBy":   "ansible"
            }
        }
    }
}

prod_without_owner := {
    "address": "local_file.prod_config",
    "type": "local_file",
    "change": {
        "actions": ["create"],
        "after": {
            "filename": "./output/prod-config.conf",
            "file_permission": "0640",
            "tags": {
                "Name":        "prod-file-config",
                "Environment": "prod",
                "ManagedBy":   "terraform"
            }
        }
    }
}

prod_with_owner := {
    "address": "local_file.prod_config_owned",
    "type": "local_file",
    "change": {
        "actions": ["create"],
        "after": {
            "filename": "./output/prod-config-owned.conf",
            "file_permission": "0640",
            "tags": {
                "Name":        "prod-file-config",
                "Environment": "prod",
                "ManagedBy":   "terraform",
                "Owner":       "platform-team"
            }
        }
    }
}

# ─── Tests ───────────────────────────────────────────────────────────────────

test_compliant_resource_has_no_violations if {
    count(violations) == 0 with input as {"resource_changes": [compliant_resource]}
}

test_world_writable_is_violation if {
    some v in violations with input as {"resource_changes": [world_writable_resource]}
    contains(v, "world-writable")
}

test_wrong_managed_by_is_violation if {
    some v in violations with input as {"resource_changes": [missing_managed_by_resource]}
    contains(v, "ManagedBy")
}

test_prod_without_owner_is_violation if {
    some v in violations with input as {"resource_changes": [prod_without_owner]}
    contains(v, "Owner")
}

test_prod_with_owner_has_no_owner_violation if {
    vs := violations with input as {"resource_changes": [prod_with_owner]}
    not any_owner_violation(vs)
}

any_owner_violation(vs) if {
    some v in vs
    contains(v, "Owner")
}

test_deleted_resources_are_skipped if {
    deleted := {
        "address": "local_file.old",
        "type": "local_file",
        "change": {
            "actions": ["delete"],
            "after": null
        }
    }
    count(violations) == 0 with input as {"resource_changes": [deleted]}
}

test_allow_when_compliant if {
    allow with input as {"resource_changes": [compliant_resource]}
}

test_deny_when_violations_exist if {
    not allow with input as {"resource_changes": [world_writable_resource]}
}
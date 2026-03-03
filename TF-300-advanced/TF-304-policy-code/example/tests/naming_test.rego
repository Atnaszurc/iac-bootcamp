# OPA Tests: naming_test.rego
# ============================
# Tests for the naming.rego policy.
# Run with: opa test policies/ tests/
#
# OPA test functions must start with "test_"
# They use the same Rego language as policies.

package terraform.naming

import rego.v1

# ─── Test fixtures ───────────────────────────────────────────────────────────

# A compliant resource change
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

# A resource missing the Name tag
missing_name_resource := {
    "address": "local_file.unnamed",
    "type": "local_file",
    "change": {
        "actions": ["create"],
        "after": {
            "filename": "./output/unnamed.conf",
            "file_permission": "0644",
            "tags": {
                "Environment": "dev",
                "ManagedBy":   "terraform"
            }
        }
    }
}

# A resource with an invalid Name tag format
bad_name_resource := {
    "address": "local_file.bad_name",
    "type": "local_file",
    "change": {
        "actions": ["create"],
        "after": {
            "filename": "./output/bad.conf",
            "file_permission": "0644",
            "tags": {
                "Name":        "MyConfig",
                "Environment": "dev",
                "ManagedBy":   "terraform"
            }
        }
    }
}

# A resource with an invalid Environment tag
bad_env_resource := {
    "address": "local_file.bad_env",
    "type": "local_file",
    "change": {
        "actions": ["create"],
        "after": {
            "filename": "./output/bad-env.conf",
            "file_permission": "0644",
            "tags": {
                "Name":        "dev-file-config",
                "Environment": "production",
                "ManagedBy":   "terraform"
            }
        }
    }
}

# ─── Tests ───────────────────────────────────────────────────────────────────

test_compliant_resource_has_no_violations if {
    count(violations) == 0 with input as {"resource_changes": [compliant_resource]}
}

test_missing_name_tag_is_violation if {
    count(violations) == 1 with input as {"resource_changes": [missing_name_resource]}
}

test_bad_name_format_is_violation if {
    some v in violations with input as {"resource_changes": [bad_name_resource]}
    contains(v, "invalid Name tag")
}

test_bad_environment_is_violation if {
    some v in violations with input as {"resource_changes": [bad_env_resource]}
    contains(v, "invalid Environment tag")
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

test_allow_is_true_when_no_violations if {
    allow with input as {"resource_changes": [compliant_resource]}
}

test_allow_is_false_when_violations_exist if {
    not allow with input as {"resource_changes": [missing_name_resource]}
}
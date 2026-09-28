package terraform.libvirt.lib_test

import data.terraform.libvirt.lib

rc(address, actions) := {
	"address": address,
	"mode": "managed",
	"type": "libvirt_domain",
	"change": {"actions": actions, "after": {"name": "dev-web"}},
}

test_changes_skips_deletes_and_no_ops if {
	plan := {"resource_changes": [
		rc("a.create", ["create"]),
		rc("b.update", ["update"]),
		rc("c.replace", ["delete", "create"]),
		rc("d.delete", ["delete"]),
		rc("e.noop", ["no-op"]),
	]}

	addresses := {c.address | some c in lib.changes} with input as plan

	addresses == {"a.create", "b.update", "c.replace"}
}

test_changes_skips_data_sources if {
	data_source := object.union(rc("data.x", ["read"]), {"mode": "data"})

	count(lib.changes) == 0 with input as {"resource_changes": [data_source]}
}

test_plan_wrapped_by_hcp_terraform if {
	# HCP Terraform passes {"plan": <plan>, "run": {...}}
	wrapped := {"plan": {"resource_changes": [rc("a", ["create"])]}, "run": {}}

	count(lib.changes) == 1 with input as wrapped
}

test_mib_converts_units if {
	lib.mib(2, "GiB") == 2048
	lib.mib(2097152, "KiB") == 2048
	lib.mib(1073741824, "bytes") == 1024
}

test_unit_defaults_when_null if {
	lib.unit(null, "KiB") == "KiB"
	lib.unit("MiB", "KiB") == "MiB"
}

test_unit_undefined_when_unknown if {
	not lib.unit("gigs", "KiB")
}

test_environment_is_first_part_of_name if {
	lib.environment("prod-web-01") == "prod"
}

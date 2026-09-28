# METADATA
# title: Shared helpers
# description: Helpers used by all the libvirt policies. No rules of its own.
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

# Bytes per unit, as libvirt understands them
# (https://libvirt.org/formatdomain.html#memory-allocation)
unit_bytes := {
	"b": 1,
	"bytes": 1,
	"KB": 1000,
	"k": 1024,
	"KiB": 1024,
	"MB": 1000000,
	"M": 1048576,
	"MiB": 1048576,
	"GB": 1000000000,
	"G": 1073741824,
	"GiB": 1073741824,
	"TB": 1000000000000,
	"T": 1099511627776,
	"TiB": 1099511627776,
}

# The unit, or libvirt's default when the configuration leaves it out.
# Undefined for a unit libvirt doesn't know.
unit(value, _) := value if value in object.keys(unit_bytes)

unit(null, default_unit) := default_unit

# A size in MiB, whatever unit it was written in:
# memory = 2 with memory_unit = "GiB" is the same VM as memory = 2048 in MiB.
mib(value, unit_name) := (value * unit_bytes[unit_name]) / unit_bytes.MiB

# The environment is the first part of a name: prod-web -> prod
environment(name) := split(name, "-")[0]

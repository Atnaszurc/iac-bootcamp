package terraform.libvirt.resources_test

import data.terraform.libvirt.resources

plan_with(type, after) := {"resource_changes": [{
	"address": sprintf("%s.this", [type]),
	"mode": "managed",
	"type": type,
	"change": {"actions": ["create"], "after": after},
}]}

vm(name, memory, unit, vcpu) := plan_with(
	"libvirt_domain",
	{"name": name, "memory": memory, "memory_unit": unit, "vcpu": vcpu},
)

volume(capacity, unit) := plan_with("libvirt_volume", {"capacity": capacity, "capacity_unit": unit})

test_vm_within_limits if {
	count(resources.deny) == 0 with input as vm("dev-web", 1024, "MiB", 1)
}

test_units_are_normalised if {
	# 2 GiB is 2048 MiB: enough for production
	count(resources.deny) == 0 with input as vm("prod-web", 2, "GiB", 2)
}

test_default_unit_is_kib if {
	# No memory_unit: libvirt reads 2097152 as KiB, which is 2048 MiB
	count(resources.deny) == 0 with input as vm("prod-web", 2097152, null, 2)
}

test_default_unit_is_not_mib if {
	# The classic mistake: memory = 2048 without a unit is 2 MiB, not 2 GiB
	plan := vm("dev-web", 2048, null, 1)

	resources.deny == {"libvirt_domain.this: 2 MiB of memory is below the minimum of 512 MiB"} with input as plan
}

test_unknown_unit if {
	resources.deny == {`libvirt_domain.this: unknown memory_unit "gigs"`} with input as vm("dev-web", 2, "gigs", 1)
}

test_memory_above_maximum if {
	plan := vm("dev-web", 32, "GiB", 1)

	resources.deny == {"libvirt_domain.this: 32768 MiB of memory is above the maximum of 16384 MiB"} with input as plan
}

test_vcpu_above_maximum if {
	plan := vm("dev-web", 1024, "MiB", 12)

	resources.deny == {"libvirt_domain.this: 12 vCPUs is above the maximum of 8"} with input as plan
}

test_production_minimums if {
	resources.deny == {
		"libvirt_domain.this: production VMs need at least 2048 MiB of memory (has 1024)",
		"libvirt_domain.this: production VMs need at least 2 vCPUs (has 1)",
	} with input as vm("prod-web", 1, "GiB", 1)
}

test_production_minimums_only_for_prod if {
	count(resources.deny) == 0 with input as vm("staging-web", 1, "GiB", 1)
}

test_disk_size if {
	count(resources.deny) == 0 with input as volume(100, "GiB")

	resources.deny == {"libvirt_volume.this: 250 GiB disk is above the maximum of 100 GiB"} with input as volume(
		250,
		"GiB",
	)
}

test_disk_default_unit_is_bytes if {
	# 200 GiB in bytes
	count(resources.deny) == 1 with input as volume(214748364800, null)
}

test_many_vcpus_warn_but_do_not_deny if {
	plan := vm("dev-build", 4, "GiB", 6)

	count(resources.deny) == 0 with input as plan
	resources.warn == {"libvirt_domain.this: 6 vCPUs, are you sure? Most lab VMs need 4 or fewer"} with input as plan
}

# METADATA
# title: Resource limits
# description: |
#   Keep VMs and disks within what the lab hosts can run. Sizes are compared
#   in MiB, whatever unit the configuration used.
package terraform.libvirt.resources

import data.terraform.libvirt.lib

limits := {
	"memory_min_mib": 512,
	"memory_max_mib": 16384,
	"prod_memory_min_mib": 2048,
	"vcpu_max": 8,
	"prod_vcpu_min": 2,
	"vcpu_warn": 4,
	"disk_max_gib": 100,
}

# VMs in the plan, with their memory in MiB. libvirt's default unit is KiB.
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

# METADATA
# title: Known units
# entrypoint: true
# description: |
#   With a unit this policy doesn't know, the VM's memory is undefined, and
#   every rule below would silently pass it. So an unknown unit is a violation.
deny contains msg if {
	some rc in lib.changes
	rc.type == "libvirt_domain"
	not lib.unit(rc.change.after.memory_unit, "KiB")

	msg := sprintf("%s: unknown memory_unit %q", [rc.address, rc.change.after.memory_unit])
}

# METADATA
# title: Memory range
deny contains msg if {
	some vm in vms
	vm.memory_mib < limits.memory_min_mib
	msg := sprintf(
		"%s: %d MiB of memory is below the minimum of %d MiB",
		[vm.address, vm.memory_mib, limits.memory_min_mib],
	)
}

deny contains msg if {
	some vm in vms
	vm.memory_mib > limits.memory_max_mib
	msg := sprintf(
		"%s: %d MiB of memory is above the maximum of %d MiB",
		[vm.address, vm.memory_mib, limits.memory_max_mib],
	)
}

# METADATA
# title: vCPU maximum
deny contains msg if {
	some vm in vms
	vm.vcpu > limits.vcpu_max
	msg := sprintf("%s: %d vCPUs is above the maximum of %d", [vm.address, vm.vcpu, limits.vcpu_max])
}

# METADATA
# title: Production minimums
deny contains msg if {
	some vm in vms
	lib.environment(vm.name) == "prod"
	vm.memory_mib < limits.prod_memory_min_mib
	msg := sprintf(
		"%s: production VMs need at least %d MiB of memory (has %d)",
		[vm.address, limits.prod_memory_min_mib, vm.memory_mib],
	)
}

deny contains msg if {
	some vm in vms
	lib.environment(vm.name) == "prod"
	vm.vcpu < limits.prod_vcpu_min
	msg := sprintf(
		"%s: production VMs need at least %d vCPUs (has %d)",
		[vm.address, limits.prod_vcpu_min, vm.vcpu],
	)
}

# METADATA
# title: Disk size
# description: Volume capacity is in bytes unless capacity_unit says otherwise
deny contains msg if {
	some rc in lib.changes
	rc.type == "libvirt_volume"
	unit := lib.unit(rc.change.after.capacity_unit, "bytes")
	gib := lib.mib(rc.change.after.capacity, unit) / 1024
	gib > limits.disk_max_gib
	msg := sprintf("%s: %v GiB disk is above the maximum of %d GiB", [rc.address, gib, limits.disk_max_gib])
}

# METADATA
# title: Many vCPUs (advisory)
# description: Allowed, but worth a second look
warn contains msg if {
	some vm in vms
	vm.vcpu > limits.vcpu_warn
	msg := sprintf(
		"%s: %d vCPUs, are you sure? Most lab VMs need %d or fewer",
		[vm.address, vm.vcpu, limits.vcpu_warn],
	)
}

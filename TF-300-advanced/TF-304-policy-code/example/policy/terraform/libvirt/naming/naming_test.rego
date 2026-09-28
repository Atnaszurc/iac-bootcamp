package terraform.libvirt.naming_test

import data.terraform.libvirt.naming

# A plan with one resource being created
plan_with(type, after) := {"resource_changes": [{
	"address": sprintf("%s.this", [type]),
	"mode": "managed",
	"type": type,
	"change": {"actions": ["create"], "after": after},
}]}

vm(name) := plan_with("libvirt_domain", {"name": name, "description": "owner=platform environment=prod"})

test_good_vm_name if {
	count(naming.deny) == 0 with input as vm("prod-web-01")
}

test_vm_name_with_uppercase_and_underscore if {
	naming.deny == {
		`libvirt_domain.this: VM name "prod-Batch_01" must be <environment>-<name> in lowercase, like prod-web`,
	} with input as vm("prod-Batch_01")
}

test_vm_name_without_environment if {
	count(naming.deny) == 1 with input as vm("web")
}

test_vm_name_with_unknown_environment if {
	count(naming.deny) == 1 with input as vm("test-web")
}

test_network_name if {
	count(naming.deny) == 0 with input as plan_with("libvirt_network", {"name": "net-dev-app"})

	naming.deny == {
		`libvirt_network.this: network name "prod-app" must be net-<environment>-<name>, like net-prod-app`,
	} with input as plan_with("libvirt_network", {"name": "prod-app"})
}

test_vm_without_owner if {
	naming.deny == {"libvirt_domain.this: the description must contain owner=<team>"} with input as plan_with(
		"libvirt_domain",
		{"name": "dev-web", "description": "environment=dev"},
	)
}

test_vm_with_empty_owner if {
	count(naming.deny) == 1 with input as plan_with("libvirt_domain", {"name": "dev-web", "description": "owner= x"})
}

test_vm_without_description if {
	# description isn't set at all: null in the plan
	count(naming.deny) == 1 with input as plan_with("libvirt_domain", {"name": "dev-web", "description": null})
}

package terraform.libvirt.network_test

import data.terraform.libvirt.network

change(type, name, after) := {
	"address": sprintf("%s.%s", [type, name]),
	"mode": "managed",
	"type": type,
	"change": {"actions": ["create"], "after": after},
}

network_change(name, mode) := change("libvirt_network", name, {"name": name, "forward": {"mode": mode}})

isolated_net(name) := change("libvirt_network", name, {"name": name, "forward": null})

vm_on(network_name) := change(
	"libvirt_domain",
	"vm",
	{"name": "dev-web", "devices": {"interfaces": [{"source": {"network": {"network": network_name}}}]}},
)

test_nat_network if {
	count(network.deny) == 0 with input as {"resource_changes": [network_change("net-dev-app", "nat")]}
}

test_network_without_forward_is_isolated if {
	count(network.deny) == 0 with input as {"resource_changes": [isolated_net("net-dev-lab")]}
}

test_open_network if {
	network.deny == {
		`libvirt_network.net-dev-app: forward mode "open" is not allowed, use one of ["nat", "route", "isolated"]`,
	} with input as {"resource_changes": [network_change("net-dev-app", "open")]}
}

test_allowed_modes_come_from_data if {
	count(network.deny) == 0 with input as {"resource_changes": [network_change("net-dev-app", "open")]}
		with data.config.allowed_forward_modes as ["open"]
}

test_vm_on_network_in_plan if {
	plan := {"resource_changes": [network_change("net-dev-app", "nat"), vm_on("net-dev-app")]}

	count(network.deny) == 0 with input as plan
}

test_vm_on_existing_network_in_plan if {
	# The network already exists: its action is no-op
	existing := object.union(network_change("net-dev-app", "nat"), {"change": {"actions": ["no-op"]}})
	plan := {"resource_changes": [existing, vm_on("net-dev-app")]}

	count(network.deny) == 0 with input as plan
}

test_vm_on_network_being_deleted if {
	deleted := object.union(
		network_change("net-dev-app", "nat"),
		{"change": {"actions": ["delete"], "after": null}},
	)
	plan := {"resource_changes": [deleted, vm_on("net-dev-app")]}

	count(network.deny) == 1 with input as plan
}

test_vm_on_shared_network if {
	count(network.deny) == 0 with input as {"resource_changes": [vm_on("default")]}
}

test_vm_on_unknown_network if {
	network.deny == {
		`libvirt_domain.vm: network "legacy-lab" is neither in this plan nor a shared network ["default"]`,
	} with input as {"resource_changes": [network_change("net-dev-app", "nat"), vm_on("legacy-lab")]}
}

# METADATA
# title: Networks
# description: |
#   Networks use an approved forward mode, and VMs only join networks that are
#   in the same plan or on the list of shared networks.
package terraform.libvirt.network

import data.config
import data.terraform.libvirt.lib

# A network without a forward block is isolated
forward_mode(network) := object.get(network, ["forward", "mode"], "isolated")

# Networks a VM may join: the ones in this plan, and the shared ones.
# All of the plan, not just lib.changes: a network that already exists is a
# no-op, and VMs can still join it. A network being deleted has no `after`,
# so it isn't included.
known_networks contains name if {
	some rc in lib.plan.resource_changes
	rc.mode == "managed"
	rc.type == "libvirt_network"
	name := rc.change.after.name
}

known_networks contains name if some name in config.shared_networks

# METADATA
# title: Forward mode
# entrypoint: true
deny contains msg if {
	some rc in lib.changes
	rc.type == "libvirt_network"
	mode := forward_mode(rc.change.after)
	not mode in config.allowed_forward_modes

	msg := sprintf(
		"%s: forward mode %q is not allowed, use one of %v",
		[rc.address, mode, config.allowed_forward_modes],
	)
}

# METADATA
# title: VM networks
deny contains msg if {
	some rc in lib.changes
	rc.type == "libvirt_domain"
	some interface in rc.change.after.devices.interfaces
	name := interface.source.network.network
	not name in known_networks

	msg := sprintf(
		"%s: network %q is neither in this plan nor a shared network %v",
		[rc.address, name, config.shared_networks],
	)
}

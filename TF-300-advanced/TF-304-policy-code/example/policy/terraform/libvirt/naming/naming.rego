# METADATA
# title: Naming and ownership
# description: |
#   Names say which environment a resource belongs to, and every VM says who
#   owns it. libvirt has no tags, so ownership goes in the VM's description.
package terraform.libvirt.naming

import data.terraform.libvirt.lib

vm_name_pattern := `^(dev|staging|prod)(-[a-z0-9]+)+$`

network_name_pattern := `^net-(dev|staging|prod)(-[a-z0-9]+)+$`

# METADATA
# title: VM names
# entrypoint: true
# description: <environment>-<name>, lowercase letters, digits and dashes
deny contains msg if {
	some rc in lib.changes
	rc.type == "libvirt_domain"
	not regex.match(vm_name_pattern, rc.change.after.name)

	msg := sprintf(
		"%s: VM name %q must be <environment>-<name> in lowercase, like prod-web",
		[rc.address, rc.change.after.name],
	)
}

# METADATA
# title: Network names
# description: net-<environment>-<name>
deny contains msg if {
	some rc in lib.changes
	rc.type == "libvirt_network"
	not regex.match(network_name_pattern, rc.change.after.name)

	msg := sprintf(
		"%s: network name %q must be net-<environment>-<name>, like net-prod-app",
		[rc.address, rc.change.after.name],
	)
}

# METADATA
# title: VM owner
# description: The description must contain owner=<team>
deny contains msg if {
	some rc in lib.changes
	rc.type == "libvirt_domain"
	not has_owner(rc.change.after.description)

	msg := sprintf("%s: the description must contain owner=<team>", [rc.address])
}

has_owner(description) if regex.match(`(^|\s)owner=\S+`, description)

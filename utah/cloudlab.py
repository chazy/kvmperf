import geni.portal as portal
import geni.rspec.pg as RSpec

# Creates 4 nodes: 1 client node, 1 bare-metal node, 1 KVM node, 1 Xen node

# Instantiate and connect to the individual nodes and run experiments:
# - on the bare-metal node, run "cd /srv/vm && sudo ./consume-mem.sh"
# - on the xen node, run "cd /srv/vm && sudo ./net.sh && sudo ./create_domU.sh"
# - on the kvm node, run "cd /srv/vm && sudo ./net.sh"

# The Xen and KVM nodes have only the internet IP adapter starting up
# automatically. Login to the nodes and do ifup eth1 to configure the
# private ones.


# Initial setup, parameter passing
pc = portal.Context()

params = pc.bindParameters()

rspec = RSpec.Request()

# kvmarm-3.18-measure disk image URL
kvm_disk_image = "https://www.utah.cloudlab.us/image_metadata.php?uuid=984d5c44-ce43-11e4-bc0b-020cbce70073"
# kvmarm-3.18-xen-measure disk image URL
xen_disk_image = "https://www.utah.cloudlab.us/image_metadata.php?uuid=6b848a4c-ce47-11e4-bc0b-020cbce70073"
# kvmarm-3.18-measure-bm disk image URL
bm_disk_image = "https://www.utah.cloudlab.us/image_metadata.php?uuid=9f549410-ce44-11e4-9fb8-3548323d6d11"

# Create private LAN
lan = RSpec.LAN()
rspec.addResource(lan)

# Create Client node
# IP will be 10.10.1.1
node = RSpec.RawPC("client-node")
node.hardware_type = "m400"
node.disk_image = kvm_disk_image
rspec.addResource(node)
iface = node.addInterface("eth1")
lan.addInterface(iface)

# Create Xen node
# IP will be 10.10.1.2
node = RSpec.RawPC("xen-node")
node.hardware_type = "m400"
node.disk_image =xen_disk_image
rspec.addResource(node)
iface = node.addInterface("eth1")
lan.addInterface(iface)

# Create KVM node
# IP will be 10.10.1.3
node = RSpec.RawPC("kvm-node")
node.hardware_type = "m400"
node.disk_image = kvm_disk_image
rspec.addResource(node)
iface = node.addInterface("eth1")
lan.addInterface(iface)

# Create Bare-Metal node
# IP will be 10.10.1.4
node = RSpec.RawPC("bm-node")
node.hardware_type = "m400"
node.disk_image = bm_disk_image
rspec.addResource(node)
iface = node.addInterface("eth1")
lan.addInterface(iface)


pc.printRequestRSpec(rspec)

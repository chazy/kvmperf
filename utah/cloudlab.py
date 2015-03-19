import geni.portal as portal
import geni.rspec.pg as RSpec


# Initial setup, parameter passing
configs = [("both", "1 Xen, 1 KVM, and 1 client node"),
           ("xen", "1 Xen node and 1 client node"),
           ("kvm", "1 KVM node and 1 client node")]

pc = portal.Context()

pc.defineParameter("config", "Desired configuration",
                   portal.ParameterType.NODETYPE, "both", configs)


params = pc.bindParameters()

rspec = RSpec.Request()

# kvmarm-3.18-measure disk image URL
kvm_disk_image = "https://www.utah.cloudlab.us/image_metadata.php?uuid=89e729ae-cd87-11e4-9fb8-3548323d6d11"
# kvmarm-3.18-xen-measure disk image URL
xen_disk_image = "https://www.utah.cloudlab.us/image_metadata.php?uuid=2221ca56-ce29-11e4-bc0b-020cbce70073"

# Create private LAN
lan = RSpec.LAN()
rspec.addResource(lan)

# Parse parameter results
client = True
if params.config == "both":
    xen = True
    kvm = True
elif params.config == "xen":
    xen = True
    kvm = False
elif params.config == "kvm":
    xen = False
    kvm = True
else:
    xen = False
    kvm = False


# Create Client node
if client:
    node = RSpec.RawPC("client-node")
    node.hardware_type = "m400"
    node.disk_image = kvm_disk_image
    rspec.addResource(node)
    iface = node.addInterface("eth1")
    lan.addInterface(iface)

# Create Xen node
if xen:
    node = RSpec.RawPC("xen-node")
    node.hardware_type = "m400"
    node.disk_image =xen_disk_image
    rspec.addResource(node)
    iface = node.addInterface("eth1")
    lan.addInterface(iface)

# Create KVM node
if xen:
    node = RSpec.RawPC("kvm-node")
    node.hardware_type = "m400"
    node.disk_image = kvm_disk_image
    rspec.addResource(node)
    iface = node.addInterface("eth1")
    lan.addInterface(iface)


pc.printRequestRSpec(rspec)


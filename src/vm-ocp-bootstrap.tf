locals {
  ocp_bootstrap = {
    hostname = "bootstrap"
    fqdn     = format("bootstrap.%s", var.dns.domain)
    ip       = lookup(var.ocp_inventory, "bootstrap").ip
    mac      = lookup(var.ocp_inventory, "bootstrap").mac
    image    = format("images/rhcos-%s-x86_64-qemu.x86_64.qcow2", var.RHCOS_VERSION)
  }
}

module "ocp_bootstrap" {

  source = "./modules/ocp_node"

  id           = format("ocp-%s", local.ocp_bootstrap.hostname)
  fqdn         = local.ocp_bootstrap.fqdn
  ignition     = data.local_file.ocp_ignition_bootstrap.content
  cpu          = var.ocp_bootstrap.vcpu
  memory       = var.ocp_bootstrap.memory
  libvirt_pool = libvirt_pool.openshift.name
  os_image     = local.ocp_bootstrap.image
  disk_size    = var.ocp_bootstrap.size # Gigabytes
  network      = {
    name = libvirt_network.openshift.name
    ip   = local.ocp_bootstrap.ip
    mac  = local.ocp_bootstrap.mac
  }
}

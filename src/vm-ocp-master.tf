locals {
  ocp_master = [
    for index in range(var.ocp_cluster.num_masters) :
      {
        hostname = format("master%02d", index)
        fqdn     = format("master%02d.%s", index, var.dns.domain)
        ip       = lookup(var.ocp_inventory, format("master%02d", index)).ip
        mac      = lookup(var.ocp_inventory, format("master%02d", index)).mac
      }
  ]
}

module "ocp_master" {
  source       = "./modules/ocp_node"
  count        = var.ocp_cluster.num_masters
  id           = format("ocp-%s", local.ocp_master[count.index].hostname)
  fqdn         = local.ocp_master[count.index].fqdn
  ignition     = data.local_file.ocp_ignition_master.content
  cpu          = var.ocp_master.vcpu
  memory       = var.ocp_master.memory
  libvirt_pool = libvirt_pool.openshift.name
  os_image     = local.ocp_bootstrap.image
  disk_size    = var.ocp_master.size # Gigabytes
  network      = {
    name = libvirt_network.openshift.name
    ip   = local.ocp_master[count.index].ip
    mac  = local.ocp_master[count.index].mac
  }
}

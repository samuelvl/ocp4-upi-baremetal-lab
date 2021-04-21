locals {
  ocp_worker = [
    for index in range(var.ocp_cluster.num_workers) :
      {
        hostname = format("worker%02d", index)
        fqdn     = format("worker%02d.%s", index, var.dns.domain)
        ip       = lookup(var.ocp_inventory, format("worker%02d", index)).ip
        mac      = lookup(var.ocp_inventory, format("worker%02d", index)).mac
      }
  ]
}

resource "libvirt_volume" "ocp_worker_lso" {
  count  = var.ocp_cluster.num_workers
  name   = format("%s-lso-volume.qcow2",
    element(local.ocp_worker, count.index).hostname
  )
  pool   = libvirt_pool.openshift.name
  size   = 20 * 1073741824 # Bytes
  format = "qcow2"
}

module "ocp_worker" {
  source       = "./modules/ocp_node"
  count        = var.ocp_cluster.num_workers
  id           = format("ocp-%s", local.ocp_worker[count.index].hostname)
  fqdn         = local.ocp_worker[count.index].fqdn
  ignition     = data.local_file.ocp_ignition_worker.content
  cpu          = var.ocp_worker.vcpu
  memory       = var.ocp_worker.memory
  libvirt_pool = libvirt_pool.openshift.name
  os_image     = local.ocp_bootstrap.image
  disk_size    = var.ocp_worker.size # Gigabytes
  extra_disks  = [
    libvirt_volume.ocp_worker_lso[count.index].id
  ]
  network      = {
    name = libvirt_network.openshift.name
    ip   = local.ocp_worker[count.index].ip
    mac  = local.ocp_worker[count.index].mac
  }
}

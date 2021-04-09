locals {
  helper_node = {
    hostname = "helper"
    fqdn     = format("helper.%s", var.dns.domain)
    ip       = lookup(var.ocp_inventory, "helper").ip
    mac      = lookup(var.ocp_inventory, "helper").mac
  }

  registry = {
    hostname = "registry"
    fqdn     = format("registry.%s", var.dns.domain)
    address  = format("registry.%s:%s", var.dns.domain, var.registry.port_tls)
    ip       = lookup(var.ocp_inventory, "helper").ip
    mac      = lookup(var.ocp_inventory, "helper").mac
  }

  load_balancer = {
    hostname = "lb"
    fqdn     = format("lb.%s", var.dns.domain)
    ip       = lookup(var.ocp_inventory, "helper").ip
    mac      = lookup(var.ocp_inventory, "helper").mac
  }

}

resource "libvirt_ignition" "helper_node" {
  name    = format("%s.ign", local.helper_node.hostname)
  pool    = libvirt_pool.openshift.name
  content = data.ct_config.helper_node_ignition.rendered
}

resource "libvirt_volume" "helper_node_image" {
  name   = format("%s-baseimg.qcow2", local.helper_node.hostname)
  pool   = libvirt_pool.openshift.name
  source = var.helper_node.base_img
  format = "qcow2"
}

resource "libvirt_volume" "helper_node" {
  name           = format("%s-volume.qcow2", local.helper_node.hostname)
  pool           = libvirt_pool.openshift.name
  base_volume_id = libvirt_volume.helper_node_image.id
  format         = "qcow2"
  size           = var.helper_node.size * pow(10, 9) # Bytes
  depends_on     = [
    libvirt_ignition.helper_node
  ]
}

resource "libvirt_domain" "helper_node" {
  name    = format("ocp-%s", local.helper_node.hostname)
  memory  = var.helper_node.memory
  vcpu    = var.helper_node.vcpu
  running = true

  coreos_ignition = libvirt_ignition.helper_node.id

  disk {
    volume_id = libvirt_volume.helper_node.id
    scsi      = false
  }

  network_interface {
    network_name   = libvirt_network.openshift.name
    hostname       = format("%s.%s", local.helper_node.hostname, var.dns.domain)
    addresses      = [ local.helper_node.ip ]
    mac            = local.helper_node.mac
    wait_for_lease = true
  }

  console {
    type           = "pty"
    target_type    = "serial"
    target_port    = "0"
    source_host    = "127.0.0.1"
    source_service = "0"
  }

  graphics {
    type           = "spice"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  lifecycle {
    ignore_changes = [
      running,
      network_interface.0.addresses
    ]
  }

  provisioner "local-exec" {
    when    = destroy
    command = format("ssh-keygen -R %s", self.network_interface.0.hostname)
  }
}

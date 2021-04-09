resource "libvirt_domain" "ocp_node" {

  # Domain initial state
  name    = var.id
  running = false

  # Resources
  memory  = var.memory
  vcpu    = var.cpu

  cpu = {
    mode = "host-passthrough"
  }

  # Ignition
  coreos_ignition = libvirt_ignition.ocp_node.id

  # Storage
  dynamic "disk" {
    for_each = concat([libvirt_volume.ocp_node.id], var.extra_disks)
    content {
      volume_id = disk.value
      scsi      = true
    }
  }

  # Network
  network_interface {
    network_name = var.network.name
    hostname     = var.fqdn
    addresses    = [ var.network.ip ]
    mac          = var.network.mac
    wait_for_lease = true
  }

  # Serial
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
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

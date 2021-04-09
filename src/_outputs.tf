# Helper node
output "helper_node" {
  value = {
    fqdn    = local.helper_node.fqdn
    ip      = local.helper_node.ip
    ssh     = format("ssh -i %s maintuser@%s",
      local_file.ssh_maintuser_private_key.filename,
      local.helper_node.fqdn
    )
    metrics  = format("http://%s:5555/haproxy?stats",
      local.load_balancer.fqdn
    )
    registry = format("https://%s:%s",
      local.registry.fqdn,
      var.registry.port_tls
    )
  }
}

# OCP masters
output "masters" {
  value = {
    fqdn = local.ocp_master.*.fqdn
    ip   = local.ocp_master.*.ip
    ssh  = formatlist("ssh -i %s core@%s",
      local_file.ssh_maintuser_private_key.filename,
      local.ocp_master.*.fqdn
    )
  }
}

# OCP workers
output "workers" {
  value = {
    fqdn = local.ocp_worker.*.fqdn
    ip   = local.ocp_worker.*.ip
    ssh  = formatlist("ssh -i %s core@%s",
      local_file.ssh_maintuser_private_key.filename,
      local.ocp_worker.*.fqdn
    )
  }
}

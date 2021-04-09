data "ct_config" "helper_node_ignition" {
  content      = templatefile(
    format("%s/ignition/helper.yml.tpl", path.module),
    {
      fqdn               = local.helper_node.fqdn,
      ssh_pubkey         = trimspace(tls_private_key.ssh_maintuser.public_key_openssh),
      pull_secret        = local.ocp_pull_secret,
      haproxy_image      = var.load_balancer.image,
      haproxy_dns        = format("%s:53", var.network.gateway),
      ocp_bootstrap_node = local.ocp_bootstrap.fqdn,
      ocp_master_nodes   = local.ocp_master.*.fqdn,
      ocp_infra_nodes    = local.ocp_worker.*.fqdn,
      nfs_image          = var.nfs.image,
      quay_image         = var.registry.image,
      quay_host          = local.registry.fqdn,
      quay_user          = var.registry.user,
      quay_pass          = var.registry.password,
      quay_port          = var.registry.port,
      quay_port_tls      = var.registry.port_tls,
      quay_tls_cert      = indent(10, local.registry_tls.certificate),
      quay_tls_key       = indent(10, local.registry_tls.private_key),
      quay_ca_bundle     = indent(10, tls_self_signed_cert.ocp_root_ca.cert_pem),
      psql_image         = var.registry.db_image,
      psql_db            = var.registry.db_name,
      psql_user          = var.registry.db_user,
      psql_pass          = var.registry.db_pass,
      psql_port          = var.registry.db_port,
      redis_image        = var.registry.redis_image,
      redis_pass         = var.registry.redis_pass,
      redis_port         = var.registry.redis_port
    }
  )
  strict       = true
  pretty_print = true
}

resource "local_file" "helper_node_ignition_rendered_yaml" {
  count                = var.DEBUG ? 1 : 0
  filename             = format("output/ignition/helper-node.yml")
  content              = data.ct_config.helper_node_ignition.content
  file_permission      = "0600"
  directory_permission = "0700"

  lifecycle {
    ignore_changes = [
      content
    ]
  }
}

resource "local_file" "helper_node_ignition_rendered_json" {
  count                = var.DEBUG ? 1 : 0
  filename             = format("output/ignition/helper-node.json")
  content              = data.ct_config.helper_node_ignition.rendered
  file_permission      = "0600"
  directory_permission = "0700"

  lifecycle {
    ignore_changes = [
      content
    ]
  }
}

locals {
  ocp_installer = {
    release      = join(".", slice(split(".", var.OCP_VERSION), 0, 2)) # e.g. 4.1.0 -> 4.1
    version_arch = format("%s-x86_64", var.OCP_VERSION)
    path         = format("output/openshift-install/%s", var.OCP_ENVIRONMENT)
  }
}

resource "local_file" "ocp_install_mirror_release_image" {
  filename             = format("%s/mirror-release-image.sh",
    local.ocp_installer.path
  )
  file_permission      = "0744"
  directory_permission = "0755"
  content              = <<-EOF
    #!/usr/bin/env bash

    # Mirror release images
    oc adm release mirror \
      --registry-config=${local_file.ocp_pull_secret.filename} \
      --from=quay.io/openshift-release-dev/ocp-release:${local.ocp_installer.version_arch} \
      --to=${local.registry.address}/${var.registry.repository} \
      --insecure=true
  EOF
}

data "template_file" "ocp_install_config" {
  template = file(format("%s/openshift-install/%s/install-config.yaml.tpl",
    path.module,
    local.ocp_installer.release
  ))

  vars = {
    ocp_cluster_name    = var.ocp_cluster.name
    ocp_dns_domain      = var.ocp_cluster.dns_domain
    ocp_nodes_cidr      = var.network.subnet
    ocp_pods_cidr       = var.ocp_cluster.pods_cidr
    ocp_pods_range      = var.ocp_cluster.pods_range
    ocp_svcs_cidr       = var.ocp_cluster.svcs_cidr
    ocp_registry_mirror = format("%s/%s",
      local.registry.address,
      var.registry.repository
    )
    ocp_pull_secret     = local.ocp_pull_secret
    ocp_ssh_pubkey      = trimspace(tls_private_key.ssh_maintuser.public_key_openssh)
    ocp_additional_ca   = indent(2, tls_self_signed_cert.ocp_root_ca.cert_pem)
  }
}

resource "local_file" "ocp_install_config" {
  filename             = format("%s/install-config.yaml",
    local.ocp_installer.path
  )
  content              = data.template_file.ocp_install_config.rendered
  file_permission      = "0600"
  directory_permission = "0700"

  provisioner "local-exec" {
    command = <<-EOF
      if [ ! -f "${local.ocp_installer.path}/master.ign" ]; then
          # Generate ignitions files from manifests
          ./openshift-install create ignition-configs --dir=${local.ocp_installer.path}
      fi
    EOF
  }
}

resource "local_file" "ocp_install_config_backup" {
  filename             = format("%s/install-config.yaml.backup",
    local.ocp_installer.path
  )
  content              = data.template_file.ocp_install_config.rendered
  file_permission      = "0600"
  directory_permission = "0700"
}

data "local_file" "ocp_ignition_bootstrap" {
  filename = format("%s/bootstrap.ign", local.ocp_installer.path)

  depends_on = [
    local_file.ocp_install_config
  ]
}

data "local_file" "ocp_ignition_master" {
  filename = format("%s/master.ign", local.ocp_installer.path)

  depends_on = [
    local_file.ocp_install_config
  ]
}

data "local_file" "ocp_ignition_worker" {
  filename = format("%s/worker.ign", local.ocp_installer.path)

  depends_on = [
    local_file.ocp_install_config
  ]
}

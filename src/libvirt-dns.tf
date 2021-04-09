data "template_file" "openshift_dnsmasq" {

  template = file(format("%s/dns/openshift_dnsmasq.conf", path.module))

  vars = {
    dns_internal_zone   = var.dns.domain
    dns_internal_server = var.network.gateway
    ocp_apps_domain     = format("apps.%s", var.dns.domain)
    ocp_apps_lb         = local.load_balancer.ip
  }
}

resource "local_file" "nm_enable_dnsmasq" {
  filename             = "/etc/NetworkManager/conf.d/nm_enable_dnsmasq.conf"
  content              = file(format("%s/dns/nm_enable_dnsmasq.conf",
    path.module
  ))
  file_permission      = "0666"
  directory_permission = "0755"
}

resource "local_file" "openshift_dnsmasq" {
  filename             = "/etc/NetworkManager/dnsmasq.d/openshift_dnsmasq.conf"
  content              = data.template_file.openshift_dnsmasq.rendered
  file_permission      = "0666"
  directory_permission = "0755"

  provisioner "local-exec" {
    command = "sudo systemctl restart NetworkManager"
  }

  depends_on = [
    local_file.nm_enable_dnsmasq
  ]
}

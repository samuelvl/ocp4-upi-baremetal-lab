libvirt = {
  pool      = "openshift"
  pool_path = "/var/lib/libvirt/images/openshift"
}

network = {
  name    = "openshift"
  subnet  = "10.0.0.0/24"
  gateway = "10.0.0.1"
}

dns = {
  domain = "ocp.bmlab.int"
  server = "10.0.0.1"
}

ocp_cluster = {
  name          = "ocp"
  dns_domain    = "bmlab.int"
  pods_cidr     = "172.0.0.0/16"
  pods_range    = 24
  svcs_cidr     = "172.255.0.0/16"
  num_masters   = 3
  num_workers   = 3
  operators     = [
    "red-hat-quay"
  ]
}

ocp_inventory = {
  "helper" = {
    ip  = "10.0.0.250"
    mac = "0A:00:00:00:00:00"
  }
  "bootstrap" = {
    ip  = "10.0.0.10"
    mac = "AA:00:00:00:00:10"
  }
  "master00" = {
    ip  = "10.0.0.11"
    mac = "AA:00:00:00:00:11"
  }
  "master01" = {
    ip  = "10.0.0.12"
    mac = "AA:00:00:00:00:12"
  }
  "master02" = {
    ip  = "10.0.0.13"
    mac = "AA:00:00:00:00:13"
  }
  "worker00" = {
    ip  = "10.0.0.101"
    mac = "AA:00:00:00:01:01"
  }
  "worker01" = {
    ip  = "10.0.0.102"
    mac = "AA:00:00:00:01:02"
  }
  "worker02" = {
    ip  = "10.0.0.103"
    mac = "AA:00:00:00:01:03"
  }
}

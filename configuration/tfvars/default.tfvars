helper_node = {
  id       = "helper"
  base_img = "images/fedora-coreos-32.20200629.3.0.x86_64.qcow2"
  vcpu     = 4
  memory   = 8192
  size     = 200 # Gigabytes
}

load_balancer = {
  type  = "haproxy"
  image = "docker.io/haproxy:2.0.14"
}

registry = {
  image       = "registry.redhat.io/quay/quay-rhel8:v3.4.3"
  user        = "openshift4"
  password    = "changeme"
  repository  = "openshift4/images"
  port        = 5080
  port_tls    = 5443
  db_image    = "registry.redhat.io/rhel8/postgresql-10:1-123"
  db_name     = "quay"
  db_user     = "quayuser"
  db_pass     = "changeme"
  db_port     = 5432
  redis_image = "registry.redhat.io/rhel8/redis-5:1-110"
  redis_pass  = "changeme"
  redis_port  = 6379
}

nfs = {
  image = "docker.io/gists/nfs-server:2.4.3"
}

ocp_bootstrap = {
  id       = "bootstrap"
  base_img = "images/rhcos-4.6.8-x86_64-qemu.x86_64.qcow2"
  vcpu     = 4
  memory   = 8192
  size     = 60 # Gigabytes
}

ocp_master = {
  id       = "master"
  vcpu     = 4
  memory   = 16384
  size     = 120 # Gigabytes
}

ocp_worker = {
  id       = "worker"
  vcpu     = 4
  memory   = 8192
  size     = 200 # Gigabytes
}

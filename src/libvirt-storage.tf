locals {
  libvirt_pool_path = (
    # if var.libvirt.pool_path is absolute_path
    substr(var.libvirt.pool_path, 0, 1) == "/" ?
      var.libvirt.pool_path : format("%s/%s",
        abspath(path.module),
        var.libvirt.pool_path
      )
  )
}

resource "libvirt_pool" "openshift" {
  name = var.libvirt.pool
  type = "dir"
  path = local.libvirt_pool_path
}

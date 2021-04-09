locals {
  olm = {
    path        = "day-two/02-olm"
    repository  = "openshift4"
    version     = format("%s-v1", local.ocp_installer.release)
  }
  olm_catalogs = [
    {
      id          = "redhat-operators-disconnected"
      description = "Red Hat Operators (Disconnected)"
      publisher   = "Disconnected"
      repository  = format("%s", local.registry.address)
      image       = format("%s/%s/olm-redhat-operator-index:v%s",
        local.registry.address, local.olm.repository, local.olm.version)
    },
    {
      id          = "certified-operators-disconnected"
      description = "Certified Operators (Disconnected)"
      publisher   = "Disconnected"
      repository  = format("%s", local.registry.address)
      image       = format("%s/%s/olm-certified-operator-index:v%s",
        local.registry.address, local.olm.repository, local.olm.version)
    },
    {
      id          = "community-operators-disconnected"
      description = "Community Operators (Disconnected)"
      publisher   = "Disconnected"
      repository  = format("%s", local.registry.address)
      image       = format("%s/%s/olm-community-operator-index:v%s",
        local.registry.address, local.olm.repository, local.olm.version)
    },
    {
      id          = "redhat-marketplace-disconnected"
      description = "Red Hat Marketplace (Disconnected)"
      publisher   = "Disconnected"
      repository  = format("%s", local.registry.address)
      image       = format("%s/%s/olm-redhat-marketplace-index:v%s",
        local.registry.address, local.olm.repository, local.olm.version)
    }
  ]
}

resource "local_file" "olm_catalog_source" {
  count                = length(local.olm_catalogs)
  filename             = format("%s/catalog-source/%s/%s.yml",
    local.olm.path, var.OCP_ENVIRONMENT, local.olm_catalogs[count.index].id)
  file_permission      = "0644"
  directory_permission = "0755"
  content              = <<-EOF
    apiVersion: operators.coreos.com/v1alpha1
    kind: CatalogSource
    metadata:
      name: ${local.olm_catalogs[count.index].id}
      namespace: openshift-marketplace
    spec:
      displayName: ${local.olm_catalogs[count.index].description}
      image: ${local.olm_catalogs[count.index].image}
      sourceType: grpc
      publisher: ${local.olm_catalogs[count.index].publisher}
    updateStrategy:
      registryPoll: 
        interval: 8h
  EOF
}

resource "local_file" "olm_environment_config" {
  filename             = format("%s/environment/%s.env",
    local.olm.path,
    var.OCP_ENVIRONMENT
  )
  file_permission      = "0644"
  directory_permission = "0755"
  content              = <<-EOF
    OCP_RELEASE="${local.ocp_installer.release}"
    %{ for catalog in local.olm_catalogs }
    ${replace(upper(catalog.id), "-", "_")}_IMAGE="${catalog.image}"
    ${replace(upper(catalog.id), "-", "_")}_REPO="${catalog.repository}"
    %{ endfor }
  EOF
}

# Enable debug mode
variable "DEBUG" {
  description = "Enable debug mode"
  type        = bool
  default     = false
}

# Openshift version
variable "OCP_VERSION" {
  description = "Openshift version"
  type        = string
}

# Openshift environment
variable "OCP_ENVIRONMENT" {
  description = "Openshift environment"
  type        = string
}

# Libvirt configuration
variable "libvirt" {
  description = "Libvirt configuration"
  type = object({
    pool      = string,
    pool_path = string
  })
}

variable "network" {
  description = "Network configuration"
  type = object({
    name    = string,
    subnet  = string,
    gateway = string
  })
}

# DNS configuration
variable "dns" {
  description = "DNS configuration"
  type = object({
    domain = string,
    server = string
  })
}

# Openshift cluster information
variable "ocp_cluster" {
  description = "Openshift cluster information"
  type        = object({
    name          = string,
    dns_domain    = string,
    pods_cidr     = string,
    pods_range    = number,
    svcs_cidr     = string,
    num_masters   = number,
    num_workers   = number,
    operators     = list(string),
  })
}

# Openshift inventory
variable "ocp_inventory" {
  description = "List of Openshift cluster nodes"
  type        = map(object({
    ip  = string,
    mac = string
  }))
}

# Helper node specification
variable "helper_node" {
  description = "Configuration for helper node virtual machine"
  type = object({
    id       = string,
    base_img = string,
    vcpu     = number,
    memory   = number,
    size     = number
  })
}

# Load balancer specification
variable "load_balancer" {
  description = "Configuration for load balancer virtual machine"
  type = object({
    type  = string,
    image = string
  })
}

# Quay specification
variable "registry" {
  description = "Configuration for quay virtual machine"
  type = object({
    image       = string,
    user        = string,
    password    = string,
    repository  = string,
    port        = number,
    port_tls    = number,
    db_image    = string,
    db_name     = string,
    db_user     = string,
    db_pass     = string,
    db_port     = number,
    redis_image = string,
    redis_pass  = string,
    redis_port  = number
  })
}

# NFS specification
variable "nfs" {
  description = "Configuration for NFS virtual machine"
  type = object({
    image = string
  })
}

# Openshift bootstrap specification
variable "ocp_bootstrap" {
  description = "Configuration for Openshift bootstrap virtual machine"
  type = object({
    id       = string,
    base_img = string,
    vcpu     = number,
    memory   = number,
    size     = number
  })
}

# Openshift masters specification
variable "ocp_master" {
  description = "Configuration for Openshift master virtual machine"
  type = object({
    id       = string,
    vcpu     = number,
    memory   = number,
    size     = number
  })
}

# Openshift workers specification
variable "ocp_worker" {
  description = "Configuration for Openshift worker virtual machine"
  type = object({
    id       = string,
    vcpu     = number,
    memory   = number,
    size     = number
  })
}

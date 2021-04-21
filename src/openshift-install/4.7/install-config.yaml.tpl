apiVersion: v1
metadata:
  name: ${ocp_cluster_name}
baseDomain: ${ocp_dns_domain}
controlPlane:
  name: master
  hyperthreading: Enabled
  replicas: 3
compute:
  - name: worker
    hyperthreading: Enabled
    replicas: 3
platform:
  none: {}
networking:
  networkType: OpenShiftSDN
  machineNetwork:
    - cidr: ${ocp_nodes_cidr}
  clusterNetwork:
    - cidr: ${ocp_pods_cidr}
      hostPrefix: ${ocp_pods_range}
  serviceNetwork:
    - ${ocp_svcs_cidr}
imageContentSources:
  - source: quay.io/openshift-release-dev/ocp-release
    mirrors:
      - ${ocp_registry_mirror}
  - source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
    mirrors:
      - ${ocp_registry_mirror}
pullSecret: '${ocp_pull_secret}'
sshKey: '${ocp_ssh_pubkey}'
fips: false
additionalTrustBundle: |
  ${ocp_additional_ca}
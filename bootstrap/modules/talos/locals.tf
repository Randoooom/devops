locals {
  talos_install_image         = data.talos_image_factory_urls.this.urls.installer
  talos_install_disk          = "/dev/sda"
  instance_kernel_arg_console = "ttyAMA0"
  oci_config_ini              = <<EOF
[Global]
compartment-id = ${var.compartment_ocid}
region = ${var.region}
use-instance-principals = true
EOF
  oci_cloud_provider_config   = <<EOF
auth:
  useInstancePrincipals: true
compartment: ${var.compartment_ocid}
vcn: ${var.vcn_id}
loadBalancer:
  subnet1: ${var.public_subnet}
  securityListManagementMode: None
  securityLists:
    ${var.public_subnet}: ${var.security_list_id}
EOF
  talos_base_configuration    = <<-EOT
    machine:
      network:
        kubespan:
          enabled: true
      sysctls:
        user.max_user_namespaces: "11255"
      time:
        servers:
          - 169.254.169.254
      kubelet:
        extraArgs:
          cloud-provider: external
          rotate-server-certificates: "true"
        extraMounts:
          - destination: /var/lib/longhorn
            type: bind
            source: /var/lib/longhorn
            options:
            - bind
            - rshared
            - rw
      systemDiskEncryption:
        state:
          provider: luks2
          keys:
            - nodeID: {}
              slot: 0
        ephemeral:
          provider: luks2
          keys:
            - nodeID: {}
              slot: 0
          options:
            - no_read_workqueue
            - no_write_workqueue
      features:
        kubePrism:
          enabled: true
          port: 7445
      install:
        disk: ${local.talos_install_disk}
        extraKernelArgs:
          - console=console=${local.instance_kernel_arg_console}
          - talos.platform=oracle
        wipe: false
        image: ${local.talos_install_image}
    cluster:
      discovery:
        enabled: true
      network:
        cni:
          name: none
        podSubnets:
          - ${var.pod_subnet_block}
        serviceSubnets:
          - ${var.service_subnet_block}
      allowSchedulingOnMasters: false
      externalCloudProvider:
        enabled: true
        manifests:
          - https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/${var.talos_ccm_version}/docs/deploy/cloud-controller-manager.yml
          - https://github.com/oracle/oci-cloud-controller-manager/releases/download/${var.oracle_ccm_version}/oci-cloud-controller-manager-rbac.yaml
          - https://github.com/oracle/oci-cloud-controller-manager/releases/download/${var.oracle_ccm_version}/oci-cloud-controller-manager.yaml
          - https://raw.githubusercontent.com/prometheus-community/helm-charts/refs/heads/main/charts/kube-prometheus-stack/charts/crds/crds/crd-servicemonitors.yaml
          - https://raw.githubusercontent.com/prometheus-community/helm-charts/refs/heads/main/charts/kube-prometheus-stack/charts/crds/crds/crd-podmonitors.yaml
          - https://frme9idv6uqw.objectstorage.eu-frankfurt-1.oci.customer-oci.com/n/frme9idv6uqw/b/public/o/cilium.yaml
      controllerManager:
        extraArgs:
          cloud-provider: external
      apiServer:
        extraArgs:
          cloud-provider: external
          anonymous-auth: true
      inlineManifests:
        - name: oci-cloud-controller-manager
          contents: |
            apiVersion: v1
            data:
              cloud-provider.yaml: ${base64encode(local.oci_cloud_provider_config)}
              config.ini: ${base64encode(local.oci_config_ini)}
            kind: Secret
            metadata:
              name: oci-cloud-controller-manager
              namespace: kube-system
        - name: requests 
          contents: |
            apiVersion: v1
            kind: ResourceQuota
            metadata:
              name: storage
              namespace: kube-system
            spec:
              hard:
                requests.storage: 100Gi
    EOT
}

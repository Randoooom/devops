locals {
  instance_mode = "PARAVIRTUALIZED"

  workers = {
    for idx, instance in oci_core_instance.worker : idx => instance
  }

  controlplane = {
    for idx, instance in oci_core_instance.controlplane : idx => instance
  }
}

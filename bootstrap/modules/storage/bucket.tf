data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "nextcloud" {
  compartment_id = var.compartment_ocid
  name           = "${var.cluster_name}-nextcloud"
  namespace      = data.oci_objectstorage_namespace.this.namespace
}

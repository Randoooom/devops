resource "oci_kms_vault" "this" {
  compartment_id = var.compartment_id
  display_name   = var.cluster_name
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "this" {
  depends_on = [oci_kms_vault.this]

  compartment_id      = var.compartment_id
  display_name        = var.cluster_name
  management_endpoint = oci_kms_vault.this.management_endpoint

  key_shape {
    algorithm = "AES"
    length    = 32
  }

  protection_mode = "SOFTWARE"
}

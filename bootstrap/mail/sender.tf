locals {
  senders = flatten([
    for key, values in var.senders : [
      for value in values : {
        key   = key
        value = value
      }
    ]
  ])
}

resource "oci_email_sender" "this" {
  for_each = { for idx, sender in local.senders : idx => sender }

  compartment_id = var.compartment_ocid
  email_address  = "${each.value.value}@${each.value.key}"

  freeform_tags = var.labels
}


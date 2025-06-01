module "iam" {
  source = "${var.module_path}/iam"

  tenancy_ocid = var.tenancy_ocid
  labels       = var.labels

  groups = merge(
    [
      for domain, senders in var.senders : {
        for sender in senders :
        "${replace(domain, ".", "-")}-${sender}" => {
          policies = [
            "ALLOW group ${replace(domain, ".", "-")}-${sender} TO use approved-senders IN TENANCY WHERE ALL { target.approved-sender.emailaddress = '${sender}@${domain}' }"
          ]
          users = [
            {
              name              = "${replace(domain, ".", "-")}-${sender}"
              smtp              = true
              customerSecretKey = false
            }
          ]
        }
      }
    ]...
  )
}

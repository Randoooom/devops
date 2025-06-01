output "senders" {
  sensitive = true
  value = {
    for domain, senders in var.senders : domain => {
      for sender in senders : "${sender}@${domain}" => {
        username = module.iam.groups["${replace(domain, ".", "-")}-${sender}"].users["${replace(domain, ".", "-")}-${sender}"].smtp_credentials.username
        password = module.iam.groups["${replace(domain, ".", "-")}-${sender}"].users["${replace(domain, ".", "-")}-${sender}"].smtp_credentials.password
      }
    }
  }
}

output "smtp_host" {
  value = "smtp.email.${var.region}.oci.oraclecloud.com"
}

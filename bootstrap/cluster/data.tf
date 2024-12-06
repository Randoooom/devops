
data "terraform_remote_state" "oci" {
  backend = "s3"

  config = {
    bucket                      = "terraform-states"
    region                      = "eu-frankfurt-1"
    key                         = "oci/tf.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    use_path_style              = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
    endpoints = {
      s3 = "https://frme9idv6uqw.compat.objectstorage.eu-frankfurt-1.oraclecloud.com"
    }
  }
}

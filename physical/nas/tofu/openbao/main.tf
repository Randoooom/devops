resource "vault_mount" "kvv2" {
  path = local.kv_path
  type = "kv"

  options = {
    version = "2"
  }
  description = "Default KVV2 engine"
}

variable "organizations" {
  type = map(object({
    public  = bool,
    mirrors = map(string)
  }))
}

variable "access_tokens" {
  type      = map(string)
  sensitive = true
}

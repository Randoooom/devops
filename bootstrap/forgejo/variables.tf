variable "organizations" {
  type = map(object({
    public  = bool,
    mirrors = list(string)
  }))
}

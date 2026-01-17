variable "digicert_domain_validation_ips" {
  description = "Map of lists of Digicert domain validation IPs by their effective date."
  type        = map(list(string))
  default = {
    "1970-01-01T00:00:00Z" = [
      "216.168.249.9",
      "216.168.240.4",
      "216.168.247.9",
      "202.65.16.4",
      "54.185.245.130",
      "13.58.90.0",
      "52.17.48.104",
      "18.193.239.14",
      "54.227.165.213",
      "54.241.89.140",
    ]
    "2026-02-24T00:00:00Z" = [
      "52.78.185.62",
      "52.197.215.146",
    ]
  }
}

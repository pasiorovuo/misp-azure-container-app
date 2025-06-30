
output "database" {
  value = {
    database = module.database.dbname
    hostname = module.database.hostname
    password = "Key vault id: ${module.database.credentials.password}"
    port     = module.database.port
    username = module.database.credentials.username
  }
}

output "misp" {
  value = {
    hostname = "https://${local.fqdn}"
  }
}

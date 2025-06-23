
output "cache" {
  value = {
    access_key = "Key vault id: ${module.cache.access_keys.primary}"
    hostname   = module.cache.host.name
    port       = module.cache.host.port
  }
}

output "database" {
  value = {
    database = local.mysql_config.database_name
    hostname = module.database.hostname
    password = "Key vault id: ${module.database.credentials.password}"
    port     = module.database.port
    username = module.database.credentials.username
  }
}

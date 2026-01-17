
locals {
  cache                 = var.cache
  cidr                  = var.vnet_cidr
  core                  = var.misp.core
  database              = var.database
  domain_validation_ips = var.digicert_domain_validation_ips
  fqdn                  = var.fqdn
  ip_allowlist          = var.ip_allowlist
  location              = var.location
  log_renention_days    = var.log_renention_days
  modules               = var.misp.modules
  naming = {
    clean_input   = true
    name          = var.naming.name
    prefixes      = var.naming.prefix != null ? [var.naming.prefix] : []
    random_length = 8
    suffixes      = var.naming.suffix != null ? [var.naming.suffix] : []
    use_slug      = true
  }
  resource_group_name = var.resource_group_name
  storage             = var.storage
}

module "resource_group" {
  source = "./modules/resource-group"

  location            = local.location
  resource_group_name = local.resource_group_name
  naming              = local.naming
}

module "network" {
  source = "./modules/network"

  cidr           = local.cidr
  naming         = local.naming
  resource_group = module.resource_group.result
}

module "keyvault" {
  source = "./modules/keyvault"

  ip_allowlist   = local.ip_allowlist.management
  naming         = local.naming
  resource_group = module.resource_group.result
  subnet_ids     = [for k, v in module.network.subnets : v.id]
}

module "logs" {
  source = "./modules/logs"

  naming         = local.naming
  resource_group = module.resource_group.result
  retention_days = local.log_renention_days
}

# We deploy redis in a container for the time being
# module "cache" {
#   source = "./modules/cache"

#   keyvault                = module.keyvault.result
#   log_analytics_workspace = module.logs.workspace
#   naming                  = local.naming
#   resource_group          = module.resource_group.result
#   subnet                  = module.network.subnets.cache
#   vnet                    = module.network.vnet
# }

module "database" {
  source = "./modules/database"

  config                  = local.database
  depends_on              = [module.keyvault]
  keyvault                = module.keyvault.result
  log_analytics_workspace = module.logs.workspace
  naming                  = local.naming
  resource_group          = module.resource_group.result
  subnet                  = module.network.subnets.database
  vnet                    = module.network.vnet
}

module "storage" {
  source = "./modules/storage"

  config                  = local.storage
  ip_allowlist            = local.ip_allowlist.management
  log_analytics_workspace = module.logs.workspace
  naming                  = local.naming
  resource_group          = module.resource_group.result
  subnet                  = module.network.subnets.app
  vnet                    = module.network.vnet
}

module "app" {
  source = "./modules/app"

  cache = local.cache
  database = {
    MYSQL_DATABASE = module.database.dbname
    MYSQL_HOST     = module.database.hostname
    MYSQL_PORT     = "${module.database.port}"
    MYSQL_USER     = module.database.credentials.username
  }
  depends_on = [module.database, module.keyvault]
  fqdn       = local.fqdn
  ip_allowlist = concat(
    # Microsoft users Digicert validation services. See
    # https://knowledge.digicert.com/alerts/ip-address-domain-validation
    # for list of IPs.
    tolist(local.ip_allowlist.access),
    flatten(
      [for date in keys(var.digicert_domain_validation_ips) :
        lookup(var.digicert_domain_validation_ips, date, []) if timecmp(date, timestamp()) <= 0
      ]
    )
  )
  keyvault                = module.keyvault.result
  log_analytics_workspace = module.logs.workspace
  misp = {
    core    = local.core
    modules = local.modules
  }
  naming         = local.naming
  resource_group = module.resource_group.result
  subnet         = module.network.subnets.app
  storage_account = {
    id         = module.storage.storage_account.id,
    name       = module.storage.storage_account.name,
    access_key = module.storage.storage_account.access_key,
    share      = module.storage.share
  }

  secret_ids = {
    db_password = module.database.credentials.password
  }
}

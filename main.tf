
locals {
  cidr               = var.vnet_cidr
  environment        = var.environment
  fqdn               = var.fqdn
  location           = var.location
  log_renention_days = var.log_renention_days
  misp_env           = var.misp_env
  misp_modules_env   = var.misp_modules_env
  naming = {
    clean_input   = true
    name          = var.naming.name
    prefixes      = var.naming.prefix != null ? [var.naming.prefix] : []
    random_length = 8
    suffixes      = var.naming.suffix != null ? [var.naming.suffix] : []
    use_slug      = true
  }
  mysql_config        = var.mysql_config
  name_prefix         = var.name_prefix
  resource_group_name = var.resource_group_name
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

  naming         = local.naming
  resource_group = module.resource_group.result
}

module "logs" {
  source = "./modules/logs"

  naming         = local.naming
  resource_group = module.resource_group.result
  retention_days = local.log_renention_days
}

module "cache" {
  source = "./modules/cache"

  keyvault                = module.keyvault.result
  log_analytics_workspace = module.logs.workspace
  naming                  = local.naming
  resource_group          = module.resource_group.result
  subnet                  = module.network.subnets.cache
  vnet                    = module.network.vnet
}

module "database" {
  source = "./modules/database"

  config                  = local.mysql_config
  environment             = local.environment
  keyvault                = module.keyvault.result
  log_analytics_workspace = module.logs.workspace
  naming                  = local.naming
  resource_group          = module.resource_group.result
  subnet                  = module.network.subnets.database
  vnet                    = module.network.vnet
}

module "storage" {
  source = "./modules/storage"

  naming         = local.naming
  resource_group = module.resource_group.result
  subnet         = module.network.subnets.app
  vnet           = module.network.vnet
}

module "app" {
  source = "./modules/app"

  envvars                 = local.misp_env
  fqdn                    = local.fqdn
  keyvault                = module.keyvault.result
  log_analytics_workspace = module.logs.workspace
  modules_envvars         = local.misp_modules_env
  naming                  = local.naming
  resource_group          = module.resource_group.result
  subnet                  = module.network.subnets.app

  storage_account = {
    id         = module.storage.storage_account.id,
    name       = module.storage.storage_account.name,
    access_key = module.storage.storage_account.access_key,
    share      = module.storage.share
  }

  cache_config = {
    REDIS_HOST = module.cache.host.name
    REDIS_PORT = module.cache.host.port
  }

  database_config = {
    MYSQL_DATABASE = local.mysql_config.database_name
    MYSQL_HOST     = module.database.hostname
    MYSQL_PORT     = "${module.database.port}"
    MYSQL_USER     = module.database.credentials.username
  }

  secret_ids = {
    cache_password = module.cache.access_keys.primary
    db_password    = module.database.credentials.password
  }
}

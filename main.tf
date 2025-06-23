
locals {
  cidr                = var.vnet_cidr
  environment         = var.environment
  fqdn                = var.fqdn
  location            = var.location
  log_renention_days  = var.log_renention_days
  misp_env            = var.misp_env
  misp_modules_env    = var.misp_modules_env
  mysql_config        = var.mysql_config
  name_prefix         = var.name_prefix
  resource_group_name = var.resource_group_name
}

module "resource_group" {
  source = "./modules/resource-group"

  location            = local.location
  resource_group_name = local.resource_group_name
  name_prefix         = local.name_prefix
}

module "network" {
  source = "./modules/network"

  cidr           = local.cidr
  name_prefix    = local.name_prefix
  resource_group = module.resource_group.output
}

module "keyvault" {
  source = "./modules/keyvault"

  name_prefix    = local.name_prefix
  resource_group = module.resource_group.output
}

module "logs" {
  source = "./modules/logs"

  name_prefix    = local.name_prefix
  resource_group = module.resource_group.output
  retention_days = local.log_renention_days
}

module "cache" {
  source = "./modules/cache"

  keyvault                = module.keyvault.output
  log_analytics_workspace = module.logs.workspace
  name_prefix             = local.name_prefix
  resource_group          = module.resource_group.output
  subnet                  = module.network.subnets.cache
  vnet                    = module.network.vnet
}

module "database" {
  source = "./modules/database"

  config                  = local.mysql_config
  environment             = local.environment
  keyvault                = module.keyvault.output
  log_analytics_workspace = module.logs.workspace
  name_prefix             = local.name_prefix
  resource_group          = module.resource_group.output
  subnet                  = module.network.subnets.database
  vnet                    = module.network.vnet
}

module "app" {
  source = "./modules/app"

  envvars                 = local.misp_env
  fqdn                    = local.fqdn
  keyvault                = module.keyvault.output
  log_analytics_workspace = module.logs.workspace
  modules_envvars         = var.misp_modules_env
  name_prefix             = local.name_prefix
  resource_group          = module.resource_group.output
  subnet                  = module.network.subnets.app

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

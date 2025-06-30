
locals {
  cache    = var.cache
  database = var.database
  core_cpu = var.misp.core != null ? var.misp.core.cpu : 0.5
  core_mem = var.misp.core != null ? var.misp.core.memory : 1
  core_env = merge(
    {
      # Defaults that can be overridden
      CORE_RUNNING_TAG = "latest"
    },
    # Configured values
    var.misp.core != null ? var.misp.core.environment : {},
    {
      # Values always forced
      DISABLE_IPV6         = "true" # Azure Container Apps does not support IPv6
      DISABLE_SSL_REDIRECT = "true" # TLS is terminated at the load balancer
      ECS_LOG_ENABLED      = "true"
    }
  )
  fqdn                    = var.fqdn
  keyvault                = var.keyvault
  log_analytics_workspace = var.log_analytics_workspace
  modules_cpu             = var.misp.modules != null ? var.misp.modules.cpu : 0.5
  modules_mem             = var.misp.modules != null ? var.misp.modules.memory : 1
  modules_env = merge(
    {
      # Defaults that can be overridden
      MODULES_FLAVOR = "full",
      MODULES_TAG    = "latest"
    },
    var.misp.modules != null ? var.misp.modules.environment : {},
    {
      # Values that are always enforced
    }
  )
  naming          = var.naming
  resource_group  = var.resource_group
  secret_ids      = var.secret_ids
  storage_account = var.storage_account
  subnet          = var.subnet
}

resource "azurecaf_name" "container_app_environment" {
  clean_input    = local.naming.clean_input
  name           = local.naming.name
  prefixes       = local.naming.prefixes
  random_length  = local.naming.random_length
  resource_type  = "azurerm_app_service_environment"
  resource_types = ["azurerm_resource_group", "azurerm_automation_certificate"]
  suffixes       = local.naming.suffixes
  use_slug       = local.naming.use_slug
}

resource "azurecaf_name" "container_app_environment_rg" {
  clean_input   = local.naming.clean_input
  name          = "${local.naming.name}-caeinfra"
  prefixes      = local.naming.prefixes
  random_length = local.naming.random_length
  resource_type = "azurerm_resource_group"
  suffixes      = local.naming.suffixes
  use_slug      = local.naming.use_slug
}

resource "azurerm_user_assigned_identity" "app" {
  name = join(azurecaf_name.container_app_environment.separator, concat(
    local.naming.prefixes,
    ["uai", local.naming.name, "app"],
    local.naming.suffixes,
    [split("-", azurecaf_name.container_app_environment.result)[length(split("-", azurecaf_name.container_app_environment.result)) - 1]]
  ))
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
}

resource "azurerm_user_assigned_identity" "secrets" {
  name = join(azurecaf_name.container_app_environment.separator, concat(
    local.naming.prefixes,
    ["uai", local.naming.name, "secrets"],
    local.naming.suffixes,
    [split("-", azurecaf_name.container_app_environment.result)[length(split("-", azurecaf_name.container_app_environment.result)) - 1]]
  ))
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
}

resource "azurerm_role_assignment" "storage_writer" {
  scope                = local.storage_account.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "keyvault_reader" {
  scope                = local.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.secrets.principal_id
}

resource "time_sleep" "keyvault_rights" {
  create_duration = "60s"

  depends_on = [azurerm_role_assignment.keyvault_reader]
}

resource "azurerm_container_app_environment" "app" {
  depends_on                         = [time_sleep.keyvault_rights]
  infrastructure_resource_group_name = replace(azurecaf_name.container_app_environment_rg.result, "ase-", "cae-")
  infrastructure_subnet_id           = local.subnet.id
  internal_load_balancer_enabled     = false
  location                           = local.resource_group.location
  log_analytics_workspace_id         = local.log_analytics_workspace.id
  logs_destination                   = "log-analytics"
  name                               = replace(azurecaf_name.container_app_environment.result, "ase-", "cae-")
  resource_group_name                = local.resource_group.name

  workload_profile {
    maximum_count         = null
    minimum_count         = null
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_container_app_environment_storage" "app" {
  access_key                   = local.storage_account.access_key
  access_mode                  = "ReadWrite"
  account_name                 = local.storage_account.name
  container_app_environment_id = azurerm_container_app_environment.app.id
  name                         = "storage"
  share_name                   = local.storage_account.share.name
}

resource "random_password" "cache" {
  length  = 16
  lower   = true
  numeric = true
  special = false
  upper   = true
}

resource "azurerm_container_app" "cache" {
  name                         = "redis"
  resource_group_name          = local.resource_group.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  container_app_environment_id = azurerm_container_app_environment.app.id

  template {
    container {
      cpu     = local.cache.cpu
      memory  = "${local.cache.memory}Gi"
      name    = "redis"
      image   = "valkey/valkey:7.2"
      command = ["valkey-server", "--requirepass", random_password.cache.result]

      liveness_probe {
        failure_count_threshold = 5
        initial_delay           = 5
        interval_seconds        = 5
        port                    = "6379"
        transport               = "TCP"
      }

      readiness_probe {
        failure_count_threshold = 5
        initial_delay           = 5
        interval_seconds        = 5
        port                    = "6379"
        transport               = "TCP"
      }
    }
    max_replicas = 1
    min_replicas = 1
  }

  ingress {
    external_enabled = false
    target_port      = 6379
    transport        = "tcp"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "misp_core" {
  container_app_environment_id = azurerm_container_app_environment.app.id
  name                         = "misp-core"
  resource_group_name          = local.resource_group.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    identity_ids = [
      # azurerm_user_assigned_identity.app.id,
      azurerm_user_assigned_identity.secrets.id,
    ]
    type = "UserAssigned"
  }

  secret {
    name                = "db-password"
    identity            = azurerm_user_assigned_identity.secrets.id
    key_vault_secret_id = local.secret_ids.db_password
  }

  template {
    container {
      cpu    = local.core_cpu
      image  = "ghcr.io/misp/misp-docker/misp-core:${lookup(local.core_env, "CORE_RUNNING_TAG", "latest")}"
      memory = "${local.core_mem}Gi"
      name   = "misp-core"

      # Pull environment variables from the deployment
      dynamic "env" {
        for_each = local.core_env

        content {
          name  = env.key
          value = env.value
        }
      }

      # MySQL configuration
      dynamic "env" {
        for_each = local.database

        content {
          name  = env.key
          value = env.value
        }
      }

      # Redis configuration
      dynamic "env" {
        for_each = {
          REDIS_HOST     = "redis"
          REDIS_PASSWORD = random_password.cache.result
          REDIS_PORT     = "6379"
        }

        content {
          name  = env.key
          value = env.value
        }
      }

      # Passwords
      env {
        name        = "MYSQL_PASSWORD"
        secret_name = "db-password"
      }

      liveness_probe {
        failure_count_threshold = 3
        interval_seconds        = 2
        path                    = "/users/heartbeat"
        port                    = 80
        timeout                 = 1
        transport               = "HTTP"
      }

      startup_probe {
        failure_count_threshold = 8
        initial_delay           = 60
        interval_seconds        = 30
        path                    = "/users/heartbeat"
        port                    = 80
        timeout                 = 5
        transport               = "HTTP"
      }

      volume_mounts {
        name     = azurerm_container_app_environment_storage.app.name
        path     = "/var/www/MISP/app/Config/"
        sub_path = "configs/"
      }
      volume_mounts {
        name     = azurerm_container_app_environment_storage.app.name
        path     = "/var/www/MISP/app/tmp/logs/"
        sub_path = "logs/"
      }
      volume_mounts {
        name     = azurerm_container_app_environment_storage.app.name
        path     = "/var/www/MISP/app/files/"
        sub_path = "files/"
      }
      volume_mounts {
        name     = azurerm_container_app_environment_storage.app.name
        path     = "/etc/nginx/certs/"
        sub_path = "ssl/"
      }
      volume_mounts {
        name     = azurerm_container_app_environment_storage.app.name
        path     = "/var/www/MISP/.gnupg/"
        sub_path = "gnupg/"
      }
    }

    volume {
      name          = azurerm_container_app_environment_storage.app.name
      storage_name  = azurerm_container_app_environment_storage.app.name
      storage_type  = "AzureFile"
      mount_options = "dir_mode=0777,file_mode=0777,uid=33,gid=33,mfsymlinks,cache=strict,nosharesock,nobrl"
    }

    max_replicas = 1
    min_replicas = 1
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    transport                  = "auto"

    ip_security_restriction {
      action           = "Allow"
      ip_address_range = "157.245.22.138/32"
      name             = "Allow from VPN"
    }

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "misp_modules" {
  container_app_environment_id = azurerm_container_app_environment.app.id
  name                         = "misp-modules"
  resource_group_name          = local.resource_group.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    container {
      cpu    = local.modules_cpu
      image  = "ghcr.io/misp/misp-docker/misp-modules:${lookup(local.modules_env, "MODULES_TAG", "latest")}"
      memory = "${local.modules_mem}Gi"
      name   = "misp-modules"

      dynamic "env" {
        for_each = local.modules_env

        content {
          name  = env.key
          value = env.value
        }
      }

      liveness_probe {
        failure_count_threshold = 3
        interval_seconds        = 2
        path                    = "/healthcheck"
        port                    = 6666
        timeout                 = 1
        transport               = "HTTP"
      }

      readiness_probe {
        failure_count_threshold = 5
        initial_delay           = 5
        interval_seconds        = 5
        path                    = "/healthcheck"
        port                    = 6666
        transport               = "HTTP"
      }
    }

    max_replicas = 1
    min_replicas = 1
  }

  ingress {
    allow_insecure_connections = true
    external_enabled           = false
    target_port                = 6666
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

data "azurerm_dns_zone" "zone" {
  name = local.fqdn
}

resource "azurerm_dns_a_record" "misp" {
  name                = "@"
  records             = [azurerm_container_app_environment.app.static_ip_address]
  resource_group_name = data.azurerm_dns_zone.zone.resource_group_name
  ttl                 = 300
  zone_name           = data.azurerm_dns_zone.zone.name
}

resource "azurerm_dns_txt_record" "misp" {
  name                = "asuid"
  resource_group_name = data.azurerm_dns_zone.zone.resource_group_name
  ttl                 = 300
  zone_name           = data.azurerm_dns_zone.zone.name

  record {
    value = azurerm_container_app.misp_core.custom_domain_verification_id
  }
}

resource "azurerm_container_app_custom_domain" "misp" {
  container_app_id = azurerm_container_app.misp_core.id
  name             = local.fqdn

  lifecycle {
    ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  }
}

resource "azapi_resource" "managed_certificate" {
  depends_on = [azurerm_container_app_custom_domain.misp]
  location   = local.resource_group.location
  name       = replace(azurecaf_name.container_app_environment.result, "aacert-", "cert-")
  parent_id  = azurerm_container_app_environment.app.id
  type       = "Microsoft.App/managedEnvironments/managedCertificates@2023-05-01"

  body = {
    properties = {
      domainControlValidation = "HTTP"
      subjectName             = local.fqdn
    }
  }
}

resource "azapi_update_resource" "bind_managed_certificate" {
  depends_on  = [azapi_resource.managed_certificate, azurerm_container_app_custom_domain.misp]
  resource_id = azurerm_container_app.misp_core.id
  type        = "Microsoft.App/containerApps@2023-05-01"

  body = {
    properties = {
      configuration = {
        ingress = {
          customDomains = [{
            bindingType   = "SniEnabled"
            certificateId = azapi_resource.managed_certificate.id
            name          = local.fqdn
          }]
        }
      }
    }
  }
}


locals {
  cache_config            = var.cache_config
  database_config         = var.database_config
  envvars                 = var.envvars
  fqdn                    = var.fqdn
  keyvault                = var.keyvault
  log_analytics_workspace = var.log_analytics_workspace
  modules_envvars         = merge({ MODULES_FLAVOR = "full", MODULES_TAG = "latest" }, var.modules_envvars)
  prefix                  = var.name_prefix
  resource_group          = var.resource_group
  secret_ids              = var.secret_ids
  subnet                  = var.subnet
}

# resource "azurerm_user_assigned_identity" "app_identity" {
#   name                = "${local.prefix}-app-identity"
#   resource_group_name = local.resource_group.name
#   location            = local.resource_group.location
# }

resource "azurerm_user_assigned_identity" "secrets_identity" {
  name                = "${local.prefix}-secrets-identity"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
}

resource "azurerm_role_assignment" "keyvault_reader" {
  scope                = local.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.secrets_identity.principal_id
}

resource "time_sleep" "keyvault_rights" {
  create_duration = "60s"

  depends_on = [azurerm_role_assignment.keyvault_reader]
}

resource "random_string" "identifier" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false

  keepers = {
    key = "1"
  }
}

resource "azurerm_container_app_environment" "app" {
  depends_on                         = [time_sleep.keyvault_rights]
  infrastructure_resource_group_name = "${trimsuffix(local.resource_group.name, "-rg")}-container-app-env-rg"
  infrastructure_subnet_id           = local.subnet.id
  internal_load_balancer_enabled     = false
  location                           = local.resource_group.location
  log_analytics_workspace_id         = local.log_analytics_workspace.id
  logs_destination                   = "log-analytics"
  name                               = "${local.prefix}-app-env-${random_string.identifier.result}"
  resource_group_name                = local.resource_group.name

  workload_profile {
    maximum_count         = null
    minimum_count         = null
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

# resource "azurerm_container_app" "cache" {
#   container_app_environment_id = azurerm_container_app_environment.app.id
#   name                         = "${local.prefix}-cache"
#   resource_group_name          = local.resource_group.name
#   revision_mode                = "Single"

#   template {
#     container {
#       name   = "php"
#       image  = "blabla"
#       cpu    = 0.5
#       memory = "1Gi"
#     }
#     max_replicas = 1
#     min_replicas = 1
#   }
# }

resource "azurerm_container_app" "misp_core" {
  container_app_environment_id = azurerm_container_app_environment.app.id
  name                         = "misp-core"
  resource_group_name          = local.resource_group.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    identity_ids = [azurerm_user_assigned_identity.secrets_identity.id]
    type         = "UserAssigned"
  }

  secret {
    name                = "cache-password"
    identity            = azurerm_user_assigned_identity.secrets_identity.id
    key_vault_secret_id = local.secret_ids.cache_password
  }

  secret {
    name                = "db-password"
    identity            = azurerm_user_assigned_identity.secrets_identity.id
    key_vault_secret_id = local.secret_ids.db_password
  }

  template {
    container {
      cpu    = 1
      image  = "ghcr.io/misp/misp-docker/misp-core:${lookup(local.envvars, "CORE_RUNNING_TAG", "latest")}"
      memory = "2Gi"
      name   = "misp-core"

      # Pull environment variables from the deployment
      dynamic "env" {
        for_each = local.envvars

        content {
          name  = env.key
          value = env.value
        }
      }
      # MySQL configuration
      dynamic "env" {
        for_each = local.database_config

        content {
          name  = env.key
          value = env.value
        }
      }
      # Redis configuration
      dynamic "env" {
        for_each = local.cache_config

        content {
          name  = env.key
          value = env.value
        }
      }

      # Passwords
      env {
        name        = "REDIS_PASSWORD"
        secret_name = "cache-password"
      }
      env {
        name        = "MYSQL_PASSWORD"
        secret_name = "db-password"
      }

      # Other
      env { # TLS is terminated at the load balancer
        name  = "DISABLE_SSL_REDIRECT"
        value = "true"
      }
      env {
        name  = "ECS_LOG_ENABLED"
        value = "true"
      }

      # liveness_probe {
      #   failure_count_threshold = 3
      #   interval_seconds        = 2
      #   path                    = "/users/heartbeat"
      #   port                    = 80
      #   timeout                 = 1
      #   transport               = "HTTP"
      # }

      startup_probe {
        failure_count_threshold = 8
        initial_delay           = 60
        interval_seconds        = 30
        path                    = "/users/heartbeat"
        port                    = 443
        timeout                 = 5
        transport               = "HTTP"
      }
    }

    max_replicas = 1
    min_replicas = 1
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 443
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
      cpu    = 0.5
      image  = "ghcr.io/misp/misp-docker/misp-modules:${lookup(local.modules_envvars, "MODULES_TAG", "latest")}"
      memory = "1Gi"
      name   = "misp-modules"

      dynamic "env" {
        for_each = local.modules_envvars

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

# resource "azurerm_dns_cname_record" "misp" {
#   name                = "@"
#   record              = "${azurerm_container_app.misp.name}.${azurerm_container_app_environment.app.default_domain}"
#   resource_group_name = data.azurerm_dns_zone.zone.resource_group_name
#   ttl                 = 300
#   zone_name           = data.azurerm_dns_zone.zone.name
# }

# resource "azurerm_dns_txt_record" "misp" {
#   name                = "asuid"
#   resource_group_name = data.azurerm_dns_zone.zone.resource_group_name
#   ttl                 = 300
#   zone_name           = data.azurerm_dns_zone.zone.name

#   record {
#     value = azurerm_container_app.misp_core.custom_domain_verification_id
#   }
# }

# resource "azurerm_container_app_custom_domain" "misp" {
#   container_app_id = azurerm_container_app.misp_core.id
#   name             = local.fqdn

#   lifecycle {
#     ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
#   }
# }

# resource "azapi_resource" "managed_certificate" {
#   depends_on = [azurerm_container_app_custom_domain.misp]
#   location   = local.resource_group.location
#   name       = "${local.prefix}-managed-certificate"
#   parent_id  = azurerm_container_app_environment.app.id
#   type       = "Microsoft.App/managedEnvironments/managedCertificates@2023-05-01"

#   body = {
#     properties = {
#       domainControlValidation = "HTTP"
#       subjectName             = local.fqdn
#     }
#   }
# }

# resource "azapi_update_resource" "bind_managed_certificate" {
#   depends_on  = [azapi_resource.managed_certificate]
#   resource_id = azurerm_container_app.misp_core.id
#   type        = "Microsoft.App/containerApps@2023-05-01"

#   body = {
#     properties = {
#       configuration = {
#         ingress = {
#           customDomains = [{
#             bindingType   = "SniEnabled"
#             certificateId = azapi_resource.managed_certificate.id
#             name          = local.fqdn
#           }]
#         }
#       }
#     }
#   }
# }

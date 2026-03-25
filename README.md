
# NOTE!

The initial deployment will possibly fail due to the container app not being
able to read the database secret. This seems to be an issue with the AzureRM
provider, as no mount of delay between creating the Key Vault secret and creating
the container app resolves the issue.

If this happens, remove the Azure Container App and the Container App Environment
manually form the Azure Portal or CLI and retry. Deployment should succeed.

Likewise, during destruction, Tofu might fail with an error about an ongoing
provisioning procedure. A retry will resolve the issue.

# Setup

1. Create a DNS zone in Azure e.g. `misp.example.com`.
2. Delegate the DNS zone (create NS records that point to Azure DNS servers) for the zone
3. Register `Microsoft.App` resource provider with the subsciption

# Deploy

Log in on your tenant in Azure CLI and make sure `az` cli commands work.

Initialize Tofu and deploy MISP:

```bash
$ tofu init
$ tofu plan
$ tofu apply
```

# Destroy

```bash
$ tofu destroy
```

# Additional documentation

- Application logs need to be configured to be shipped to the Log Analytics Workspace
- Finish documentation
  - How to prepare the Azure account
    - DNS Zone
    - Key vault administrator permissions
  - Scaling / performance

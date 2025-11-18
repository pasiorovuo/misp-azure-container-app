
# Setup

1. Create a DNS zone in Azure e.g. `misp.example.com`.
2. Delegate the DNS zone (create NS records that point to Azure DNS servers) for the zone
3. Register `Microsoft.App` resource provider with the subsciption

# Deploy

Initialize `tofu` command line with:

```bash
$ az login --tenant <your tenante id> --use-device-code
$ tofu init
$ tofu plan
$ tofu apply
```

N.B. The initial deployment will likely fail due to the container app not being
able to read the database secret. This is under investigation.

# Destroy

```bash
$ tofu destroy
```

N.B. The destroy will likely fail because there is no proper delay between the
removal of custom domain name of the container app and the removal of the
certificate. This is under investigation.

# Additional documentation

- Application logs need to be configured to be shipped to the Log Analytics Workspace
- Finish documentation
  - How to prepare the Azure account
    - DNS Zone
    - Key vault administrator permissions
  - Scaling / performance

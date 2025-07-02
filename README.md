
# TODO

- Application logs need to be configured to be shipped to the Log Analytics Workspace
- Finish documentation
  - How to configure Entra ID for authentication
  - How to prepare the Azure account
    - DNS Zone
    - Key vault administrator permissions
  - How to configure the solution
  - How to deploy it
  - How to destroy the environment
    - Manual removal of custom domain
  - Scaling / performance

# Login

```bash
$ az login --tenant 2df6f409-32be-4b76-9c7c-7fd84ecd2edc --use-device-code
$ tofu init
$ tofu plan
```


# Setup

1. Create a DNS zone in Azure e.g. `misp.example.com`.
2. Delegate the DNS zone (create NS records that point to Azure DNS servers) for the zone
3. Register `Microsoft.App` resource provider with the subsciption


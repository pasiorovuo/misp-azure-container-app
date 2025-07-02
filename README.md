
# TODO

- Harden the key vault
- Storage account file share size should be configurable
- Application logs need to be configured to be shipped somewhere

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


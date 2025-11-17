
# How to destroy the environment

Due to missing functionality in Terraform providers, the destruction of the environment needs to be executed in two phases.

- First execute `tofu destroy`
- When destructions fails with an error about domain / certificate being used, go to Azure portal -> Container Apps -> misp-core -> Custom domains and delete the custom domain.
- Re-execute `tofu destroy`

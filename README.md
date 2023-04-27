# azure-chaos-studio

This repo contains several demos for the Azure Chaos Studio.

## Getting started with Azure Chaos Studio

In this demo we are creating a Azure Key Vault and deploying our first Chaos Studio Experiment. The experiment will activate the Key Vaults Firewall to disable all access to this Key Vault.

For This demo we created a Resource Group called `rg-chaos-demo` that we use for our purposes.

### Deploy

```bash
# What-if
az deployment group what-if \
  --name AkvBicepDeployment \
  --resource-group rg-chaos-demo \
  --location westeurope \
  --template-file ./keyVault/main.bicep

# Deploy
az deployment group create \
  --name AkvBicepDeployment \
  --resource-group rg-chaos-demo \
  --location westeurope \
  --template-file ./keyVault/main.bicep
```

### Important

As of now, it is not supporrted to add a capability via Bicep ([GitHub Issue](https://github.com/Azure/bicep/issues/6010)). So after we created all resources we have to manually enable the capabilitiy `Key Vault Deny Access` on the Chaos Studio Target. To do this, go to the [Azure Portal](https://preview.portal.azure.com/) and search for Chaos Studio (preview) in the search bar. In the Targets view you, click the **Manage actions** link next to the resource. This will lead you to the capability view of the target. Select now `Key Vault Deny Access` as capability and Save. Now we are ready to run our first experiment.

## Chaos with AKS and Chaos Mesh

In this demo we are creating a Azure Key Vault and deploying our first Chaos Studio Experiment. The experiment will activate the Key Vaults Firewall to disable all access to this Key Vault.

This demo will create a Resource Group called `rg-aks-chaos-demo` that we use for our purposes.
### Deploy

```bash
# What-if
az deployment sub what-if \
  --name AksBicepDeployment \
  --location westeurope \
  --template-file ./aks/src/main.bicep

# Deploy
az deployment sub create \
  --name AksBicepDeployment \
  --location westeurope \
  --template-file ./aks/src/main.bicep
```

## Useful docs

* [PRINCIPLES OF CHAOS ENGINEERING](https://principlesofchaos.org/)
* [What is Azure Chaos Studio (Preview)?](https://learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-overview)
* [Quickstart: Create and run a chaos experiment using Azure Chaos Studio](https://learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-quickstart-azure-portal)
* [Chaos Studio fault and action library](https://learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-fault-library)
* [Chaos Studio supported resource types](https://learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-fault-providers)

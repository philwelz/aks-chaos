// ################################
// ########### Common #############
// ################################

targetScope='subscription'

param location string = deployment().location

@description('The prefix of the Managed Cluster resource')
param prefix string = 'chaos'

@description('The environment of the Managed Cluster resource e.g. stg, dev, prd or demo')
param stage string = 'demo'

@description('The prefix of the Managed Cluster resource')
param baseName string = '${prefix}-${stage}'

@description('Common tags for all resources')
param tags object = {
  env: stage
  managedBy: 'bicep'
  project: prefix
}

// ################################
// ############# RG ###############
// ################################

module rgCore './modules/rg.bicep' = {
  name: 'rg-aks-${baseName}'
  params: {
    rgName: 'rg-aks-${baseName}'
    location: location
    tags: tags
  }
}

// ################################
// ############# AKS ##############
// ################################

module aksIdentity './modules/identity.bicep' = {
  name: 'aksIdentity'
  scope: resourceGroup(rgCore.name)
  params: {
    basename: 'uai-aks-${baseName}'
    tags: tags
    location: location
  }
}

@description('The Kubernetes Version to use for the AKS Cluster')
param kubernetes_version string = '1.24.9'

module aksCluster './modules/aks.bicep' = {
  name: 'aksCluster'
  scope: resourceGroup(rgCore.name)
  params: {
    k8sVersion: kubernetes_version
    k8sAdminGroup: '429bfc0b-dac5-4dd8-862a-831985f20e4d'
    basename: baseName
    location: location
    tags: tags
    identity: {
      '${aksIdentity.outputs.identityid}' : {}
    }
  }
}

// assign Managed Identity to networkContributor role
module UaiAksNetworkContributor './modules/role.bicep' = {
  name: 'ra-uai-aks-network-contributor'
  scope: resourceGroup(rgCore.name)
  params: {
    roleDefinitionResourceId: resourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7') // Network Contributer
    principalId: aksIdentity.outputs.identityprincipalId
    principalType: 'ServicePrincipal'
  }
}

// ################################
// ############ GitOps ############
// ################################

module aksGitOps './modules/gitops.bicep' = {
  name: 'aksGitOps'
  scope: resourceGroup(rgCore.name)
  params: {
    aksName: aksCluster.outputs.aksName
    gitRepository: 'https://github.com/philwelz/azure-chaos-studio'
    gitBranch: 'main'
    fluxKustomizationPath: './aks/gitops/cluster/'
  }
}

// ################################
// ############# AKV ##############
// ################################

module akv './modules/akv.bicep' = {
  name: 'akv'
  scope: resourceGroup(rgCore.name)
  params: {
    basename: baseName
    tags: tags
    location: location
  }
}

// Create Identity used for Workload Identity
module akvChaosIdentity './modules/identity.bicep' = {
  name: 'akvChaosIdentity'
  scope: resourceGroup(rgCore.name)
  params: {
    basename: 'uai-akv-wi-${baseName}'
    tags: tags
    location: location
  }
}

// assign Identity used for Workload Identity to Secrets User Role
module raAkvChaosIdentity './modules/role.bicep' = {
  name: 'ra-uai-akv-secret-user'
  scope: resourceGroup(rgCore.name)
  params: {
    roleDefinitionResourceId: resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: akvChaosIdentity.outputs.identityprincipalId
    principalType: 'ServicePrincipal'
  }
}

// Create federation between AKS, Identity and Service Account
module AkvWiFederatedIdentityCredentials './modules/fed.bicep' = {
  name: 'fc-uai-akv-wi-${baseName}'
  scope: resourceGroup(rgCore.name)
  params: {
    basename: 'fc-uai-akv-wi-${baseName}'
    identity: akvChaosIdentity.outputs.identityName
    subject: 'system:serviceaccount:akv-demo:sa-akv-demo'
    issuer: aksCluster.outputs.aksIssuerURL
  }
}


// ################################
// ########## Chaos AKS ###########
// ################################

module chaosExperimentsAKS './modules/chaos-aks.bicep' = {
  name: 'aksChaos'
  scope: resourceGroup(rgCore.name)
  params: {
    location: location
    tags: tags
    aksName: aksCluster.outputs.aksName
  }
}

// assign ChaosExperimentIdentity to Azure Kubernetes Service Cluster Admin Role
module SaiPodChaosAksAdmin './modules/role.bicep' = {
  name: 'ra-sai-aks-podChaos-aksAdmin'
  scope: resourceGroup(rgCore.name)
  params: {
    roleDefinitionResourceId: resourceId('Microsoft.Authorization/roleDefinitions', '0ab0b1a8-8aac-4efd-b8c2-3ee1fb270be8') // Azure Kubernetes Service Cluster Admin Role
    principalId: chaosExperimentsAKS.outputs.podChaosPrincipalId
    principalType: 'ServicePrincipal'
  }
}


// ################################
// ########## Chaos AKV ###########
// ################################

module chaosExperimentsAKV './modules/chaos-akv.bicep' = {
  name: 'akvChaos'
  scope: resourceGroup(rgCore.name)
  params: {
    location: location
    tags: tags
    akvName: akv.outputs.akvName
  }
}

// assign ChaosExperimentIdentity to Key Vault Contributor Role
module SaiChaosAkvContributor './modules/role.bicep' = {
  name: 'ra-sai-akv-accessDenied-akvContributor'
  scope: resourceGroup(rgCore.name)
  params: {
    roleDefinitionResourceId: resourceId('Microsoft.Authorization/roleDefinitions', 'f25e0fa2-a7c8-4377-a976-54943a77a395') // Key Vault Contributor
    principalId: chaosExperimentsAKV.outputs.akvAccessDeniedPrincipalId
    principalType: 'ServicePrincipal'
  }
}

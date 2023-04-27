// ################################
// ########### Common #############
// ################################

param location string = 'westeurope'

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
// ############# AKV ##############
// ################################

resource akv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'akv-${baseName}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableRbacAuthorization: true
    enableSoftDelete: true
    publicNetworkAccess: 'Enabled'
    softDeleteRetentionInDays: 90
    tenantId: tenant().tenantId
  }
}

resource superSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'secret-${baseName}'
  tags: tags
  parent: akv
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'secret'
    value: 'mysupersecretsecret'
  }
}

// ################################
// ############ Chaos #############
// ################################

// Create Chaos Studio Target
resource akvChaosStudioTarget 'Microsoft.Chaos/targets@2022-10-01-preview' = {
  name: 'Microsoft-KeyVault'
  location: location
  scope: akv
  properties: {}
}

// This is not working  at the moment. Issue open at https://github.com/Azure/bicep/issues/6010
// resource akvCapabilitiyAccessDenied 'Microsoft.Chaos/targets/capabilities@2022-10-01-preview' = {
//   name: 'DenyAccess-1.0'
//   parent: akvChaosStudioTarget
// }

resource akvAccessDenied 'Microsoft.Chaos/experiments@2022-10-01-preview' = {
  name: '${akv.name}AccessDenied10m'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    selectors: [
      {
        type: 'List'
        id: 'Selector1'
        targets: [
          {
            id: akvChaosStudioTarget.id
            type: 'ChaosTarget'
          }
        ]
      }
    ]
    steps: [
      {
        name: 'akvAccessDenied10m'
        branches: [
          {
            name: 'akvAccessDenied10m'
            actions: [
              {
                name: 'urn:csci:microsoft:keyVault:denyAccess/1.0'
                type: 'continuous'
                duration: 'PT10M'
                selectorId: 'Selector1'
                parameters: []
              }
            ]
          }
        ]
      }
    ]
  }
}

// Role Assignment resource
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, resourceGroup().id, akvAccessDenied.id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'f25e0fa2-a7c8-4377-a976-54943a77a395') // Key Vault Contributor
    principalId: akvAccessDenied.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

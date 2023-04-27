targetScope='resourceGroup'

// inherited from root module
param basename string
param tags object
param location string

// ################################
// ############ Common ############
// ################################

resource akv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'akv-${basename}-meetup'
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
  name: 'secret-${basename}'
  tags: tags
  parent: akv
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'secret'
    value: 'Hello, im a Secret!'
  }
}

output akvName string = akv.name

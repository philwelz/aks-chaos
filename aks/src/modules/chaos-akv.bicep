// inherited from root module
param location string
param tags object
param akvName string

// Get existing AKS
resource akv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: akvName
}

// Create Chaos Studio Target
resource akvChaosStudioTarget 'Microsoft.Chaos/targets@2022-10-01-preview' = {
  name: 'Microsoft-KeyVault'
  location: location
  scope: akv
  properties: {}
}

// AKV access denied experiment
resource akvAccessDenied 'Microsoft.Chaos/experiments@2022-10-01-preview' = {
  name: 'akvAccessDenied5m'
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
        name: 'akvAccessDenied5m'
        branches: [
          {
            name: 'akvAccessDenied5m'
            actions: [
              {
                name: 'urn:csci:microsoft:keyVault:denyAccess/1.0'
                type: 'continuous'
                duration: 'PT5M'
                selectorId: 'Selector1'
                parameters: [
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}

output akvAccessDeniedPrincipalId string = akvAccessDenied.identity.principalId

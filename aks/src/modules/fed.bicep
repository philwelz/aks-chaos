targetScope='resourceGroup'

// inherited from root module
param basename string
param identity string
param issuer string
param subject string

// Get existing Identity
resource parentIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: identity
}

resource symbolicname 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: basename
  parent: parentIdentity
  properties: {
    audiences: ['api://AzureADTokenExchange']
    issuer: issuer
    subject: subject
  }
}

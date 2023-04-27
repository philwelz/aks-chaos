targetScope='resourceGroup'

// inherited from root module
param basename string
param tags object
param location string

// create Managed Identity
resource uaIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: basename
  location: location
  tags: tags
}

// define output
output identityName string = uaIdentity.name
output identityid string = uaIdentity.id
output identityprincipalId string = uaIdentity.properties.principalId

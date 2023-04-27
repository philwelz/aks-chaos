targetScope='resourceGroup'

// Role Assingment params
@description('Provide a Role Definition ID.')
param roleDefinitionResourceId string

@description('Provide a Principal ID.')
param principalId string

@description('Provide the Principal Type.')
param principalType string = 'ServicePrincipal'

// Role Assignment resource
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, resourceGroup().id, principalId, roleDefinitionResourceId)
  properties: {
    roleDefinitionId: roleDefinitionResourceId
    principalId: principalId
    principalType: principalType
  }
}

// inherited from root module
param location string
param tags object
param aksName string

// Get existing AKS
resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-09-01' existing = {
  name: aksName
}

// Create Chaos Studio Target
resource chaosStudioTarget 'Microsoft.Chaos/targets@2022-10-01-preview' = {
  name: 'microsoft-azurekubernetesservicechaosmesh'
  location: location
  scope: aksCluster
  properties: {}
}

// Pod Chaos experiment
resource podChaos 'Microsoft.Chaos/experiments@2022-10-01-preview' = {
  name: 'PodFault5mNsFred'
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
            id: chaosStudioTarget.id
            type: 'ChaosTarget'
          }
        ]
      }
    ]
    steps: [
      {
        name: 'PodFault5mNsFred'
        branches: [
          {
            name: 'PodFault5mNsFred'
            actions: [
              {
                name: 'urn:csci:microsoft:azureKubernetesServiceChaosMesh:podChaos/2.1'
                type: 'continuous'
                duration: 'PT5M'
                selectorId: 'Selector1'
                parameters: [
                  {
                    key: 'jsonSpec'
                    value: '{"action":"pod-failure","mode":"all","duration":"300s","selector":{"namespaces":["fred"]}}'
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}

output podChaosPrincipalId string = podChaos.identity.principalId

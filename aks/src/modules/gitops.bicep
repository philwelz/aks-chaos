// inherited from root module
param gitRepository string
param gitBranch string
param fluxKustomizationPath string
param aksName string

// Get existing AKS
resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-09-01' existing = {
  name: aksName
}

// ################################
// ############# Flux #############
// ################################

resource flux 'Microsoft.KubernetesConfiguration/extensions@2021-09-01' = {
  name: 'flux'
  scope: aksCluster
  properties: {
    autoUpgradeMinorVersion: true
    configurationProtectedSettings: {}
    configurationSettings: {
      'toleration-keys': 'CriticalAddonsOnly=true:NoSchedule'
      'multiTenancy.enforce': 'false'
      'helm-controller.enabled': 'true' // enabled by default
      'source-controller.enabled': 'true' // enabled by default
      'kustomize-controller.enabled': 'true' // enabled by default
      'notification-controller.enabled': 'false' // enabled by default
      'image-automation-controller.enabled': 'false' // disabled by default
      'image-reflector-controller.enabled': 'false' // disabled by default
    }
    extensionType: 'microsoft.flux'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
  }
}

// ################################
// ######### Flux Config ##########
// ################################

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2022-01-01-preview' = {
  name: 'flux-config'
  scope: aksCluster
  dependsOn: [
    flux
  ]
  properties: {
    scope: 'cluster'
    namespace: 'flux-system'
    sourceKind: 'GitRepository'
    suspend: false

    gitRepository: {
      url: gitRepository
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
      repositoryRef: {
        branch: gitBranch
      }

    }
    kustomizations: {
      cluster: {
        path: fluxKustomizationPath
        dependsOn: []
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        prune: true
      }
    }
  }
}

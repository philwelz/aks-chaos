targetScope='resourceGroup'

// inherited from root module
param basename string
param tags object
param k8sVersion string
param k8sAdminGroup string
param identity object
param location string

// ################################
// ############ Common ############
// ################################

@description('The type of identity used for the managed cluster')
param identity_type string = 'UserAssigned'

@minValue(3)
@maxValue(6)
@description('The number of Nodes that should exist in the System Node Pool')
param system_node_count int = 3

@description('Maximum Pods per Node')
param max_pods int = 110

@description('The default virtual machine size for the Nodes')
param system_vm_size string = 'Standard_D2s_v3'

@description('Availability zones to use for the system node pool')
param system_availability_zones array = [
  '1'
]

// ################################
// ############# AKS ##############
// ################################

// Create AKS
resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-01-01' = {
  name: 'aks-${basename}'
  location: location
  tags: tags

  sku: {
    name: 'Basic'
    tier: 'Free'
  }

  identity: {
    type: identity_type
    userAssignedIdentities: identity
  }

  properties: {
    nodeResourceGroup: 'rg-aks-mc-${basename}'
    kubernetesVersion: k8sVersion
    dnsPrefix: basename
    enableRBAC: true
    disableLocalAccounts: false

    aadProfile: {
      adminGroupObjectIDs: [
        k8sAdminGroup
      ]
      enableAzureRBAC: true
      managed: true
      tenantID: subscription().tenantId
    }

    oidcIssuerProfile: {
      enabled: true
    }

    addonProfiles: {

      kubeDashboard: {
        enabled: false
      }
      azurePolicy: {
        enabled: false
      }
      omsAgent : {
        enabled: false
      }
      azureKeyvaultSecretsProvider : {
        enabled: true
      }
    }

    agentPoolProfiles: [
      {
        name: 'default'
        mode: 'System'
        maxPods: max_pods
        count: system_node_count
        availabilityZones: system_availability_zones
        vmSize: system_vm_size
        osSKU: 'Mariner'
        osDiskType: 'Ephemeral'
        osDiskSizeGB: 30
        type: 'VirtualMachineScaleSets'
        tags: tags
      }
    ]

    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      loadBalancerSku: 'standard'
    }
  }
}

// define output
output aksName string = aksCluster.name
output aksIssuerURL string = aksCluster.properties.oidcIssuerProfile.issuerURL

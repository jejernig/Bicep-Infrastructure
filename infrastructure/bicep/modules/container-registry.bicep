@description('The name of the Container Registry')
param name string

@description('The Azure region for the resource')
param location string

@description('Resource tags')
param tags object

@description('The SKU of the Container Registry')
param skuName string = 'Standard'

@description('Whether admin user is enabled')
param adminUserEnabled bool = true

@description('Whether public network access is allowed')
param publicNetworkAccess string = 'Enabled'

@description('Whether anonymous pull is enabled')
param anonymousPullEnabled bool = false

@description('Whether zone redundancy is enabled')
param zoneRedundancy string = 'Disabled'

@description('Whether data endpoint is enabled')
param dataEndpointEnabled bool = false

@description('Whether network rule bypass is enabled')
param networkRuleBypassOptions string = 'AzureServices'

// Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: publicNetworkAccess
    anonymousPullEnabled: anonymousPullEnabled
    zoneRedundancy: zoneRedundancy
    dataEndpointEnabled: dataEndpointEnabled
    networkRuleBypassOptions: networkRuleBypassOptions
  }
}

// Outputs
output id string = containerRegistry.id
output name string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
output adminUsername string = containerRegistry.name
output adminPassword string = listCredentials(containerRegistry.id, containerRegistry.apiVersion).passwords[0].value

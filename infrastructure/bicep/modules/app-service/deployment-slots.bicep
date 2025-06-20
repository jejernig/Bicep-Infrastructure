@description('Name of the parent App Service')
param appServiceName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Array of deployment slot configurations')
param slots array = []

@description('Tags to apply to resources')
param tags object = {}

// Reference the parent App Service
resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

// Create deployment slots
resource deploymentSlot 'Microsoft.Web/sites/slots@2022-03-01' = [for slot in slots: {
  name: '${appServiceName}/${slot.name}'
  location: location
  tags: union(tags, contains(slot, 'tags') ? slot.tags : {})
  kind: contains(slot, 'kind') ? slot.kind : appService.kind
  identity: contains(slot, 'identity') ? slot.identity : null
  properties: {
    serverFarmId: appService.properties.serverFarmId
    httpsOnly: contains(slot, 'httpsOnly') ? slot.httpsOnly : true
    siteConfig: contains(slot, 'siteConfig') ? slot.siteConfig : {
      appSettings: contains(slot, 'appSettings') ? slot.appSettings : []
      linuxFxVersion: contains(slot, 'linuxFxVersion') ? slot.linuxFxVersion : null
      netFrameworkVersion: contains(slot, 'netFrameworkVersion') ? slot.netFrameworkVersion : null
      phpVersion: contains(slot, 'phpVersion') ? slot.phpVersion : null
      nodeVersion: contains(slot, 'nodeVersion') ? slot.nodeVersion : null
      javaVersion: contains(slot, 'javaVersion') ? slot.javaVersion : null
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      autoSwapSlotName: contains(slot, 'autoSwapSlotName') ? slot.autoSwapSlotName : null
    }
  }
}]

// Create slot configuration names if specified
resource slotConfigNames 'Microsoft.Web/sites/config@2022-03-01' = if (contains(slots, 'stickySettings')) {
  name: '${appServiceName}/slotConfigNames'
  properties: {
    appSettingNames: contains(slots, 'stickySettings') && contains(slots.stickySettings, 'appSettingNames') ? slots.stickySettings.appSettingNames : []
    connectionStringNames: contains(slots, 'stickySettings') && contains(slots.stickySettings, 'connectionStringNames') ? slots.stickySettings.connectionStringNames : []
    azureStorageConfigNames: contains(slots, 'stickySettings') && contains(slots.stickySettings, 'azureStorageConfigNames') ? slots.stickySettings.azureStorageConfigNames : []
  }
  dependsOn: [
    appService
  ]
}

// Outputs
output slotNames array = [for (slot, i) in slots: {
  name: slot.name
  id: deploymentSlot[i].id
  hostname: deploymentSlot[i].properties.defaultHostName
}]

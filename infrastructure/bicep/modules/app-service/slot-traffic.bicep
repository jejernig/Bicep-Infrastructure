@description('Name of the parent App Service')
param appServiceName string

@description('Traffic routing settings for deployment slots')
param slotTrafficSettings array = []

// Reference the parent App Service
resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

// Configure traffic routing percentages for each slot
resource slotTraffic 'Microsoft.Web/sites/config@2022-03-01' = {
  name: '${appServiceName}/slotConfigNames'
  properties: {
    // Convert array of objects to key-value pairs for routing rules
    // Example input: [{ slotName: 'staging', percentage: 20 }, { slotName: 'test', percentage: 10 }]
    // Example output: { staging: 20, test: 10 }
    routingRules: reduce(slotTrafficSettings, {}, (result, current) => union(result, { '${current.slotName}': current.percentage }))
  }
  dependsOn: [
    appService
  ]
}

// Outputs
output slotTrafficSettings array = slotTrafficSettings

@description('Name of the App Service')
param appServiceName string

@description('Array of app settings')
param appSettings array = []

@description('Array of connection strings')
param connectionStrings array = []

@description('Name of the slot to apply configuration to (if any)')
param slotName string = ''

// Reference the App Service
resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

// Apply app settings to the App Service or slot
resource appServiceConfig 'Microsoft.Web/sites/config@2022-03-01' = if (empty(slotName)) {
  name: '${appServiceName}/appsettings'
  properties: {
    // Convert array of objects to key-value pairs
    // Example input: [{ name: 'Setting1', value: 'Value1' }, { name: 'Setting2', value: 'Value2' }]
    // Example output: { Setting1: 'Value1', Setting2: 'Value2' }
    '${reduce(appSettings, {}, (result, current) => union(result, { '${current.name}': current.value }))}'
  }
  dependsOn: [
    appService
  ]
}

// Apply connection strings to the App Service or slot
resource connectionStringsConfig 'Microsoft.Web/sites/config@2022-03-01' = if (empty(slotName) && !empty(connectionStrings)) {
  name: '${appServiceName}/connectionstrings'
  properties: {
    // Convert array of objects to key-value pairs with type
    // Example input: [{ name: 'Conn1', value: 'Value1', type: 'SQLAzure' }]
    // Example output: { Conn1: { value: 'Value1', type: 'SQLAzure' } }
    '${reduce(connectionStrings, {}, (result, current) => union(result, { '${current.name}': { value: current.value, type: current.type } }))}'
  }
  dependsOn: [
    appService
  ]
}

// Apply app settings to a slot if specified
resource slotAppServiceConfig 'Microsoft.Web/sites/slots/config@2022-03-01' = if (!empty(slotName)) {
  name: '${appServiceName}/${slotName}/appsettings'
  properties: {
    '${reduce(appSettings, {}, (result, current) => union(result, { '${current.name}': current.value }))}'
  }
  dependsOn: [
    appService
  ]
}

// Apply connection strings to a slot if specified
resource slotConnectionStringsConfig 'Microsoft.Web/sites/slots/config@2022-03-01' = if (!empty(slotName) && !empty(connectionStrings)) {
  name: '${appServiceName}/${slotName}/connectionstrings'
  properties: {
    '${reduce(connectionStrings, {}, (result, current) => union(result, { '${current.name}': { value: current.value, type: current.type } }))}'
  }
  dependsOn: [
    appService
  ]
}

// Outputs
output appSettingsNames array = [for setting in appSettings: setting.name]
output connectionStringNames array = [for conn in connectionStrings: conn.name]

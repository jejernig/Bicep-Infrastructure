@description('Name of the parent App Service')
param appServiceName string

@description('Name of the slot to configure pre-warmed instances for')
param slotName string = ''

@description('Number of pre-warmed instances')
param preWarmedCount int = 1

// Reference the App Service
resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

// Configure pre-warmed instances for the main App Service
resource appServicePreWarmed 'Microsoft.Web/sites/config@2022-03-01' = if (empty(slotName)) {
  name: '${appServiceName}/web'
  properties: {
    preWarmedInstanceCount: preWarmedCount
  }
  dependsOn: [
    appService
  ]
}

// Configure pre-warmed instances for a slot if specified
resource slotPreWarmed 'Microsoft.Web/sites/slots/config@2022-03-01' = if (!empty(slotName)) {
  name: '${appServiceName}/${slotName}/web'
  properties: {
    preWarmedInstanceCount: preWarmedCount
  }
  dependsOn: [
    appService
  ]
}

// Outputs
output preWarmedCount int = preWarmedCount

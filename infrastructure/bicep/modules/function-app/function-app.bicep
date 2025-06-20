@description('Name of the Function App')
param functionAppName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Runtime stack for the Function App')
param runtime string = 'dotnet'

@description('Runtime version')
param runtimeVersion string = '6'

@description('Function App SKU')
param sku string = 'Y1' // Default to Consumption plan

@description('OS type (Windows or Linux)')
param osType string = 'Windows'

@description('Reference to the hosting plan ID')
param hostingPlanId string

@description('Reference to the storage account name')
param storageAccountName string

@description('Reference to the Application Insights instrumentation key')
param appInsightsInstrumentationKey string = ''

@description('Reference to the Application Insights connection string')
param appInsightsConnectionString string = ''

@description('Array of app settings')
param appSettings array = []

@description('Array of connection strings')
param connectionStrings array = []

@description('Enable system-assigned managed identity')
param systemAssignedIdentity bool = false

@description('User-assigned managed identities to assign to the Function App')
param userAssignedIdentities object = {}

@description('Tags to apply to resources')
param tags object = {}

// Reference the storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccountName
}

// Create the Function App
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: osType == 'Windows' ? 'functionapp' : 'functionapp,linux'
  tags: tags
  identity: {
    type: systemAssignedIdentity && !empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : (systemAssignedIdentity ? 'SystemAssigned' : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None'))
    userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
  }
  properties: {
    serverFarmId: hostingPlanId
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      functionAppScaleLimit: sku == 'Y1' ? 200 : null
      minimumElasticInstanceCount: sku == 'EP1' || sku == 'EP2' || sku == 'EP3' ? 1 : null
      appSettings: concat(
        [
          {
            name: 'AzureWebJobsStorage'
            value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
          }
          {
            name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
            value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
          }
          {
            name: 'WEBSITE_CONTENTSHARE'
            value: toLower(functionAppName)
          }
          {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: '~4'
          }
          {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: runtime
          }
          {
            name: 'WEBSITE_NODE_DEFAULT_VERSION'
            value: runtime == 'node' ? '~16' : null
          }
          {
            name: 'WEBSITE_RUN_FROM_PACKAGE'
            value: '1'
          }
        ],
        !empty(appInsightsInstrumentationKey) ? [
          {
            name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
            value: appInsightsInstrumentationKey
          }
        ] : [],
        !empty(appInsightsConnectionString) ? [
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: appInsightsConnectionString
          }
        ] : [],
        appSettings
      )
      linuxFxVersion: osType == 'Linux' ? '${runtime}|${runtimeVersion}' : null
      netFrameworkVersion: runtime == 'dotnet' && osType == 'Windows' ? 'v6.0' : null
    }
  }
}

// Configure connection strings if specified
resource functionAppConnectionStrings 'Microsoft.Web/sites/config@2022-03-01' = if (!empty(connectionStrings)) {
  name: '${functionAppName}/connectionstrings'
  properties: {
    // Convert array of connection strings to object format required by the API
    // Example input: [{ name: 'MyDb', value: 'connection-string', type: 'SQLAzure' }]
    // Example output: { MyDb: { value: 'connection-string', type: 'SQLAzure' } }
    connectionStrings: reduce(connectionStrings, {}, (result, current) => union(result, { '${current.name}': { value: current.value, type: current.type } }))
  }
  dependsOn: [
    functionApp
  ]
}

// Outputs
output functionAppId string = functionApp.id
output functionAppName string = functionApp.name
output defaultHostName string = functionApp.properties.defaultHostName
output principalId string = systemAssignedIdentity ? functionApp.identity.principalId : ''

@description('Name of the App Service')
param appServiceName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('SKU for the App Service Plan')
param sku string = 'B1'

@description('Runtime stack for the App Service')
param runtimeStack string = 'dotnet:6'

@description('Array of app settings')
param appSettings array = []

@description('Tags to apply to resources')
param tags object = {}

@description('Enable system-assigned managed identity')
param systemAssignedIdentity bool = false

@description('User-assigned managed identities to assign to the App Service')
param userAssignedIdentities object = {}

@description('Enable diagnostic settings')
param enableDiagnostics bool = false

@description('Resource ID of the Log Analytics workspace for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Resource ID of the Storage Account for diagnostics')
param diagnosticsStorageAccountId string = ''

@description('Resource ID of the Event Hub for diagnostics')
param eventHubAuthorizationRuleId string = ''

@description('Resource ID of the Event Hub Namespace for diagnostics')
param eventHubNamespaceId string = ''

@description('Log categories to enable for diagnostics')
param diagnosticLogCategories array = [
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceAuditLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
]

@description('Retention days for diagnostic logs')
param diagnosticLogsRetentionInDays int = 30

// Determine if the runtime stack is Linux-based
var isLinux = contains(toLower(runtimeStack), 'linux') || contains(toLower(runtimeStack), 'node') || contains(toLower(runtimeStack), 'python') || contains(toLower(runtimeStack), 'php') || contains(toLower(runtimeStack), 'java')

// Determine the identity type based on parameters
var identityType = systemAssignedIdentity && !empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : (systemAssignedIdentity ? 'SystemAssigned' : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None'))

// Create the App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${appServiceName}-plan'
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: isLinux ? 'linux' : 'windows'
  properties: {
    reserved: isLinux
  }
}

// Create the App Service
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  tags: tags
  kind: isLinux ? 'app,linux' : 'app'
  identity: {
    type: identityType
    userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: appSettings
      linuxFxVersion: isLinux ? runtimeStack : null
      netFrameworkVersion: !isLinux && contains(toLower(runtimeStack), 'dotnet') ? runtimeStack : null
      phpVersion: !isLinux && contains(toLower(runtimeStack), 'php') ? runtimeStack : null
      nodeVersion: !isLinux && contains(toLower(runtimeStack), 'node') ? runtimeStack : null
      javaVersion: !isLinux && contains(toLower(runtimeStack), 'java') ? runtimeStack : null
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
  }
}

// Create diagnostic settings if enabled
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: '${appServiceName}-diagnostics'
  scope: appService
  properties: {
    workspaceId: !empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspaceId : null
    storageAccountId: !empty(diagnosticsStorageAccountId) ? diagnosticsStorageAccountId : null
    eventHubAuthorizationRuleId: !empty(eventHubAuthorizationRuleId) ? eventHubAuthorizationRuleId : null
    eventHubName: !empty(eventHubNamespaceId) ? eventHubNamespaceId : null
    logs: [for category in diagnosticLogCategories: {
      category: category
      enabled: true
      retentionPolicy: {
        enabled: true
        days: diagnosticLogsRetentionInDays
      }
    }]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: diagnosticLogsRetentionInDays
        }
      }
    ]
  }
}

// Outputs
output appServiceId string = appService.id
output appServiceName string = appService.name
output appServicePlanId string = appServicePlan.id
output appServicePlanName string = appServicePlan.name
output defaultHostName string = appService.properties.defaultHostName
output principalId string = systemAssignedIdentity ? appService.identity.principalId : ''

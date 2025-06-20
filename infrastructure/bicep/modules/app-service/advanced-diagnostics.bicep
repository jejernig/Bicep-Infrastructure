@description('Name of the App Service')
param appServiceName string

@description('Name of the slot (if any)')
param slotName string = ''

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

@description('Enable Application Insights integration')
param enableApplicationInsights bool = false

@description('Name of the Application Insights instance')
param applicationInsightsName string = ''

@description('Location for the resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the App Service
resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

// Reference the App Service slot if specified
resource appServiceSlot 'Microsoft.Web/sites/slots@2022-03-01' existing = if (!empty(slotName)) {
  name: '${appServiceName}/${slotName}'
}

// Create Application Insights if enabled
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableApplicationInsights) {
  name: !empty(applicationInsightsName) ? applicationInsightsName : '${appServiceName}-insights'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    Flow_Type: 'Redfield'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Configure Application Insights for the App Service
resource appServiceAppInsights 'Microsoft.Web/sites/config@2022-03-01' = if (enableApplicationInsights && empty(slotName)) {
  name: '${appServiceName}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: enableApplicationInsights ? applicationInsights.properties.InstrumentationKey : ''
    APPLICATIONINSIGHTS_CONNECTION_STRING: enableApplicationInsights ? applicationInsights.properties.ConnectionString : ''
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
  }
  dependsOn: [
    appService
  ]
}

// Configure Application Insights for the App Service slot if specified
resource slotAppInsights 'Microsoft.Web/sites/slots/config@2022-03-01' = if (enableApplicationInsights && !empty(slotName)) {
  name: '${appServiceName}/${slotName}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: enableApplicationInsights ? applicationInsights.properties.InstrumentationKey : ''
    APPLICATIONINSIGHTS_CONNECTION_STRING: enableApplicationInsights ? applicationInsights.properties.ConnectionString : ''
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
  }
  dependsOn: [
    appServiceSlot
  ]
}

// Create diagnostic settings for the App Service
resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (empty(slotName)) {
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

// Create diagnostic settings for the App Service slot if specified
resource slotDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(slotName)) {
  name: '${appServiceName}-${slotName}-diagnostics'
  scope: appServiceSlot
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
output applicationInsightsId string = enableApplicationInsights ? applicationInsights.id : ''
output applicationInsightsName string = enableApplicationInsights ? applicationInsights.name : ''
output applicationInsightsInstrumentationKey string = enableApplicationInsights ? applicationInsights.properties.InstrumentationKey : ''
output applicationInsightsConnectionString string = enableApplicationInsights ? applicationInsights.properties.ConnectionString : ''

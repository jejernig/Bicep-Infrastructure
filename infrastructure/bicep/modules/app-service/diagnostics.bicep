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

// Reference the App Service
resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

// Reference the App Service slot if specified
resource appServiceSlot 'Microsoft.Web/sites/slots@2022-03-01' existing = if (!empty(slotName)) {
  name: '${appServiceName}/${slotName}'
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

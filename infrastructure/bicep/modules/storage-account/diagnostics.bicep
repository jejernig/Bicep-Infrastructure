param storageAccountName string
param location string = resourceGroup().location
param tags object = {}

@description('The resource ID of the Log Analytics workspace to send diagnostics to')
param logAnalyticsWorkspaceId string = ''

@description('The name of the diagnostic settings')
param diagnosticSettingsName string = 'diagnostic-settings-storage'

@description('Enable all supported metrics')
param enableAllMetrics bool = true

@description('Enable all available logs')
param enableAllLogs bool = true

@description('Retention policy for metrics in days. Set to 0 to retain the data indefinitely.')
@minValue(0)
@maxValue(365)
param metricsRetentionInDays int = 30

@description('Retention policy for logs in days. Set to 0 to retain the data indefinitely.')
@minValue(0)
@maxValue(365)
param logsRetentionInDays int = 30

// Get the storage account resource ID
var storageAccountId = resourceId('Microsoft.Storage/storageAccounts', storageAccountName)

// Diagnostic settings for the storage account
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: diagnosticSettingsName
  scope: storageAccountId
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: enableAllMetrics ? [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy: {
          days: metricsRetentionInDays
          enabled: metricsRetentionInDays > 0
        }
      }
      {
        category: 'Capacity'
        enabled: true
        retentionPolicy: {
          days: metricsRetentionInDays
          enabled: metricsRetentionInDays > 0
        }
      }
    ] : []
    logs: enableAllLogs ? [
      {
        category: 'StorageRead'
        enabled: true
        retentionPolicy: {
          days: logsRetentionInDays
          enabled: logsRetentionInDays > 0
        }
      }
      {
        category: 'StorageWrite'
        enabled: true
        retentionPolicy: {
          days: logsRetentionInDays
          enabled: logsRetentionInDays > 0
        }
      }
      {
        category: 'StorageDelete'
        enabled: true
        retentionPolicy: {
          days: logsRetentionInDays
          enabled: logsRetentionInDays > 0
        }
      }
    ] : []
  }
}

// Outputs
output diagnosticSettingsId string = !empty(logAnalyticsWorkspaceId) ? diagnosticSettings.id : ''
output diagnosticSettingsName string = !empty(logAnalyticsWorkspaceId) ? diagnosticSettings.name : ''

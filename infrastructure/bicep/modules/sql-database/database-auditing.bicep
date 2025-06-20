@description('Name of the SQL Server')
param sqlServerName string

@description('Name of the SQL Database')
param sqlDatabaseName string

@description('Enable or disable database auditing')
param enabled bool = true

@description('Audit log retention days (0 means unlimited)')
@minValue(0)
@maxValue(365)
param retentionDays int = 0

@description('Storage account resource ID for audit logs')
param storageAccountId string = ''

@description('Log Analytics workspace resource ID for audit logs')
param workspaceId string = ''

@description('Event Hub authorization rule resource ID for audit logs')
param eventHubAuthorizationRuleId string = ''

@description('Event Hub name for audit logs')
param eventHubName string = ''

// Reference the SQL Server and Database
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' existing = {
  parent: sqlServer
  name: sqlDatabaseName
}

// Configure database auditing
resource databaseAuditing 'Microsoft.Sql/servers/databases/auditingSettings@2022-05-01-preview' = {
  parent: sqlDatabase
  name: 'default'
  properties: {
    state: enabled ? 'Enabled' : 'Disabled'
    retentionDays: retentionDays
    storageEndpoint: !empty(storageAccountId) ? reference(storageAccountId, '2021-08-01').primaryEndpoints.blob : null
    storageAccountAccessKey: !empty(storageAccountId) ? listKeys(storageAccountId, '2021-08-01').keys[0].value : null
    storageAccountSubscriptionId: !empty(storageAccountId) ? subscription().subscriptionId : null
    isAzureMonitorTargetEnabled: !empty(workspaceId)
    workspaceResourceId: !empty(workspaceId) ? workspaceId : null
    isDevopsAuditEnabled: false
    eventHubAuthorizationRuleId: !empty(eventHubAuthorizationRuleId) ? eventHubAuthorizationRuleId : null
    eventHubName: !empty(eventHubName) ? eventHubName : null
  }
}

// Outputs
output auditingState string = databaseAuditing.properties.state

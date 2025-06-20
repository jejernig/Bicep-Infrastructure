@description('Name of the SQL Server')
param sqlServerName string

@description('Name of the SQL Database')
param sqlDatabaseName string

@description('Enable or disable advanced threat protection')
param enabled bool = true

@description('Email addresses for alerts')
param emailAddresses array = []

@description('Email account administrators')
param emailAccountAdmins bool = false

@description('Storage account resource ID for threat detection logs')
param storageAccountId string = ''

@description('Retention days for threat detection logs')
@minValue(0)
@maxValue(365)
param retentionDays int = 0

@description('Disabled alerts')
param disabledAlerts array = []

// Reference the SQL Server and Database
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' existing = {
  parent: sqlServer
  name: sqlDatabaseName
}

// Configure advanced threat protection
resource threatProtection 'Microsoft.Sql/servers/databases/securityAlertPolicies@2022-05-01-preview' = {
  parent: sqlDatabase
  name: 'default'
  properties: {
    state: enabled ? 'Enabled' : 'Disabled'
    emailAccountAdmins: emailAccountAdmins
    emailAddresses: emailAddresses
    retentionDays: retentionDays
    storageEndpoint: !empty(storageAccountId) ? reference(storageAccountId, '2021-08-01').primaryEndpoints.blob : null
    storageAccountAccessKey: !empty(storageAccountId) ? listKeys(storageAccountId, '2021-08-01').keys[0].value : null
    disabledAlerts: disabledAlerts
  }
}

// Outputs
output threatProtectionState string = threatProtection.properties.state

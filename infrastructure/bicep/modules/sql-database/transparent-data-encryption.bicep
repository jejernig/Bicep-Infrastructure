@description('Name of the SQL Server')
param sqlServerName string

@description('Name of the SQL Database')
param sqlDatabaseName string

@description('Enable or disable transparent data encryption')
param enabled bool = true

@description('Key type for transparent data encryption')
@allowed([
  'ServiceManaged'
  'AzureKeyVault'
])
param keyType string = 'ServiceManaged'

@description('Key URI for customer-managed key')
param keyUri string = ''

// Reference the SQL Server and Database
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' existing = {
  parent: sqlServer
  name: sqlDatabaseName
}

// Configure transparent data encryption
resource transparentDataEncryption 'Microsoft.Sql/servers/databases/transparentDataEncryption@2022-05-01-preview' = {
  parent: sqlDatabase
  name: 'current'
  properties: {
    state: enabled ? 'Enabled' : 'Disabled'
    keyType: keyType
    serverKeyName: keyType == 'AzureKeyVault' && !empty(keyUri) ? 'AzureKeyVault' : null
    serverKeyType: keyType == 'AzureKeyVault' && !empty(keyUri) ? 'AzureKeyVault' : null
  }
}

// Outputs
output tdeState string = transparentDataEncryption.properties.state
output tdeKeyType string = transparentDataEncryption.properties.keyType

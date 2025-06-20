@description('Name of the primary SQL Server')
param primaryServerName string

@description('Name of the primary SQL Database')
param primaryDatabaseName string

@description('Name of the secondary SQL Server')
param secondaryServerName string

@description('Name of the secondary SQL Database')
param secondaryDatabaseName string = primaryDatabaseName

@description('Location for the secondary database')
param secondaryLocation string

@description('Secondary database SKU')
param secondarySku object = {
  name: 'Standard'
  tier: 'Standard'
  capacity: 10
}

@description('Enable read-only access to secondary database')
param readOnlyEndpointFailoverPolicy bool = true

@description('Tags to apply to resources')
param tags object = {}

// Reference the primary SQL Server and Database
resource primaryServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: primaryServerName
}

resource primaryDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' existing = {
  parent: primaryServer
  name: primaryDatabaseName
}

// Reference the secondary SQL Server
resource secondaryServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: secondaryServerName
}

// Create the secondary database as a replica
resource secondaryDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: secondaryServer
  name: secondaryDatabaseName
  location: secondaryLocation
  tags: tags
  sku: secondarySku
  properties: {
    createMode: 'Secondary'
    secondaryType: 'Geo'
    sourceDatabaseId: primaryDatabase.id
    readScale: readOnlyEndpointFailoverPolicy ? 'Enabled' : 'Disabled'
  }
}

// Outputs
output secondaryDatabaseId string = secondaryDatabase.id
output secondaryDatabaseName string = secondaryDatabase.name

@description('Name of the SQL Server')
param sqlServerName string

@description('Name of the SQL Database')
param sqlDatabaseName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Database SKU')
param sku object = {
  name: 'Basic'
  tier: 'Basic'
  capacity: 5
}

@description('Database collation')
param collation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('Maximum database size in bytes')
param maxSizeBytes int = 2147483648 // 2GB

@description('Enable zone redundancy')
param zoneRedundant bool = false

@description('Enable read scale')
param readScale string = 'Disabled'

@description('License type')
@allowed([
  'LicenseIncluded'
  'BasePrice'
])
param licenseType string = 'LicenseIncluded'

@description('High availability replica count')
@allowed([
  0
  1
  2
  3
  4
])
param highAvailabilityReplicaCount int = 0

@description('Database backup storage redundancy')
@allowed([
  'Geo'
  'Local'
  'Zone'
])
param requestedBackupStorageRedundancy string = 'Geo'

@description('Tags to apply to resources')
param tags object = {}

// Reference the SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

// Create SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: sku
  properties: {
    collation: collation
    maxSizeBytes: maxSizeBytes
    zoneRedundant: zoneRedundant
    readScale: readScale
    licenseType: licenseType
    highAvailabilityReplicaCount: highAvailabilityReplicaCount
    requestedBackupStorageRedundancy: requestedBackupStorageRedundancy
  }
}

// Outputs
output sqlDatabaseId string = sqlDatabase.id
output sqlDatabaseName string = sqlDatabase.name

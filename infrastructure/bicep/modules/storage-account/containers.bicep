param storageAccountName string
param location string = resourceGroup().location
param tags object = {}

@description('List of blob containers to create')
param blobContainers array = []

@description('List of file shares to create')
param fileShares array = []

@description('List of queues to create')
param queues array = []

@description('List of tables to create')
param tables array = []

@description('The SKU name of the storage account')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param skuName string = 'Standard_GRS'

// Helper function to create a valid DNS name
var sanitizedStorageAccountName = toLower(replace(storageAccountName, '[^a-z0-9]', ''))

// Blob Containers
resource blobContainersResources 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for (container, i) in blobContainers: {
  name: '${storageAccountName}/default/${container.name}'
  properties: {
    publicAccess: container.publicAccess
    metadata: container.metadata
    defaultEncryptionScope: container.defaultEncryptionScope
    denyEncryptionScopeOverride: container.denyEncryptionScopeOverride
    enableNfsV3AllSquash: container.enableNfsV3AllSquash
    enableNfsV3RootSquash: container.enableNfsV3RootSquash
  }
}]

// File Shares
resource fileSharesResources 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = [for (share, i) in fileShares: {
  name: '${storageAccountName}/default/${share.name}'
  properties: {
    accessTier: share.accessTier
    shareQuota: share.quotaInGB
    enabledProtocols: share.enabledProtocols
    rootSquash: share.rootSquash
    metadata: share.metadata
  }
}]

// Queues
resource queuesResources 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-09-01' = [for (queue, i) in queues: {
  name: '${storageAccountName}/default/${queue.name}'
  properties: {
    metadata: queue.metadata
  }
}]

// Tables
resource tablesResources 'Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01' = [for (table, i) in tables: {
  name: '${storageAccountName}/default/${table.name}'
}]

// Outputs
output blobContainers array = [for container in blobContainersResources: {
  name: container.name
  id: container.id
  type: container.type
  properties: container.properties
}]

output fileShares array = [for share in fileSharesResources: {
  name: share.name
  id: share.id
  type: share.type
  properties: share.properties
}]

output queues array = [for queue in queuesResources: {
  name: queue.name
  id: queue.id
  type: queue.type
  properties: queue.properties
}]

output tables array = [for table in tablesResources: {
  name: table.name
  id: table.id
  type: table.type
}]

@description('Name of the storage account')
param storageAccountName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('SKU for the storage account')
param sku string = 'Standard_LRS'

@description('Kind of storage account')
param kind string = 'StorageV2'

@description('Enable hierarchical namespace (for Data Lake Storage)')
param enableHierarchicalNamespace bool = false

@description('Enable blob public access')
param allowBlobPublicAccess bool = false

@description('Enable shared key access')
param allowSharedKeyAccess bool = true

@description('Minimum TLS version')
param minimumTlsVersion string = 'TLS1_2'

@description('Enable blob soft delete')
param enableBlobSoftDelete bool = true

@description('Blob soft delete retention days')
param blobSoftDeleteRetentionDays int = 7

@description('Enable container soft delete')
param enableContainerSoftDelete bool = true

@description('Container soft delete retention days')
param containerSoftDeleteRetentionDays int = 7

@description('Enable file share soft delete')
param enableShareSoftDelete bool = true

@description('File share soft delete retention days')
param shareSoftDeleteRetentionDays int = 7

@description('Tags to apply to resources')
param tags object = {}

// Create the storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    accessTier: kind == 'StorageV2' || kind == 'BlobStorage' ? 'Hot' : null
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        queue: {
          enabled: true
        }
        table: {
          enabled: true
        }
      }
    }
    isHnsEnabled: enableHierarchicalNamespace
    minimumTlsVersion: minimumTlsVersion
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
  }
}

// Configure blob service properties
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  name: '${storageAccountName}/default'
  properties: {
    deleteRetentionPolicy: {
      enabled: enableBlobSoftDelete
      days: enableBlobSoftDelete ? blobSoftDeleteRetentionDays : null
    }
    containerDeleteRetentionPolicy: {
      enabled: enableContainerSoftDelete
      days: enableContainerSoftDelete ? containerSoftDeleteRetentionDays : null
    }
  }
  dependsOn: [
    storageAccount
  ]
}

// Configure file service properties
resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2022-05-01' = {
  name: '${storageAccountName}/default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: enableShareSoftDelete
      days: enableShareSoftDelete ? shareSoftDeleteRetentionDays : null
    }
  }
  dependsOn: [
    storageAccount
  ]
}

// Create a container for function app deployments
resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${storageAccountName}/default/function-releases'
  properties: {
    publicAccess: 'None'
  }
  dependsOn: [
    blobServices
  ]
}

// Outputs
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'

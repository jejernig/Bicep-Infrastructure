@description('Name of the storage account')
param storageAccountName string

@description('Location for the storage account.')
param location string = resourceGroup().location

@description('The SKU of the storage account.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param storageSku string = 'Standard_LRS'

@description('File shares to create in the storage account')
param fileShares array = []

@description('Enable blob encryption at rest')
param enableBlobEncryption bool = true

@description('Enable file encryption at rest')
param enableFileEncryption bool = true

@description('Enable https traffic only')
param enableHttpsTrafficOnly bool = true

@description('Tags to apply to the resources')
param tags object = {}

@description('Allow public access to blobs')
param allowBlobPublicAccess bool = false

@description('Minimum TLS version')
param minimumTlsVersion string = 'TLS1_2'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: enableHttpsTrafficOnly
    encryption: {
      services: {
        blob: {
          enabled: enableBlobEncryption
        }
        file: {
          enabled: enableFileEncryption
        }
      }
      keySource: 'Microsoft.Storage'
    }
    allowBlobPublicAccess: allowBlobPublicAccess
    minimumTlsVersion: minimumTlsVersion
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// Create file shares if specified
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = [for share in fileShares: {
  name: '${storageAccountName}/default/${share.name}'
  properties: {
    shareQuota: share.quota
    enabledProtocols: 'SMB'
  }
  dependsOn: [
    storageAccount
  ]
}]

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output storageAccountKey string = listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output primaryFileEndpoint string = storageAccount.properties.primaryEndpoints.file

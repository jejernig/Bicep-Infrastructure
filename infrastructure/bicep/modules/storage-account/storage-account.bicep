param storageAccountName string
param location string = resourceGroup().location
param tags object = {}

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

@description('The SKU tier')
@allowed([
  'Standard'
  'Premium'
])
param skuTier string = 'Standard'

@description('The kind of storage account')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param kind string = 'StorageV2'

@description('The access tier for BlobStorage and GPv2 accounts')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

@description('Enable hierarchical namespace (Azure Data Lake Storage Gen2)')
param isHnsEnabled bool = false

@description('Allow or disallow public access to all blobs or containers in the storage account')
param allowBlobPublicAccess bool = false

@description('Restrict copy to and from Storage Accounts within an AAD tenant or with Private Links to the same VNet')
param allowedCopyScope string = 'AAD'

@description('The minimum TLS version for requests to storage')
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
])
param minimumTlsVersion string = 'TLS1_2'

@description('Allow or disallow cross AAD tenant object replication')
param allowCrossTenantReplication bool = false

@description('Enable infrastructure encryption for data at rest')
param requireInfrastructureEncryption bool = false

@description('Allow shared key access to the storage account')
param allowSharedKeyAccess bool = true

@description('Enable NFSv3 protocol')
param isSftpEnabled bool = false

@description('Enable SMB Multichannel')
param isSMBMultichannelEnabled bool = true

@description('The network rule set')
param networkRuleSet object = {
  bypass: 'AzureServices'
  defaultAction: 'Allow'
  ipRules: []
  virtualNetworkRules: []
  resourceAccessRules: []
}

@description('The custom domain to use for the storage account')
param customDomain object = {
  name: ''
  useSubDomain: true
}

@description('The encryption settings')
param encryption object = {
  keySource: 'Microsoft.Storage'
  requireInfrastructureEncryption: false
  services: {
    blob: {
      enabled: true
      keyType: 'Account'
    }
    file: {
      enabled: true
      keyType: 'Account'
    }
    table: {
      enabled: true
      keyType: 'Account'
    }
    queue: {
      enabled: true
      keyType: 'Account'
    }
  }
}

@description('The identity for the storage account')
param identity object = {
  type: 'None'
  userAssignedIdentities: {}
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: kind
  properties: {
    accessTier: kind == 'BlobStorage' || kind == 'StorageV2' ? accessTier : null
    isHnsEnabled: isHnsEnabled
    allowBlobPublicAccess: allowBlobPublicAccess
    allowedCopyScope: allowedCopyScope
    minimumTlsVersion: minimumTlsVersion
    allowCrossTenantReplication: allowCrossTenantReplication
    requireInfrastructureEncryption: requireInfrastructureEncryption
    allowSharedKeyAccess: allowSharedKeyAccess
    isSftpEnabled: isSftpEnabled
    isSMBMultichannelEnabled: isSMBMultichannelEnabled
    networkAcls: networkRuleSet
    customDomain: !empty(customDomain.name) ? customDomain : null
    encryption: encryption
    supportsHttpsTrafficOnly: true
    largeFileSharesState: 'Disabled'
  }
  identity: identity.type == 'None' ? null : identity
}

output id string = storageAccount.id
output name string = storageAccount.name
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
output primaryLocation string = storageAccount.properties.primaryLocation
output statusOfPrimary string = storageAccount.properties.statusOfPrimary
output secondaryLocation string = storageAccount.properties.secondaryLocation
output statusOfSecondary string = storageAccount.properties.statusOfSecondary
output primaryEndpointsBlob string = storageAccount.properties.primaryEndpoints.blob
output primaryEndpointsQueue string = storageAccount.properties.primaryEndpoints.queue
output primaryEndpointsTable string = storageAccount.properties.primaryEndpoints.table
output primaryEndpointsFile string = storageAccount.properties.primaryEndpoints.file
output primaryEndpointsWeb string = storageAccount.properties.primaryEndpoints.web
output primaryLocationBlob string = '${storageAccount.properties.primaryEndpoints.blob}'
output primaryLocationQueue string = '${storageAccount.properties.primaryEndpoints.queue}'
output primaryLocationTable string = '${storageAccount.properties.primaryEndpoints.table}'
output primaryLocationFile string = '${storageAccount.properties.primaryEndpoints.file}'
output primaryLocationWeb string = '${storageAccount.properties.primaryEndpoints.web}'
output secondaryLocationBlob string = !empty(storageAccount.properties.secondaryEndpoints) ? '${storageAccount.properties.secondaryEndpoints.blob}' : ''
output secondaryLocationQueue string = !empty(storageAccount.properties.secondaryEndpoints) ? '${storageAccount.properties.secondaryEndpoints.queue}' : ''
output secondaryLocationTable string = !empty(storageAccount.properties.secondaryEndpoints) ? '${storageAccount.properties.secondaryEndpoints.table}' : ''
output secondaryLocationFile string = !empty(storageAccount.properties.secondaryEndpoints) ? '${storageAccount.properties.secondaryEndpoints.file}' : ''
output secondaryLocationWeb string = !empty(storageAccount.properties.secondaryEndpoints) ? '${storageAccount.properties.secondaryEndpoints.web}' : ''
output primaryAccessKey string = listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
output secondaryAccessKey string = listKeys(storageAccount.id, storageAccount.apiVersion).keys[1].value
output connectionString object = {
  primaryBlob: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  primaryQueue: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  primaryTable: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  primaryFile: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  primaryWeb: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  secondaryBlob: !empty(storageAccount.properties.secondaryEndpoints) ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[1].value};EndpointSuffix=${environment().suffixes.storage}' : ''
  secondaryQueue: !empty(storageAccount.properties.secondaryEndpoints) ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[1].value};EndpointSuffix=${environment().suffixes.storage}' : ''
  secondaryTable: !empty(storageAccount.properties.secondaryEndpoints) ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[1].value};EndpointSuffix=${environment().suffixes.storage}' : ''
  secondaryFile: !empty(storageAccount.properties.secondaryEndpoints) ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[1].value};EndpointSuffix=${environment().suffixes.storage}' : ''
  secondaryWeb: !empty(storageAccount.properties.secondaryEndpoints) ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[1].value};EndpointSuffix=${environment().suffixes.storage}' : ''
}

@description('Name of the Key Vault')
param keyVaultName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('SKU name for the Key Vault')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('SKU family for the Key Vault')
param skuFamily string = 'A'

@description('Enable for Azure Virtual Machines deployment')
param enabledForDeployment bool = false

@description('Enable for Azure Resource Manager template deployment')
param enabledForTemplateDeployment bool = true

@description('Enable for Azure Disk Encryption')
param enabledForDiskEncryption bool = false

@description('Enable purge protection')
param enablePurgeProtection bool = true

@description('Soft delete retention days')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Enable RBAC authorization')
param enableRbacAuthorization bool = false

@description('Tags to apply to resources')
param tags object = {}

// Create the Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    tenantId: subscription().tenantId
    enablePurgeProtection: enablePurgeProtection ? true : null
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enableRbacAuthorization: enableRbacAuthorization
    sku: {
      name: skuName
      family: skuFamily
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Outputs
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri

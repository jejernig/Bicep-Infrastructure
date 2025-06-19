@description('The name of the Key Vault')
param name string

@description('The Azure region for the resource')
param location string

@description('Resource tags')
param tags object

@description('The SKU name of the Key Vault')
param skuName string = 'standard'

@description('Whether Azure Resource Manager is permitted to retrieve secrets from the Key Vault')
param enabledForTemplateDeployment bool = true

@description('Whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the Key Vault')
param enabledForDeployment bool = true

@description('Whether Azure Disk Encryption is permitted to retrieve secrets from the Key Vault and unwrap keys')
param enabledForDiskEncryption bool = true

@description('Whether soft delete is enabled for this Key Vault')
param enableSoftDelete bool = true

@description('The soft delete retention period in days')
param softDeleteRetentionInDays int = 90

@description('The default action when no rule matches')
param networkAclsDefaultAction string = 'Allow'

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    tenantId: subscription().tenantId
    accessPolicies: []
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: networkAclsDefaultAction
      bypass: 'AzureServices'
    }
  }
}

// Outputs
output id string = keyVault.id
output name string = keyVault.name
output uri string = keyVault.properties.vaultUri

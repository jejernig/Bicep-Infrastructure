@description('Name of the Key Vault')
param keyVaultName string

@description('Default action for network ACLs')
@allowed([
  'Allow'
  'Deny'
])
param defaultAction string = 'Allow'

@description('Bypass for network ACLs')
@allowed([
  'AzureServices'
  'None'
])
param bypass string = 'AzureServices'

@description('IP rules for network ACLs')
param ipRules array = []

@description('Virtual network rules for network ACLs')
param virtualNetworkRules array = []

@description('Private endpoint connections')
param privateEndpointConnections array = []

// Reference the Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Update network settings
resource networkSettings 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: keyVault.location
  properties: {
    // Preserve existing properties
    enabledForDeployment: keyVault.properties.enabledForDeployment
    enabledForDiskEncryption: keyVault.properties.enabledForDiskEncryption
    enabledForTemplateDeployment: keyVault.properties.enabledForTemplateDeployment
    enablePurgeProtection: keyVault.properties.enablePurgeProtection
    enableRbacAuthorization: keyVault.properties.enableRbacAuthorization
    enableSoftDelete: keyVault.properties.enableSoftDelete
    softDeleteRetentionInDays: keyVault.properties.softDeleteRetentionInDays
    tenantId: keyVault.properties.tenantId
    sku: keyVault.properties.sku
    accessPolicies: keyVault.properties.accessPolicies
    
    // Update network ACLs
    networkAcls: {
      bypass: bypass
      defaultAction: defaultAction
      ipRules: [for ipRule in ipRules: {
        value: ipRule
      }]
      virtualNetworkRules: [for vnetRule in virtualNetworkRules: {
        id: vnetRule
      }]
    }
  }
}

// Outputs
output networkAclsDefaultAction string = networkSettings.properties.networkAcls.defaultAction
output networkAclsBypass string = networkSettings.properties.networkAcls.bypass
output ipRulesCount int = length(ipRules)
output virtualNetworkRulesCount int = length(virtualNetworkRules)

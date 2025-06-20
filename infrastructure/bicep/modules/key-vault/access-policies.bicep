@description('Name of the Key Vault')
param keyVaultName string

@description('Array of access policies to configure')
param accessPolicies array = []

@description('Whether to replace all existing access policies')
param replaceExistingPolicies bool = false

// Reference the Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Configure access policies
resource accessPolicyResource 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: replaceExistingPolicies ? 'replace' : 'add'
  parent: keyVault
  properties: {
    accessPolicies: accessPolicies
  }
}

// Outputs
output accessPoliciesCount int = length(accessPolicies)

@description('The name of the Key Vault')
param keyVaultName string

@description('The object ID of the principal to give access to')
param principalId string

@description('The tenant ID of the principal')
param tenantId string = subscription().tenantId

@description('The permissions to keys to grant')
param keyPermissions array = [
  'Get'
  'List'
]

@description('The permissions to secrets to grant')
param secretPermissions array = [
  'Get'
  'List'
]

@description('The permissions to certificates to grant')
param certificatePermissions array = [
  'Get'
  'List'
]

// Reference to existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Key Vault Access Policy
resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: principalId
        permissions: {
          keys: keyPermissions
          secrets: secretPermissions
          certificates: certificatePermissions
        }
      }
    ]
  }
}

// Outputs
output keyVaultName string = keyVault.name

@description('Name of the Key Vault')
param keyVaultName string

@description('Object ID of the managed identity')
param objectId string

@description('Key permissions to grant')
param keyPermissions array = [
  'Get'
  'List'
]

@description('Secret permissions to grant')
param secretPermissions array = [
  'Get'
  'List'
]

@description('Certificate permissions to grant')
param certificatePermissions array = [
  'Get'
  'List'
]

@description('Storage permissions to grant')
param storagePermissions array = []

// Reference the Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Configure access policy for the managed identity
resource accessPolicyResource 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        objectId: objectId
        tenantId: subscription().tenantId
        permissions: {
          keys: keyPermissions
          secrets: secretPermissions
          certificates: certificatePermissions
          storage: storagePermissions
        }
      }
    ]
  }
}

// Outputs
output objectId string = objectId

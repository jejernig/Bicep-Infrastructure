@description('Name of the Key Vault')
param keyVaultName string

@description('Array of keys to create')
param keys array = []

// Reference the Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Create keys
resource keyVaultKeys 'Microsoft.KeyVault/vaults/keys@2022-07-01' = [for key in keys: {
  name: '${keyVaultName}/${key.name}'
  properties: {
    kty: contains(key, 'keyType') ? key.keyType : 'RSA'
    keySize: contains(key, 'keySize') ? key.keySize : 2048
    keyOps: contains(key, 'keyOps') ? key.keyOps : [
      'encrypt'
      'decrypt'
      'sign'
      'verify'
      'wrapKey'
      'unwrapKey'
    ]
    attributes: {
      enabled: contains(key, 'enabled') ? key.enabled : true
      exp: contains(key, 'expirationDate') ? dateTimeToEpoch(key.expirationDate) : null
      nbf: contains(key, 'activationDate') ? dateTimeToEpoch(key.activationDate) : null
    }
  }
}]

// Helper function to convert DateTime to epoch seconds
func dateTimeToEpoch(dateTime string) int {
  return dateTimeToUnixEpoch(dateTime) / 1000
}

// Outputs
output keysCount int = length(keys)
output keyNames array = [for (key, i) in keys: key.name]

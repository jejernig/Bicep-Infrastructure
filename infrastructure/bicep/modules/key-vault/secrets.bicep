@description('Name of the Key Vault')
param keyVaultName string

@description('Array of secrets to create')
param secrets array = []

@description('Enable secret versioning')
param enableSecretVersioning bool = true

@description('Default content type for secrets')
param defaultContentType string = 'text/plain'

// Reference the Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Create secrets
resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for secret in secrets: {
  name: '${keyVaultName}/${secret.name}'
  properties: {
    value: secret.value
    contentType: contains(secret, 'contentType') ? secret.contentType : defaultContentType
    attributes: {
      enabled: contains(secret, 'enabled') ? secret.enabled : true
      exp: contains(secret, 'expirationDate') ? dateTimeToEpoch(secret.expirationDate) : null
      nbf: contains(secret, 'activationDate') ? dateTimeToEpoch(secret.activationDate) : null
    }
  }
}]

// Helper function to convert DateTime to epoch seconds
func dateTimeToEpoch(dateTime string) int {
  return dateTimeToUnixEpoch(dateTime) / 1000
}

// Outputs
output secretsCount int = length(secrets)
output secretNames array = [for (secret, i) in secrets: secret.name]

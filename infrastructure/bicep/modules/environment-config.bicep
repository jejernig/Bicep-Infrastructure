@description('The environment name (dev, test, staging, prod)')
param environmentName string

@description('The Azure region for the resource')
param location string

@description('Resource tags')
param tags object

@description('The name of the Key Vault to store environment-specific secrets')
param keyVaultName string

@description('The name of the App Configuration service')
param appConfigName string = 'phantomline-appconfig-${environmentName}'

// App Configuration Service for environment-specific configuration
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: appConfigName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    encryption: {}
    disableLocalAuth: false
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false
  }
}

// Reference to existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Add App Configuration's managed identity to Key Vault access policies
module appConfigKeyVaultAccess './key-vault-access.bicep' = {
  name: 'appConfigKeyVaultAccess'
  params: {
    keyVaultName: keyVault.name
    principalId: appConfig.identity.principalId
    secretPermissions: [
      'Get'
      'List'
    ]
  }
}

// Environment-specific configuration values
var commonConfig = [
  {
    key: 'PhantomLine:Environment'
    value: environmentName
    contentType: 'text/plain'
  }
  {
    key: 'PhantomLine:KeyVaultUri'
    value: keyVault.properties.vaultUri
    contentType: 'text/plain'
  }
]

var environmentSpecificConfig = environmentName == 'prod' ? [
  {
    key: 'PhantomLine:LogLevel'
    value: 'Warning'
    contentType: 'text/plain'
  }
  {
    key: 'PhantomLine:UseRedisCache'
    value: 'true'
    contentType: 'text/plain'
  }
] : [
  {
    key: 'PhantomLine:LogLevel'
    value: 'Information'
    contentType: 'text/plain'
  }
  {
    key: 'PhantomLine:UseRedisCache'
    value: environmentName == 'staging' ? 'true' : 'false'
    contentType: 'text/plain'
  }
]

var allConfigs = concat(commonConfig, environmentSpecificConfig)

// Create configuration entries in App Configuration
resource configEntries 'Microsoft.AppConfiguration/configurationStores/keyValues@2023-03-01' = [for config in allConfigs: {
  parent: appConfig
  name: config.key
  properties: {
    value: config.value
    contentType: config.contentType
  }
}]

// Outputs
output appConfigName string = appConfig.name
output appConfigEndpoint string = appConfig.properties.endpoint
output appConfigPrincipalId string = appConfig.identity.principalId

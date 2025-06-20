@description('Configuration for the Key Vault module')
param config object

@description('Location for the resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Extract configuration values
var keyVaultName = config.name
var enabledForDeployment = contains(config, 'enabledForDeployment') ? config.enabledForDeployment : false
var enabledForTemplateDeployment = contains(config, 'enabledForTemplateDeployment') ? config.enabledForTemplateDeployment : true
var enabledForDiskEncryption = contains(config, 'enabledForDiskEncryption') ? config.enabledForDiskEncryption : false
var enablePurgeProtection = contains(config, 'enablePurgeProtection') ? config.enablePurgeProtection : true
var softDeleteRetentionInDays = contains(config, 'softDeleteRetentionInDays') ? config.softDeleteRetentionInDays : 90
var enableRbacAuthorization = contains(config, 'enableRbacAuthorization') ? config.enableRbacAuthorization : false
var skuName = contains(config, 'skuName') ? config.skuName : 'standard'
var skuFamily = contains(config, 'skuFamily') ? config.skuFamily : 'A'

// Network settings
var networkAcls = contains(config, 'networkAcls') ? config.networkAcls : {
  defaultAction: 'Allow'
  bypass: 'AzureServices'
  ipRules: []
  virtualNetworkRules: []
}

// Access policies
var accessPolicies = contains(config, 'accessPolicies') ? config.accessPolicies : []
var replaceExistingPolicies = contains(config, 'replaceExistingPolicies') ? config.replaceExistingPolicies : false

// Secrets, certificates, and keys
var secrets = contains(config, 'secrets') ? config.secrets : []
var certificates = contains(config, 'certificates') ? config.certificates : []
var keys = contains(config, 'keys') ? config.keys : []

// Private endpoint
var privateEndpoint = contains(config, 'privateEndpoint') ? config.privateEndpoint : null

// Deploy Key Vault
module keyVault './key-vault.bicep' = {
  name: 'keyVault-${keyVaultName}'
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: tags
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enablePurgeProtection: enablePurgeProtection
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enableRbacAuthorization: enableRbacAuthorization
    skuName: skuName
    skuFamily: skuFamily
  }
}

// Configure access policies if provided
module accessPoliciesModule './access-policies.bicep' = if (!empty(accessPolicies)) {
  name: 'accessPolicies-${keyVaultName}'
  params: {
    keyVaultName: keyVaultName
    accessPolicies: accessPolicies
    replaceExistingPolicies: replaceExistingPolicies
  }
  dependsOn: [
    keyVault
  ]
}

// Configure network settings if provided
module networkSettingsModule './network-settings.bicep' = if (networkAcls.defaultAction != 'Allow' || networkAcls.bypass != 'AzureServices' || !empty(networkAcls.ipRules) || !empty(networkAcls.virtualNetworkRules)) {
  name: 'networkSettings-${keyVaultName}'
  params: {
    keyVaultName: keyVaultName
    defaultAction: networkAcls.defaultAction
    bypass: networkAcls.bypass
    ipRules: networkAcls.ipRules
    virtualNetworkRules: networkAcls.virtualNetworkRules
  }
  dependsOn: [
    keyVault
    accessPoliciesModule
  ]
}

// Create secrets if provided
module secretsModule './secrets.bicep' = if (!empty(secrets)) {
  name: 'secrets-${keyVaultName}'
  params: {
    keyVaultName: keyVaultName
    secrets: secrets
  }
  dependsOn: [
    keyVault
    accessPoliciesModule
    networkSettingsModule
  ]
}

// Create certificates if provided
module certificatesModule './certificates.bicep' = if (!empty(certificates)) {
  name: 'certificates-${keyVaultName}'
  params: {
    keyVaultName: keyVaultName
    certificates: certificates
  }
  dependsOn: [
    keyVault
    accessPoliciesModule
    networkSettingsModule
  ]
}

// Create keys if provided
module keysModule './keys.bicep' = if (!empty(keys)) {
  name: 'keys-${keyVaultName}'
  params: {
    keyVaultName: keyVaultName
    keys: keys
  }
  dependsOn: [
    keyVault
    accessPoliciesModule
    networkSettingsModule
  ]
}

// Create private endpoint if provided
module privateEndpointModule './private-endpoint.bicep' = if (privateEndpoint != null) {
  name: 'privateEndpoint-${keyVaultName}'
  params: {
    keyVaultName: keyVaultName
    privateEndpointName: contains(privateEndpoint, 'name') ? privateEndpoint.name : '${keyVaultName}-pe'
    location: location
    subnetId: privateEndpoint.subnetId
    privateDnsZoneId: contains(privateEndpoint, 'privateDnsZoneId') ? privateEndpoint.privateDnsZoneId : ''
    tags: tags
  }
  dependsOn: [
    keyVault
    networkSettingsModule
  ]
}

// Outputs
output keyVaultId string = keyVault.outputs.keyVaultId
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri

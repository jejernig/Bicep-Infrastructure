@description('Configuration object for SQL Database module')
param config object

@description('Location for the resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Parse configuration
var sqlServerName = config.serverName
var sqlDatabaseName = config.databaseName
var administratorLogin = contains(config, 'administratorLogin') ? config.administratorLogin : ''
var administratorLoginPassword = contains(config, 'administratorLoginPassword') ? config.administratorLoginPassword : ''

// SQL Server configuration
var enableAzureADAdmin = contains(config, 'azureADAdmin') && !empty(config.azureADAdmin)
var aadAdministrator = enableAzureADAdmin ? config.azureADAdmin : {}
var azureADOnlyAuthentication = contains(config, 'azureADOnlyAuthentication') ? config.azureADOnlyAuthentication : false
var systemAssignedIdentity = contains(config, 'systemAssignedIdentity') ? config.systemAssignedIdentity : false
var userAssignedIdentities = contains(config, 'userAssignedIdentities') ? config.userAssignedIdentities : {}

// Database configuration
var databaseSku = contains(config, 'databaseSku') ? config.databaseSku : {
  name: 'Basic'
  tier: 'Basic'
  capacity: 5
}
var collation = contains(config, 'collation') ? config.collation : 'SQL_Latin1_General_CP1_CI_AS'
var maxSizeBytes = contains(config, 'maxSizeBytes') ? config.maxSizeBytes : 2147483648 // 2GB
var zoneRedundant = contains(config, 'zoneRedundant') ? config.zoneRedundant : false
var readScale = contains(config, 'readScale') ? config.readScale : 'Disabled'
var licenseType = contains(config, 'licenseType') ? config.licenseType : 'LicenseIncluded'
var highAvailabilityReplicaCount = contains(config, 'highAvailabilityReplicaCount') ? config.highAvailabilityReplicaCount : 0
var requestedBackupStorageRedundancy = contains(config, 'requestedBackupStorageRedundancy') ? config.requestedBackupStorageRedundancy : 'Geo'

// Firewall configuration
var allowAzureServices = contains(config, 'allowAzureServices') ? config.allowAzureServices : true
var firewallRules = contains(config, 'firewallRules') ? config.firewallRules : []
var virtualNetworkRules = contains(config, 'virtualNetworkRules') ? config.virtualNetworkRules : []

// Private endpoint configuration
var enablePrivateEndpoint = contains(config, 'privateEndpoint') && !empty(config.privateEndpoint)
var privateEndpointName = enablePrivateEndpoint ? contains(config.privateEndpoint, 'name') ? config.privateEndpoint.name : '${sqlServerName}-pe' : ''
var subnetId = enablePrivateEndpoint ? config.privateEndpoint.subnetId : ''
var privateDnsZoneId = enablePrivateEndpoint && contains(config.privateEndpoint, 'privateDnsZoneId') ? config.privateEndpoint.privateDnsZoneId : ''

// Security configuration
var enableAuditing = contains(config, 'auditing') && contains(config.auditing, 'enabled') ? config.auditing.enabled : false
var auditingConfig = contains(config, 'auditing') ? config.auditing : {}
var enableThreatProtection = contains(config, 'threatProtection') && contains(config.threatProtection, 'enabled') ? config.threatProtection.enabled : false
var threatProtectionConfig = contains(config, 'threatProtection') ? config.threatProtection : {}
var enableTDE = contains(config, 'transparentDataEncryption') && contains(config.transparentDataEncryption, 'enabled') ? config.transparentDataEncryption.enabled : true
var tdeConfig = contains(config, 'transparentDataEncryption') ? config.transparentDataEncryption : {}

// Backup configuration
var configureLongTermRetention = contains(config, 'backupPolicy') && contains(config.backupPolicy, 'longTermRetentionPolicy')
var configureShortTermRetention = contains(config, 'backupPolicy') && contains(config.backupPolicy, 'shortTermRetentionPolicy')
var longTermRetentionPolicy = configureLongTermRetention ? config.backupPolicy.longTermRetentionPolicy : {}
var shortTermRetentionPolicy = configureShortTermRetention ? config.backupPolicy.shortTermRetentionPolicy : {}

// Geo-replication configuration
var enableGeoReplication = contains(config, 'geoReplication') && !empty(config.geoReplication)
var geoReplicationConfig = enableGeoReplication ? config.geoReplication : {}

// Connection string configuration
var configureConnectionString = contains(config, 'connectionString') && !empty(config.connectionString)
var connectionStringConfig = configureConnectionString ? config.connectionString : {}
var keyVaultName = configureConnectionString && contains(connectionStringConfig, 'keyVaultName') ? connectionStringConfig.keyVaultName : ''
var connectionStringSecretName = configureConnectionString && contains(connectionStringConfig, 'secretName') ? connectionStringConfig.secretName : '${sqlServerName}-${sqlDatabaseName}-ConnectionString'
var useManagedIdentity = configureConnectionString && contains(connectionStringConfig, 'useManagedIdentity') ? connectionStringConfig.useManagedIdentity : false
var connectionStringType = configureConnectionString && contains(connectionStringConfig, 'type') ? connectionStringConfig.type : 'ADO.NET'
var outputConnectionString = configureConnectionString && contains(connectionStringConfig, 'outputConnectionString') ? connectionStringConfig.outputConnectionString : false

// Create SQL Server
module sqlServerModule 'sql-server.bicep' = {
  name: 'deploy-${sqlServerName}'
  params: {
    sqlServerName: sqlServerName
    location: location
    tags: tags
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

// Configure authentication options
module authenticationModule 'authentication-options.bicep' = {
  name: 'deploy-${sqlServerName}-auth'
  params: {
    sqlServerName: sqlServerName
    aadAdministrator: aadAdministrator
    azureADOnlyAuthentication: azureADOnlyAuthentication
    systemAssignedIdentity: systemAssignedIdentity
    userAssignedIdentities: userAssignedIdentities
  }
  dependsOn: [
    sqlServerModule
  ]
}

// Create SQL Database
module sqlDatabaseModule 'sql-database.bicep' = {
  name: 'deploy-${sqlDatabaseName}'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    location: location
    tags: tags
    sku: databaseSku
    collation: collation
    maxSizeBytes: maxSizeBytes
    zoneRedundant: zoneRedundant
    readScale: readScale
    licenseType: licenseType
    highAvailabilityReplicaCount: highAvailabilityReplicaCount
    requestedBackupStorageRedundancy: requestedBackupStorageRedundancy
  }
  dependsOn: [
    sqlServerModule
  ]
}

// Configure firewall rules
module firewallRulesModule 'firewall-rules.bicep' = {
  name: 'deploy-${sqlServerName}-firewall'
  params: {
    sqlServerName: sqlServerName
    allowAzureServices: allowAzureServices
    firewallRules: firewallRules
  }
  dependsOn: [
    sqlServerModule
  ]
}

// Configure virtual network rules
module virtualNetworkRulesModule 'virtual-network-rules.bicep' = if (!empty(virtualNetworkRules)) {
  name: 'deploy-${sqlServerName}-vnet-rules'
  params: {
    sqlServerName: sqlServerName
    virtualNetworkRules: virtualNetworkRules
  }
  dependsOn: [
    sqlServerModule
  ]
}

// Configure private endpoint
module privateEndpointModule 'private-endpoint.bicep' = if (enablePrivateEndpoint) {
  name: 'deploy-${sqlServerName}-private-endpoint'
  params: {
    sqlServerName: sqlServerName
    privateEndpointName: privateEndpointName
    location: location
    subnetId: subnetId
    privateDnsZoneId: privateDnsZoneId
    tags: tags
  }
  dependsOn: [
    sqlServerModule
  ]
}

// Configure database auditing
module auditingModule 'database-auditing.bicep' = if (enableAuditing) {
  name: 'deploy-${sqlDatabaseName}-auditing'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    enabled: enableAuditing
    retentionDays: contains(auditingConfig, 'retentionDays') ? auditingConfig.retentionDays : 0
    storageAccountId: contains(auditingConfig, 'storageAccountId') ? auditingConfig.storageAccountId : ''
    workspaceId: contains(auditingConfig, 'workspaceId') ? auditingConfig.workspaceId : ''
    eventHubAuthorizationRuleId: contains(auditingConfig, 'eventHubAuthorizationRuleId') ? auditingConfig.eventHubAuthorizationRuleId : ''
    eventHubName: contains(auditingConfig, 'eventHubName') ? auditingConfig.eventHubName : ''
  }
  dependsOn: [
    sqlDatabaseModule
  ]
}

// Configure threat protection
module threatProtectionModule 'threat-protection.bicep' = if (enableThreatProtection) {
  name: 'deploy-${sqlDatabaseName}-threat-protection'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    enabled: enableThreatProtection
    emailAddresses: contains(threatProtectionConfig, 'emailAddresses') ? threatProtectionConfig.emailAddresses : []
    emailAccountAdmins: contains(threatProtectionConfig, 'emailAccountAdmins') ? threatProtectionConfig.emailAccountAdmins : false
    storageAccountId: contains(threatProtectionConfig, 'storageAccountId') ? threatProtectionConfig.storageAccountId : ''
    retentionDays: contains(threatProtectionConfig, 'retentionDays') ? threatProtectionConfig.retentionDays : 0
    disabledAlerts: contains(threatProtectionConfig, 'disabledAlerts') ? threatProtectionConfig.disabledAlerts : []
  }
  dependsOn: [
    sqlDatabaseModule
  ]
}

// Configure transparent data encryption
module tdeModule 'transparent-data-encryption.bicep' = {
  name: 'deploy-${sqlDatabaseName}-tde'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    enabled: enableTDE
    keyType: contains(tdeConfig, 'keyType') ? tdeConfig.keyType : 'ServiceManaged'
    keyUri: contains(tdeConfig, 'keyUri') ? tdeConfig.keyUri : ''
  }
  dependsOn: [
    sqlDatabaseModule
  ]
}

// Configure backup policies
module backupPolicyModule 'backup-policy.bicep' = if (configureLongTermRetention || configureShortTermRetention) {
  name: 'deploy-${sqlDatabaseName}-backup-policy'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    longTermRetentionPolicy: longTermRetentionPolicy
    shortTermRetentionPolicy: shortTermRetentionPolicy
  }
  dependsOn: [
    sqlDatabaseModule
  ]
}

// Configure geo-replication
module geoReplicationModule 'geo-replication.bicep' = if (enableGeoReplication) {
  name: 'deploy-${sqlDatabaseName}-geo-replication'
  params: {
    primaryServerName: sqlServerName
    primaryDatabaseName: sqlDatabaseName
    secondaryServerName: geoReplicationConfig.secondaryServerName
    secondaryDatabaseName: contains(geoReplicationConfig, 'secondaryDatabaseName') ? geoReplicationConfig.secondaryDatabaseName : sqlDatabaseName
    secondaryLocation: geoReplicationConfig.secondaryLocation
    secondarySku: contains(geoReplicationConfig, 'secondarySku') ? geoReplicationConfig.secondarySku : databaseSku
    readOnlyEndpointFailoverPolicy: contains(geoReplicationConfig, 'readOnlyEndpointFailoverPolicy') ? geoReplicationConfig.readOnlyEndpointFailoverPolicy : true
    tags: tags
  }
  dependsOn: [
    sqlDatabaseModule
  ]
}

// Configure connection string management
module connectionStringModule 'connection-string-management.bicep' = if (configureConnectionString) {
  name: 'deploy-${sqlDatabaseName}-connection-string'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    keyVaultName: keyVaultName
    connectionStringSecretName: connectionStringSecretName
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    useManagedIdentity: useManagedIdentity
    connectionStringType: connectionStringType
    outputConnectionString: outputConnectionString
  }
  dependsOn: [
    sqlDatabaseModule
    authenticationModule
  ]
}

// Outputs
output sqlServerId string = sqlServerModule.outputs.sqlServerId
output sqlServerName string = sqlServerModule.outputs.sqlServerName
output sqlServerFqdn string = sqlServerModule.outputs.sqlServerFqdn
output sqlDatabaseId string = sqlDatabaseModule.outputs.sqlDatabaseId
output sqlDatabaseName string = sqlDatabaseModule.outputs.sqlDatabaseName
output identityType string = authenticationModule.outputs.identityType
output systemAssignedIdentityPrincipalId string = authenticationModule.outputs.systemAssignedIdentityPrincipalId
output connectionString string = configureConnectionString && outputConnectionString ? connectionStringModule.outputs.connectionString : ''
output connectionStringSecretUri string = configureConnectionString && !empty(keyVaultName) ? connectionStringModule.outputs.connectionStringSecretUri : ''

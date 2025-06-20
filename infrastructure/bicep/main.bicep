@description('Configuration object that drives the deployment')
param config object

// Extract metadata from config
var metadata = config.metadata
var projectName = metadata.projectName
var environment = metadata.environment
var location = contains(metadata, 'location') ? metadata.location : resourceGroup().location

// Extract tags from config
var tags = config.tags

// Extract feature toggles from config
var featureToggles = config.featureToggles
var enableApiManagement = contains(featureToggles, 'enableApiManagement') ? featureToggles.enableApiManagement : true
var enableFunctionApp = contains(featureToggles, 'enableFunctionApp') ? featureToggles.enableFunctionApp : true
var enableSignalR = contains(featureToggles, 'enableSignalR') ? featureToggles.enableSignalR : true
var enableRedisCache = contains(featureToggles, 'enableRedisCache') ? featureToggles.enableRedisCache : false
var enableKeyVault = contains(featureToggles, 'enableKeyVault') ? featureToggles.enableKeyVault : true
var enableOpenAI = contains(featureToggles, 'enableOpenAI') ? featureToggles.enableOpenAI : true
var enableContainerRegistry = contains(featureToggles, 'enableContainerRegistry') ? featureToggles.enableContainerRegistry : true
var enableStorageAccount = contains(featureToggles, 'enableStorageAccount') ? featureToggles.enableStorageAccount : true
var enableContainerInstance = contains(featureToggles, 'enableContainerInstance') ? featureToggles.enableContainerInstance : true
var enableSqlDatabase = contains(featureToggles, 'enableSqlDatabase') ? featureToggles.enableSqlDatabase : true
var enableCdn = contains(featureToggles, 'enableCdn') ? featureToggles.enableCdn : false
var enableFrontDoor = contains(featureToggles, 'enableFrontDoor') ? featureToggles.enableFrontDoor : false
var enableAspire = contains(featureToggles, 'enableAspire') ? featureToggles.enableAspire : false

// Extract module configurations
var moduleConfigs = contains(config, 'moduleConfigurations') ? config.moduleConfigurations : {}

// Extract Bicep settings
var bicepSettings = contains(config, 'bicepSettings') ? config.bicepSettings : {}

@secure()
param sqlAdminPassword string

// Resource naming helper function
@description('Creates a standardized resource name')
func resourceName(resourceType string, suffix string) string {
  var resourceAbbreviations = {
    apiManagement: 'apim'
    functionApp: 'func'
    signalR: 'signalr'
    redisCache: 'redis'
    keyVault: 'kv'
    openAI: 'openai'
    containerRegistry: 'acr'
    appConfig: 'appconfig'
    storageAccount: 'sa'
    containerInstance: 'ci'
    logAnalyticsWorkspace: 'law'
    sqlServer: 'sql'
    sqlDatabase: 'db'
  }
  
  // Handle special cases for storage accounts and container registries (no hyphens allowed)
  if (resourceType == 'storageAccount' || resourceType == 'containerRegistry') {
    return '${projectName}${resourceAbbreviations[resourceType]}${environment}${empty(suffix) ? '' : suffix}'
  }
  
  return '${projectName}-${resourceAbbreviations[resourceType]}-${environment}${empty(suffix) ? '' : '-${suffix}'}'
}

// Resource name variables
var resourceNames = {
  apiManagement: resourceName('apiManagement', '')
  functionApp: resourceName('functionApp', '')
  signalR: resourceName('signalR', '')
  redisCache: resourceName('redisCache', '')
  keyVault: resourceName('keyVault', '')
  openAI: resourceName('openAI', '')
  containerRegistry: resourceName('containerRegistry', '')
  appConfig: resourceName('appConfig', '')
  storageAccount: resourceName('storageAccount', '')
  mcpContainerGroup: resourceName('containerInstance', 'mcp-db')
  logAnalyticsWorkspace: resourceName('logAnalyticsWorkspace', '')
  sqlServer: resourceName('sqlServer', '')
  sqlDatabase: resourceName('sqlDatabase', '')
  cdnProfile: '${projectName}-cdn-${environment}'
  frontDoor: '${projectName}-fd-${environment}'
  containerAppEnvironment: '${projectName}-cae-${environment}'
}

// Deploy API Management
module apiManagement './modules/api-management.bicep' = if (enableApiManagement) {
  name: 'apiManagementDeploy'
  params: {
    name: resourceNames.apiManagement
    location: location
    tags: tags
    skuName: contains(moduleConfigs, 'apiManagement') && contains(moduleConfigs.apiManagement, 'sku') ? moduleConfigs.apiManagement.sku : 'Developer'
    skuCapacity: contains(moduleConfigs, 'apiManagement') && contains(moduleConfigs.apiManagement, 'capacity') ? moduleConfigs.apiManagement.capacity : 1
    publisherEmail: contains(moduleConfigs, 'apiManagement') && contains(moduleConfigs.apiManagement, 'publisherEmail') ? moduleConfigs.apiManagement.publisherEmail : 'admin@phantomline.io'
    publisherName: contains(moduleConfigs, 'apiManagement') && contains(moduleConfigs.apiManagement, 'publisherName') ? moduleConfigs.apiManagement.publisherName : 'PhantomLine'
    functionAppName: enableFunctionApp ? functionApp.outputs.functionAppName : ''
  }
  dependsOn: enableFunctionApp ? [
    functionApp
  ] : []
}

// Deploy Azure Functions
module functionApp './modules/function-app.bicep' = if (enableFunctionApp) {
  name: 'functionAppDeploy'
  params: {
    name: resourceNames.functionApp
    location: location
    tags: tags
    runtime: contains(moduleConfigs, 'functionApp') && contains(moduleConfigs.functionApp, 'runtime') ? moduleConfigs.functionApp.runtime : 'dotnet'
    sku: contains(moduleConfigs, 'functionApp') && contains(moduleConfigs.functionApp, 'sku') ? moduleConfigs.functionApp.sku : 'Y1'
    appSettings: contains(moduleConfigs, 'functionApp') && contains(moduleConfigs.functionApp, 'appSettings') ? moduleConfigs.functionApp.appSettings : [
      {
        name: 'FUNCTIONS_WORKER_RUNTIME'
        value: 'dotnet'
      }
      {
        name: 'FUNCTIONS_EXTENSION_VERSION'
        value: '~4'
      }
    ]
    storageAccountName: enableStorageAccount ? mcpStorageAccount.outputs.storageAccountName : ''
    storageAccountKey: enableStorageAccount ? mcpStorageAccount.outputs.storageAccountKey : ''
  }
  dependsOn: [
    mcpStorageAccount
  ]
}

// Deploy SignalR Service
module signalR './modules/signalr.bicep' = if (enableSignalR) {
  name: 'signalRDeploy'
  params: {
    name: resourceNames.signalR
    location: location
    tags: tags
    skuName: contains(moduleConfigs, 'signalR') && contains(moduleConfigs.signalR, 'sku') ? moduleConfigs.signalR.sku : 'Standard_S1'
    skuCapacity: contains(moduleConfigs, 'signalR') && contains(moduleConfigs.signalR, 'capacity') ? moduleConfigs.signalR.capacity : 1
    functionAppId: enableFunctionApp ? functionApp.outputs.functionAppId : ''
  }
  dependsOn: enableFunctionApp ? [
    functionApp
  ] : []
}

// Deploy Redis Cache
module redisCache './modules/redis/main.bicep' = if (enableRedisCache) {
  name: 'redisCacheDeploy'
  params: {
    redisCacheName: resourceNames.redisCache
    location: location
    tags: tags
    sku: contains(moduleConfigs, 'redisCache') && contains(moduleConfigs.redisCache, 'sku') ? moduleConfigs.redisCache.sku : 'Basic'
    family: contains(moduleConfigs, 'redisCache') && contains(moduleConfigs.redisCache, 'family') ? moduleConfigs.redisCache.family : 'C'
    capacity: contains(moduleConfigs, 'redisCache') && contains(moduleConfigs.redisCache, 'capacity') ? moduleConfigs.redisCache.capacity : 0
    enableNonSslPort: contains(moduleConfigs, 'redisCache') && contains(moduleConfigs.redisCache, 'enableNonSslPort') ? moduleConfigs.redisCache.enableNonSslPort : false
  }
}

// Deploy Key Vault
module keyVault './modules/key-vault.bicep' = if (enableKeyVault) {
  name: 'keyVaultDeploy'
  params: {
    name: resourceNames.keyVault
    location: location
    tags: tags
    skuName: contains(moduleConfigs, 'keyVault') && contains(moduleConfigs.keyVault, 'sku') ? moduleConfigs.keyVault.sku : 'standard'
    enabledForDeployment: contains(moduleConfigs, 'keyVault') && contains(moduleConfigs.keyVault, 'enabledForDeployment') ? moduleConfigs.keyVault.enabledForDeployment : false
    enabledForTemplateDeployment: contains(moduleConfigs, 'keyVault') && contains(moduleConfigs.keyVault, 'enabledForTemplateDeployment') ? moduleConfigs.keyVault.enabledForTemplateDeployment : true
    enabledForDiskEncryption: contains(moduleConfigs, 'keyVault') && contains(moduleConfigs.keyVault, 'enabledForDiskEncryption') ? moduleConfigs.keyVault.enabledForDiskEncryption : false
    enablePurgeProtection: contains(moduleConfigs, 'keyVault') && contains(moduleConfigs.keyVault, 'enablePurgeProtection') ? moduleConfigs.keyVault.enablePurgeProtection : true
    softDeleteRetentionInDays: contains(moduleConfigs, 'keyVault') && contains(moduleConfigs.keyVault, 'softDeleteRetentionInDays') ? moduleConfigs.keyVault.softDeleteRetentionInDays : 90
  }
}

// Deploy OpenAI Service
module openAI './modules/openai.bicep' = if (enableOpenAI) {
  name: 'openAIDeploy'
  params: {
    name: resourceNames.openAI
    location: location
    tags: tags
    sku: contains(moduleConfigs, 'openAI') && contains(moduleConfigs.openAI, 'sku') ? moduleConfigs.openAI.sku : 'S0'
    deployments: contains(moduleConfigs, 'openAI') && contains(moduleConfigs.openAI, 'deployments') ? moduleConfigs.openAI.deployments : [
      {
        name: 'gpt-35'
        model: 'gpt-35-turbo'
        version: '0613'
        capacity: 1
      }
    ]
  }
}

// Deploy Container Registry
module containerRegistry './modules/container-registry.bicep' = if (enableContainerRegistry) {
  name: 'containerRegistryDeploy'
  params: {
    name: resourceNames.containerRegistry
    location: location
    tags: tags
    sku: contains(moduleConfigs, 'containerRegistry') && contains(moduleConfigs.containerRegistry, 'sku') ? moduleConfigs.containerRegistry.sku : 'Standard'
    adminUserEnabled: contains(moduleConfigs, 'containerRegistry') && contains(moduleConfigs.containerRegistry, 'adminUserEnabled') ? moduleConfigs.containerRegistry.adminUserEnabled : true
  }
}

// Deploy Storage Account for MCP Graph Database persistent storage
module mcpStorageAccount './modules/storage-account.bicep' = if (enableStorageAccount) {
  name: 'mcpStorageAccountDeploy'
  params: {
    storageAccountName: resourceNames.storageAccount
    location: location
    tags: tags
    storageSku: contains(moduleConfigs, 'storageAccount') && contains(moduleConfigs.storageAccount, 'sku') ? moduleConfigs.storageAccount.sku : 'Standard_LRS'
    kind: contains(moduleConfigs, 'storageAccount') && contains(moduleConfigs.storageAccount, 'kind') ? moduleConfigs.storageAccount.kind : 'StorageV2'
    accessTier: contains(moduleConfigs, 'storageAccount') && contains(moduleConfigs.storageAccount, 'accessTier') ? moduleConfigs.storageAccount.accessTier : 'Hot'
    fileShares: contains(moduleConfigs, 'storageAccount') && contains(moduleConfigs.storageAccount, 'fileShares') ? moduleConfigs.storageAccount.fileShares : [
      {
        name: 'mcp-graph-data'
        quota: 100
      }
      {
        name: 'mcp-graph-logs'
        quota: 50
      }
      {
        name: 'mcp-graph-import'
        quota: 50
      }
    ]
  }
}

// Deploy MCP Graph Database Container Instance
module mcpContainerInstance './modules/container-instance.bicep' = if (enableContainerInstance && enableStorageAccount && enableContainerRegistry) {
  name: 'mcpContainerInstanceDeploy'
  params: {
    containerGroupName: resourceNames.mcpContainerGroup
    location: location
    tags: tags
    image: contains(moduleConfigs, 'containerInstance') && contains(moduleConfigs.containerInstance, 'image') ? moduleConfigs.containerInstance.image : '${resourceNames.containerRegistry}.azurecr.io/phantomline-mcp-database:latest'
    port: contains(moduleConfigs, 'containerInstance') && contains(moduleConfigs.containerInstance, 'port') ? moduleConfigs.containerInstance.port : 7474
    cpuCores: contains(moduleConfigs, 'containerInstance') && contains(moduleConfigs.containerInstance, 'cpuCores') ? moduleConfigs.containerInstance.cpuCores : 2
    memoryInGb: contains(moduleConfigs, 'containerInstance') && contains(moduleConfigs.containerInstance, 'memoryInGb') ? moduleConfigs.containerInstance.memoryInGb : 4
    acrLoginServer: '${resourceNames.containerRegistry}.azurecr.io'
    acrUsername: containerRegistry.outputs.adminUsername
    acrPassword: containerRegistry.outputs.adminPassword
    environmentVariables: contains(moduleConfigs, 'containerInstance') && contains(moduleConfigs.containerInstance, 'environmentVariables') ? moduleConfigs.containerInstance.environmentVariables : [
      {
        name: 'NEO4J_AUTH'
        secureValue: 'neo4j/${keyVault.outputs.keyVaultName}'
      }
      {
        name: 'NEO4J_dbms_memory_heap_initial__size'
        value: '1G'
      }
      {
        name: 'NEO4J_dbms_memory_heap_max__size'
        value: '2G'
      }
      {
        name: 'NEO4J_dbms_memory_pagecache_size'
        value: '1G'
      }
      {
        name: 'ALERT_WEBHOOK_URL'
        secureValue: '@Microsoft.KeyVault(SecretUri=https://${keyVault.outputs.keyVaultName}.vault.azure.net/secrets/AlertWebhookUrl/)'
      }
      {
        name: 'ALERT_EMAIL'
        secureValue: '@Microsoft.KeyVault(SecretUri=https://${keyVault.outputs.keyVaultName}.vault.azure.net/secrets/AlertEmail/)'
      }
      {
        name: 'ENVIRONMENT'
        value: environment
      }
    ]
    volumeMounts: contains(moduleConfigs, 'containerInstance') && contains(moduleConfigs.containerInstance, 'volumeMounts') ? moduleConfigs.containerInstance.volumeMounts : [
      {
        name: 'mcp-graph-data'
        mountPath: '/data'
        shareName: 'mcp-graph-data'
        storageAccountName: mcpStorageAccount.outputs.storageAccountName
        storageAccountKey: mcpStorageAccount.outputs.storageAccountKey
      }
      {
        name: 'mcp-graph-logs'
        mountPath: '/logs'
        shareName: 'mcp-graph-logs'
        storageAccountName: mcpStorageAccount.outputs.storageAccountName
        storageAccountKey: mcpStorageAccount.outputs.storageAccountKey
      }
      {
        name: 'mcp-graph-import'
        mountPath: '/var/lib/neo4j/import'
        shareName: 'mcp-graph-import'
        storageAccountName: mcpStorageAccount.outputs.storageAccountName
        storageAccountKey: mcpStorageAccount.outputs.storageAccountKey
      }
    ]
    managedIdentityId: enableFunctionApp ? functionApp.outputs.functionAppIdentityId : ''
  }
  dependsOn: [
    containerRegistry
    mcpStorageAccount
    keyVault
    functionApp
  ]
}

// Deploy Container Monitoring for MCP Graph Database
module containerMonitoring './modules/container-monitoring.bicep' = if (enableContainerInstance) {
  name: 'containerMonitoringDeploy'
  params: {
    workspaceName: resourceNames.logAnalyticsWorkspace
    location: location
    tags: tags
    containerGroupId: mcpContainerInstance.outputs.containerGroupId
    alertEmailAddresses: '@Microsoft.KeyVault(SecretUri=https://${keyVault.outputs.keyVaultName}.vault.azure.net/secrets/AlertEmail/)'
    enableDiagnostics: true
    retentionInDays: 30
  }
  dependsOn: [
    mcpContainerInstance
    keyVault
  ]
}

// Deploy Environment Configuration with App Configuration
module environmentConfig './modules/environment-config.bicep' = if (enableKeyVault) {
  name: 'environmentConfigDeploy'
  params: {
    environmentName: environment
    location: location
    tags: tags
    keyVaultName: keyVault.outputs.name
    appConfigName: resourceNames.appConfig
  }
  dependsOn: [
    keyVault
  ]
}

// Grant Function App access to Key Vault
module functionAppKeyVaultAccess './modules/key-vault-access.bicep' = if (enableKeyVault && enableFunctionApp) {
  name: 'functionAppKeyVaultAccess'
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: functionApp.outputs.principalId
    secretPermissions: [
      'Get'
      'List'
    ]
  }
  dependsOn: [
    keyVault
    functionApp
  ]
}

// Store important connection strings in Key Vault
resource signalRConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${resourceNames.keyVault}/SignalRConnectionString'
  properties: {
    value: 'Endpoint=https://${signalR.outputs.hostName};AccessKey=${listKeys(resourceId('Microsoft.SignalR/signalR', resourceNames.signalR), '2022-02-01').primaryKey};Version=1.0;'
  }
  dependsOn: [
    keyVault
    signalR
  ]
}

resource redisConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${resourceNames.keyVault}/RedisConnectionString'
  properties: {
    value: '${resourceNames.redisCache}.redis.cache.windows.net:${redisCache.outputs.sslPort},password=${listKeys(resourceId('Microsoft.Cache/redis', resourceNames.redisCache), '2022-06-01').primaryKey},ssl=True,abortConnect=False'
  }
  dependsOn: [
    keyVault
    redisCache
  ]
}

// Deploy SQL Database
module sqlDatabase './modules/sql-database.bicep' = if (enableSqlDatabase) {
  name: 'sqlDatabaseDeploy'
  params: {
    sqlServerName: resourceNames.sqlServer
    sqlDatabaseName: resourceNames.sqlDatabase
    location: location
    tags: tags
    administratorLogin: contains(moduleConfigs, 'sqlDatabase') && contains(moduleConfigs.sqlDatabase, 'administratorLogin') ? moduleConfigs.sqlDatabase.administratorLogin : 'phantomline_admin'
    administratorLoginPassword: sqlAdminPassword
    allowAzureIPs: contains(moduleConfigs, 'sqlDatabase') && contains(moduleConfigs.sqlDatabase, 'allowAzureIPs') ? moduleConfigs.sqlDatabase.allowAzureIPs : true
    firewallRules: contains(moduleConfigs, 'sqlDatabase') && contains(moduleConfigs.sqlDatabase, 'firewallRules') ? moduleConfigs.sqlDatabase.firewallRules : []
    databaseSku: contains(moduleConfigs, 'sqlDatabase') && contains(moduleConfigs.sqlDatabase, 'databaseSku') ? moduleConfigs.sqlDatabase.databaseSku : {
      name: 'Basic'
      tier: 'Basic'
    }
    keyVaultName: enableKeyVault ? keyVault.outputs.keyVaultName : ''
  }
  dependsOn: enableKeyVault ? [
    keyVault
  ] : []
}

// Store SQL connection string in Key Vault
module sqlConnectionString './modules/key-vault-secret.bicep' = if (enableKeyVault && enableSqlDatabase) {
  name: 'sqlConnectionStringDeploy'
  params: {
    keyVaultName: keyVault.outputs.name
    secretName: 'SqlConnectionString'
    secretValue: 'Server=tcp:${resourceNames.sqlServer}.database.windows.net,1433;Initial Catalog=${resourceNames.sqlDatabase};Persist Security Info=False;User ID=${sqlDatabase.outputs.administratorLogin};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
  dependsOn: [
    keyVault
    sqlDatabase
  ]
}

// Outputs

// Deployment metadata outputs
output projectName string = metadata.projectName
output environment string = metadata.environment
output location string = location
output deploymentTimestamp string = utcNow('yyyy-MM-dd-HH-mm-ss')

// Resource outputs - only exposed if the corresponding feature is enabled
output apiManagementName string = enableApiManagement ? apiManagement.outputs.name : ''
output apiManagementGatewayUrl string = enableApiManagement ? apiManagement.outputs.gatewayUrl : ''

output functionAppName string = enableFunctionApp ? functionApp.outputs.name : ''
output functionAppHostName string = enableFunctionApp ? functionApp.outputs.hostName : ''
output functionAppDefaultHostName string = enableFunctionApp ? functionApp.outputs.defaultHostName : ''

output signalRName string = enableSignalR ? signalR.outputs.name : ''
output signalRConnectionString string = enableSignalR ? signalR.outputs.connectionString : ''

// Deploy CDN Profile and Endpoint
module cdnProfile './modules/cdn/main.bicep' = if (enableCdn) {
  name: 'cdnDeploy'
  params: {
    cdnProfileName: resourceNames.cdnProfile
    location: location
    tags: union(tags, {
      displayName: 'CDN Profile'
    })
    sku: contains(moduleConfigs, 'cdn') && contains(moduleConfigs.cdn, 'sku') ? moduleConfigs.cdn.sku : 'Standard_Microsoft'
    originUrl: contains(moduleConfigs, 'cdn') && contains(moduleConfigs.cdn, 'originUrl') ? moduleConfigs.cdn.originUrl : ''
    originHostHeader: contains(moduleConfigs, 'cdn') && contains(moduleConfigs.cdn, 'originHostHeader') ? moduleConfigs.cdn.originHostHeader : ''
    isHttpAllowed: contains(moduleConfigs, 'cdn') && contains(moduleConfigs.cdn, 'isHttpAllowed') ? moduleConfigs.cdn.isHttpAllowed : false
    isHttpsAllowed: contains(moduleConfigs, 'cdn') && contains(moduleConfigs.cdn, 'isHttpsAllowed') ? moduleConfigs.cdn.isHttpsAllowed : true
    queryStringCachingBehavior: contains(moduleConfigs, 'cdn') && contains(moduleConfigs.cdn, 'queryStringCachingBehavior') ? moduleConfigs.cdn.queryStringCachingBehavior : 'IgnoreQueryString'
    optimizationType: contains(moduleConfigs, 'cdn') && contains(moduleConfigs.cdn, 'optimizationType') ? moduleConfigs.cdn.optimizationType : 'GeneralWebDelivery'
  }
}

// Deploy Front Door
module frontDoor './modules/front-door/main.bicep' = if (enableFrontDoor) {
  name: 'frontDoorDeploy'
  params: {
    frontDoorName: resourceNames.frontDoor
    location: 'global'
    tags: union(tags, {
      displayName: 'Azure Front Door'
    })
    backendHostName: contains(moduleConfigs, 'frontDoor') && contains(moduleConfigs.frontDoor, 'backendHostName') ? moduleConfigs.frontDoor.backendHostName : ''
    backendHostHeader: contains(moduleConfigs, 'frontDoor') && contains(moduleConfigs.frontDoor, 'backendHostHeader') ? moduleConfigs.frontDoor.backendHostHeader : ''
    backendHttpPort: contains(moduleConfigs, 'frontDoor') && contains(moduleConfigs.frontDoor, 'backendHttpPort') ? moduleConfigs.frontDoor.backendHttpPort : 80
    backendHttpsPort: contains(moduleConfigs, 'frontDoor') && contains(moduleConfigs.frontDoor, 'backendHttpsPort') ? moduleConfigs.frontDoor.backendHttpsPort : 443
    path: contains(moduleConfigs, 'frontDoor') && contains(moduleConfigs.frontDoor, 'path') ? moduleConfigs.frontDoor.path : '/*'
    acceptedProtocols: contains(moduleConfigs, 'frontDoor') && contains(moduleConfigs.frontDoor, 'acceptedProtocols') ? moduleConfigs.frontDoor.acceptedProtocols : 'HttpsOnly'
    routeType: contains(moduleConfigs, 'frontDoor') && contains(moduleConfigs.frontDoor, 'routeType') ? moduleConfigs.frontDoor.routeType : 'Forwarding'
    enableCaching: contains(moduleConfigs, 'frontDoor') && contains(moduleConfigs.frontDoor, 'enableCaching') ? moduleConfigs.frontDoor.enableCaching : false
    customDomainName: contains(moduleConfigs, 'frontDoor') && contains(moduleConfigs.frontDoor, 'customDomainName') ? moduleConfigs.frontDoor.customDomainName : ''
    customDomainHostName: contains(moduleConfigs, 'frontDoor') && contains(moduleConfigs.frontDoor, 'customDomainHostName') ? moduleConfigs.frontDoor.customDomainHostName : ''
    keyVaultCertificateId: contains(moduleConfigs, 'frontDoor') && contains(moduleConfigs.frontDoor, 'keyVaultCertificateId') ? moduleConfigs.frontDoor.keyVaultCertificateId : ''
  }
}

// CDN Outputs
output cdnProfileName string = enableCdn ? cdnProfile.outputs.name : ''
output cdnEndpointHostName string = enableCdn ? cdnProfile.outputs.endpointHostName : ''

// Front Door Outputs
output frontDoorName string = enableFrontDoor ? frontDoor.outputs.name : ''
output frontDoorEndpoint string = enableFrontDoor ? frontDoor.outputs.frontendEndpointHostName : ''
output frontDoorCustomDomain string = enableFrontDoor ? frontDoor.outputs.customDomainHostName : ''

output redisCacheName string = enableRedisCache ? redisCache.outputs.name : ''
output redisCacheHostName string = enableRedisCache ? redisCache.outputs.hostName : ''
output redisCachePort int = enableRedisCache ? redisCache.outputs.sslPort : 0
output redisCacheConnectionString string = enableRedisCache ? redisCache.outputs.connectionString : ''
output redisCachePrimaryKey string = enableRedisCache ? redisCache.outputs.primaryKey : ''
output redisCacheSecondaryKey string = enableRedisCache ? redisCache.outputs.secondaryKey : ''

output keyVaultName string = enableKeyVault ? keyVault.outputs.name : ''
output keyVaultUri string = enableKeyVault ? keyVault.outputs.vaultUri : ''

output openAIName string = enableOpenAI ? openAI.outputs.name : ''
output openAIEndpoint string = enableOpenAI ? openAI.outputs.endpoint : ''

output containerRegistryName string = enableContainerRegistry ? containerRegistry.outputs.name : ''
output containerRegistryLoginServer string = enableContainerRegistry ? containerRegistry.outputs.loginServer : ''

output mcpContainerGroupName string = (enableContainerInstance && enableStorageAccount && enableContainerRegistry) ? mcpContainerInstance.outputs.containerGroupName : ''
output mcpContainerGroupFqdn string = (enableContainerInstance && enableStorageAccount && enableContainerRegistry) ? mcpContainerInstance.outputs.containerGroupFqdn : ''

output mcpStorageAccountName string = enableStorageAccount ? mcpStorageAccount.outputs.storageAccountName : ''
output mcpStorageAccountConnectionString string = enableStorageAccount ? mcpStorageAccount.outputs.connectionString : ''

output logAnalyticsWorkspaceName string = enableContainerInstance ? containerMonitoring.outputs.workspaceName : ''
output logAnalyticsWorkspaceId string = enableContainerInstance ? containerMonitoring.outputs.workspaceId : ''

output sqlServerName string = enableSqlDatabase ? sqlDatabase.outputs.sqlServerName : ''
output sqlDatabaseName string = enableSqlDatabase ? sqlDatabase.outputs.sqlDatabaseName : ''
output sqlConnectionString string = (enableSqlDatabase && enableKeyVault) ? 'Stored in KeyVault Secret: SqlConnectionString' : ''

output appConfigName string = enableKeyVault ? environmentConfig.outputs.appConfigName : ''
output appConfigEndpoint string = enableKeyVault ? environmentConfig.outputs.appConfigEndpoint : ''

// ============================================
// Output values for all resources
// ============================================

// API Management Outputs
output apiManagementName string = enableApiManagement ? apiManagement.outputs.name : ''
output apiManagementGatewayUrl string = enableApiManagement ? apiManagement.outputs.gatewayUrl : ''
output apiManagementPortalUrl string = enableApiManagement ? apiManagement.outputs.portalUrl : ''
output apiManagementManagementApiUrl string = enableApiManagement ? apiManagement.outputs.managementApiUrl : ''
output apiManagementScmUrl string = enableApiManagement ? apiManagement.outputs.scmUrl : ''

// Function App Outputs
output functionAppName string = enableFunctionApp ? functionApp.outputs.functionAppName : ''
output functionAppHostName string = enableFunctionApp ? functionApp.outputs.functionAppHostName : ''
output functionAppDefaultHostName string = enableFunctionApp ? functionApp.outputs.defaultHostName : ''
output functionAppOutboundIps string = enableFunctionApp ? functionApp.outputs.outboundIps : ''
output functionAppConnectionString string = enableFunctionApp ? functionApp.outputs.connectionString : ''

// SignalR Outputs
output signalRName string = enableSignalR ? signalR.outputs.name : ''
output signalRConnectionString string = enableSignalR ? signalR.outputs.connectionString : ''
output signalRExternalIp string = enableSignalR ? signalR.outputs.externalIp : ''
output signalRHostName string = enableSignalR ? signalR.outputs.hostName : ''
output signalRPublicPort int = enableSignalR ? signalR.outputs.publicPort : 0
output signalRServerPort int = enableSignalR ? signalR.outputs.serverPort : 0
output signalRVersion string = enableSignalR ? signalR.outputs.version : ''

// Redis Cache Outputs
output redisCacheName string = enableRedisCache ? redisCache.outputs.name : ''
output redisCacheHostName string = enableRedisCache ? redisCache.outputs.hostName : ''
output redisCachePort int = enableRedisCache ? redisCache.outputs.sslPort : 0
output redisCacheNonSslPort int = enableRedisCache ? redisCache.outputs.nonSslPort : 0
output redisCacheConnectionString string = enableRedisCache ? redisCache.outputs.connectionString : ''
output redisCachePrimaryKey string = enableRedisCache ? redisCache.outputs.primaryKey : ''
output redisCacheSecondaryKey string = enableRedisCache ? redisCache.outputs.secondaryKey : ''
output redisCacheSslPort int = enableRedisCache ? redisCache.outputs.sslPort : 0
output redisCacheTlsVersion string = enableRedisCache ? redisCache.outputs.minimumTlsVersion : ''

// Key Vault Outputs
output keyVaultName string = enableKeyVault ? keyVault.outputs.name : ''
output keyVaultUri string = enableKeyVault ? keyVault.outputs.vaultUri : ''
output keyVaultTenantId string = enableKeyVault ? keyVault.outputs.tenantId : ''
output keyVaultEnabledForDeployment bool = enableKeyVault ? keyVault.outputs.enabledForDeployment : false
output keyVaultEnabledForTemplateDeployment bool = enableKeyVault ? keyVault.outputs.enabledForTemplateDeployment : false
output keyVaultEnabledForDiskEncryption bool = enableKeyVault ? keyVault.outputs.enabledForDiskEncryption : false

// OpenAI Outputs
output openAIName string = enableOpenAI ? openAI.outputs.name : ''
output openAIEndpoint string = enableOpenAI ? openAI.outputs.endpoint : ''
output openAIPrivateEndpointConnections array = enableOpenAI ? openAI.outputs.privateEndpointConnections : []
output openAIPublicNetworkAccess string = enableOpenAI ? openAI.outputs.publicNetworkAccess : ''

// Container Registry Outputs
output containerRegistryName string = enableContainerRegistry ? containerRegistry.outputs.name : ''
output containerRegistryLoginServer string = enableContainerRegistry ? containerRegistry.outputs.loginServer : ''
output containerRegistryAdminUserEnabled bool = enableContainerRegistry ? containerRegistry.outputs.adminUserEnabled : false
output containerRegistryIdentityPrincipalId string = enableContainerRegistry ? containerRegistry.outputs.identityPrincipalId : ''
output containerRegistrySkuName string = enableContainerRegistry ? containerRegistry.outputs.skuName : ''
output containerRegistrySkuTier string = enableContainerRegistry ? containerRegistry.outputs.skuTier : ''

// Storage Account Outputs
output storageAccountName string = enableStorageAccount ? mcpStorageAccount.outputs.storageAccountName : ''
output storageAccountKey string = enableStorageAccount ? mcpStorageAccount.outputs.storageAccountKey : ''
output storageAccountConnectionString string = enableStorageAccount ? mcpStorageAccount.outputs.storageAccountConnectionString : ''
output storageAccountPrimaryBlobEndpoint string = enableStorageAccount ? mcpStorageAccount.outputs.primaryBlobEndpoint : ''
output storageAccountPrimaryFileEndpoint string = enableStorageAccount ? mcpStorageAccount.outputs.primaryFileEndpoint : ''
output storageAccountPrimaryQueueEndpoint string = enableStorageAccount ? mcpStorageAccount.outputs.primaryQueueEndpoint : ''
output storageAccountPrimaryTableEndpoint string = enableStorageAccount ? mcpStorageAccount.outputs.primaryTableEndpoint : ''
output storageAccountPrimaryAccessKey string = enableStorageAccount ? mcpStorageAccount.outputs.primaryAccessKey : ''

// Container Instance Outputs
output containerInstanceName string = enableContainerInstance ? containerInstance.outputs.name : ''
output containerInstanceFqdn string = enableContainerInstance ? containerInstance.outputs.fqdn : ''
output containerInstanceIpAddress string = enableContainerInstance ? containerInstance.outputs.ipAddress : ''
output containerInstanceOsType string = enableContainerInstance ? containerInstance.outputs.osType : ''
output containerInstanceProvisioningState string = enableContainerInstance ? containerInstance.outputs.provisioningState : ''

// SQL Database Outputs
output sqlServerName string = enableSqlDatabase ? sqlServer.outputs.name : ''
output sqlDatabaseName string = enableSqlDatabase ? sqlDatabase.outputs.name : ''
output sqlServerFullyQualifiedDomainName string = enableSqlDatabase ? sqlServer.outputs.fullyQualifiedDomainName : ''
output sqlConnectionString string = enableSqlDatabase ? sqlDatabase.outputs.connectionString : ''
output sqlServerVersion string = enableSqlDatabase ? sqlServer.outputs.version : ''
output sqlDatabaseCollation string = enableSqlDatabase ? sqlDatabase.outputs.collation : ''
output sqlDatabaseStatus string = enableSqlDatabase ? sqlDatabase.outputs.status : ''

// CDN Outputs
output cdnProfileName string = enableCdn ? cdnProfile.outputs.name : ''
output cdnEndpointName string = enableCdn ? cdnProfile.outputs.endpointName : ''
output cdnEndpointHostName string = enableCdn ? cdnProfile.outputs.endpointHostName : ''
output cdnProvisioningState string = enableCdn ? cdnProfile.outputs.provisioningState : ''
output cdnResourceState string = enableCdn ? cdnProfile.outputs.resourceState : ''

// Front Door Outputs
output frontDoorName string = enableFrontDoor ? frontDoor.outputs.name : ''
output frontDoorEndpoint string = enableFrontDoor ? frontDoor.outputs.frontendEndpointHostName : ''
output frontDoorCustomDomain string = enableFrontDoor ? frontDoor.outputs.customDomainHostName : ''
output frontDoorCname string = enableFrontDoor ? '${frontDoor.outputs.name}.azurefd.net' : ''
output frontDoorProvisioningState string = enableFrontDoor ? frontDoor.outputs.provisioningState : ''
output frontDoorResourceState string = enableFrontDoor ? frontDoor.outputs.resourceState : ''

// Combined Outputs for Common Scenarios
output webAppEndpoints object = {
  functionApp: enableFunctionApp ? functionApp.outputs.defaultHostName : ''
  cdn: enableCdn ? cdnProfile.outputs.endpointHostName : ''
  frontDoor: enableFrontDoor ? '${frontDoor.outputs.name}.azurefd.net' : ''
  customDomain: enableFrontDoor && !empty(frontDoor.outputs.customDomainHostName) ? frontDoor.outputs.customDomainHostName : ''
}

output connectionStrings object = {
  redis: enableRedisCache ? redisCache.outputs.connectionString : ''
  sql: enableSqlDatabase ? sqlDatabase.outputs.connectionString : ''
  storage: enableStorageAccount ? mcpStorageAccount.outputs.storageAccountConnectionString : ''
  signalR: enableSignalR ? signalR.outputs.connectionString : ''
}

// Deploy .NET Aspire resources
module aspire './modules/aspire/main.bicep' = if (enableAspire) {
  name: 'aspireDeployment'
  params: {
    name: resourceNames.containerAppEnvironment
    location: location
    tags: union(tags, {
      displayName: 'Aspire Environment'
      environment: environment
    })
    containerAppEnvironment: contains(moduleConfigs, 'aspire') && contains(moduleConfigs.aspire, 'containerAppEnvironment') ? moduleConfigs.aspire.containerAppEnvironment : {}
    containerApps: contains(moduleConfigs, 'aspire') && contains(moduleConfigs.aspire, 'containerApps') ? moduleConfigs.aspire.containerApps : []
  }
  dependsOn: [
    // Add dependencies if needed, e.g., container registry, key vault
  ]
}

output resourceIds object = {
  functionApp: enableFunctionApp ? functionApp.outputs.id : ''
  appServicePlan: enableFunctionApp ? functionApp.outputs.appServicePlanId : ''
  storageAccount: enableStorageAccount ? mcpStorageAccount.outputs.id : ''
  keyVault: enableKeyVault ? keyVault.outputs.id : ''
  redis: enableRedisCache ? redisCache.outputs.id : ''
  sqlServer: enableSqlDatabase ? sqlServer.outputs.id : ''
  sqlDatabase: enableSqlDatabase ? sqlDatabase.outputs.id : ''
  cdn: enableCdn ? cdnProfile.outputs.id : ''
  frontDoor: enableFrontDoor ? frontDoor.outputs.id : ''
}

// Output the enabled status of all optional modules
output enabledModules object = {
  apiManagement: enableApiManagement
  functionApp: enableFunctionApp
  signalR: enableSignalR
  redisCache: enableRedisCache
  keyVault: enableKeyVault
  openAI: enableOpenAI
  containerRegistry: enableContainerRegistry
  storageAccount: enableStorageAccount
  containerInstance: enableContainerInstance
  sqlDatabase: enableSqlDatabase
  cdn: enableCdn
  frontDoor: enableFrontDoor
}

@description('The environment name (dev, test, staging, prod)')
param environmentName string = 'dev'

@description('The Azure region for all resources')
param location string = resourceGroup().location

@description('The base name for all resources')
param baseName string = 'phantomline'

@description('Tags for all resources')
param tags object = {
  environment: environmentName
  project: 'PhantomLine'
}

// Resource name variables
var resourceNames = {
  apiManagement: '${baseName}-apim-${environmentName}'
  functionApp: '${baseName}-func-${environmentName}'
  signalR: '${baseName}-signalr-${environmentName}'
  redisCache: '${baseName}-redis-${environmentName}'
  keyVault: '${baseName}-kv-${environmentName}'
  openAI: '${baseName}-openai-${environmentName}'
  containerRegistry: '${baseName}acr${environmentName}'
  appConfig: '${baseName}-appconfig-${environmentName}'
  storageAccount: '${baseName}sa${environmentName}'
  mcpContainerGroup: '${baseName}-mcp-db-${environmentName}'
  logAnalyticsWorkspace: '${baseName}-law-${environmentName}'
  sqlServer: '${baseName}-sql-${environmentName}'
  sqlDatabase: '${baseName}-db-${environmentName}'
}

// Deploy API Management
module apiManagement './modules/api-management.bicep' = {
  name: 'apiManagementDeploy'
  params: {
    name: resourceNames.apiManagement
    location: location
    tags: tags
  }
}

// Deploy Azure Functions
module functionApp './modules/function-app.bicep' = {
  name: 'functionAppDeploy'
  params: {
    name: resourceNames.functionApp
    location: location
    tags: tags
  }
}

// Deploy SignalR Service
module signalR './modules/signalr.bicep' = {
  name: 'signalRDeploy'
  params: {
    name: resourceNames.signalR
    location: location
    tags: tags
  }
}

// Deploy Redis Cache
module redisCache './modules/redis-cache.bicep' = {
  name: 'redisCacheDeploy'
  params: {
    name: resourceNames.redisCache
    location: location
    tags: tags
  }
}

// Deploy Key Vault
module keyVault './modules/key-vault.bicep' = {
  name: 'keyVaultDeploy'
  params: {
    name: resourceNames.keyVault
    location: location
    tags: tags
  }
}

// Deploy OpenAI Service
module openAI './modules/openai.bicep' = {
  name: 'openAIDeploy'
  params: {
    name: resourceNames.openAI
    location: location
    tags: tags
  }
}

// Deploy Container Registry
module containerRegistry './modules/container-registry.bicep' = {
  name: 'containerRegistryDeploy'
  params: {
    name: resourceNames.containerRegistry
    location: location
    tags: tags
  }
}

// Deploy Storage Account for MCP Graph Database persistent storage
module mcpStorageAccount './modules/storage-account.bicep' = {
  name: 'mcpStorageAccountDeploy'
  params: {
    storageAccountName: resourceNames.storageAccount
    location: location
    tags: tags
    storageSku: 'Standard_LRS'
    fileShares: [
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
module mcpContainerInstance './modules/container-instance.bicep' = {
  name: 'mcpContainerInstanceDeploy'
  params: {
    containerGroupName: resourceNames.mcpContainerGroup
    location: location
    tags: tags
    image: '${resourceNames.containerRegistry}.azurecr.io/phantomline-mcp-database:latest'
    port: 7474
    cpuCores: 2
    memoryInGb: 4
    acrLoginServer: '${resourceNames.containerRegistry}.azurecr.io'
    acrUsername: containerRegistry.outputs.adminUsername
    acrPassword: containerRegistry.outputs.adminPassword
    environmentVariables: [
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
        value: environmentName
      }
    ]
    volumeMounts: [
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
    managedIdentityId: functionApp.outputs.functionAppIdentityId
  }
}

// Deploy Container Monitoring for MCP Graph Database
module containerMonitoring './modules/container-monitoring.bicep' = {
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
}

// Deploy Environment Configuration with App Configuration
module environmentConfig './modules/environment-config.bicep' = {
  name: 'environmentConfigDeploy'
  params: {
    environmentName: environmentName
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
module functionAppKeyVaultAccess './modules/key-vault-access.bicep' = {
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
@secure()
param sqlAdminPassword string

module sqlDatabase './modules/sql-database.bicep' = {
  name: 'sqlDatabaseDeploy'
  params: {
    sqlServerName: resourceNames.sqlServer
    sqlDatabaseName: resourceNames.sqlDatabase
    location: location
    tags: tags
    administratorLogin: 'phantomline_admin'
    administratorLoginPassword: sqlAdminPassword
  }
}

// Store SQL connection string in Key Vault
resource sqlConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${resourceNames.keyVault}/SqlConnectionString'
  properties: {
    value: 'Server=tcp:${resourceNames.sqlServer}.database.windows.net,1433;Initial Catalog=${resourceNames.sqlDatabase};Persist Security Info=False;User ID=phantomline_admin;Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
  dependsOn: [
    keyVault
    sqlDatabase
  ]
}

// Outputs
output apiManagementName string = apiManagement.outputs.name
output functionAppName string = functionApp.outputs.name
output signalRName string = signalR.outputs.name
output redisCacheName string = redisCache.outputs.name
output keyVaultName string = keyVault.outputs.name
output openAIName string = openAI.outputs.name
output containerRegistryName string = containerRegistry.outputs.name
output mcpContainerGroupName string = mcpContainerInstance.outputs.containerGroupFqdn
output mcpStorageAccountName string = mcpStorageAccount.outputs.storageAccountName
output logAnalyticsWorkspaceName string = containerMonitoring.outputs.workspaceName
output appConfigName string = environmentConfig.outputs.appConfigName
output appConfigEndpoint string = environmentConfig.outputs.appConfigEndpoint
output sqlServerName string = sqlDatabase.outputs.sqlServerName
output sqlDatabaseName string = sqlDatabase.outputs.sqlDatabaseName

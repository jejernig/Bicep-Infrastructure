@description('Name of the Function App')
param functionAppName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Runtime stack for the Function App')
param runtime string = 'dotnet'

@description('Runtime version')
param runtimeVersion string = '6'

@description('Function App SKU')
@allowed([
  'Y1'    // Consumption
  'EP1'   // Premium
  'EP2'   // Premium
  'EP3'   // Premium
  'B1'    // Basic
  'B2'    // Basic
  'B3'    // Basic
  'S1'    // Standard
  'S2'    // Standard
  'S3'    // Standard
  'P1v2'  // PremiumV2
  'P2v2'  // PremiumV2
  'P3v2'  // PremiumV2
  'P1v3'  // PremiumV3
  'P2v3'  // PremiumV3
  'P3v3'  // PremiumV3
])
param sku string = 'Y1'

@description('OS type (Windows or Linux)')
@allowed([
  'Windows'
  'Linux'
])
param osType string = 'Windows'

@description('Number of instances')
param capacity int = 0

@description('Enable zone redundancy')
param zoneRedundant bool = false

@description('Enable autoscale')
param enableAutoscale bool = false

@description('Minimum instance count for autoscale')
param minInstanceCount int = 1

@description('Maximum instance count for autoscale')
param maxInstanceCount int = 10

@description('Default instance count for autoscale')
param defaultInstanceCount int = 1

@description('Storage account name')
param storageAccountName string = ''

@description('Storage account SKU')
param storageAccountSku string = 'Standard_LRS'

@description('Storage account kind')
param storageAccountKind string = 'StorageV2'

@description('Enable Application Insights')
param enableApplicationInsights bool = true

@description('Application Insights name')
param applicationInsightsName string = ''

@description('Application Insights type')
param applicationType string = 'web'

@description('Application Insights retention in days')
param retentionInDays int = 90

@description('Array of app settings')
param appSettings array = []

@description('Array of connection strings')
param connectionStrings array = []

@description('Enable system-assigned managed identity')
param systemAssignedIdentity bool = false

@description('User-assigned managed identities to assign to the Function App')
param userAssignedIdentities object = {}

@description('Role assignments to create for the Function App identity')
param roleAssignments array = []

@description('Tags to apply to resources')
param tags object = {}

// Generate names if not provided
var generatedStorageAccountName = '${replace(toLower(functionAppName), '-', '')}sa'
var actualStorageAccountName = empty(storageAccountName) ? length(generatedStorageAccountName) > 24 ? substring(generatedStorageAccountName, 0, 24) : generatedStorageAccountName : storageAccountName
var actualApplicationInsightsName = empty(applicationInsightsName) ? '${functionAppName}-insights' : applicationInsightsName
var hostingPlanName = '${functionAppName}-plan'

// Deploy the storage account
module storageAccountModule './storage-account.bicep' = {
  name: 'storageAccount-${functionAppName}'
  params: {
    storageAccountName: actualStorageAccountName
    location: location
    sku: storageAccountSku
    kind: storageAccountKind
    tags: tags
  }
}

// Deploy Application Insights if enabled
module appInsightsModule './app-insights.bicep' = if (enableApplicationInsights) {
  name: 'appInsights-${functionAppName}'
  params: {
    appInsightsName: actualApplicationInsightsName
    location: location
    applicationType: applicationType
    retentionInDays: retentionInDays
    tags: tags
  }
}

// Deploy the hosting plan
module hostingPlanModule './hosting-plan.bicep' = {
  name: 'hostingPlan-${functionAppName}'
  params: {
    hostingPlanName: hostingPlanName
    location: location
    sku: sku
    osType: osType
    capacity: capacity
    zoneRedundant: zoneRedundant
    enableAutoscale: enableAutoscale
    minInstanceCount: minInstanceCount
    maxInstanceCount: maxInstanceCount
    defaultInstanceCount: defaultInstanceCount
    tags: tags
  }
}

// Deploy the Function App
module functionAppModule './function-app.bicep' = {
  name: 'functionApp-${functionAppName}'
  params: {
    functionAppName: functionAppName
    location: location
    runtime: runtime
    runtimeVersion: runtimeVersion
    sku: sku
    osType: osType
    hostingPlanId: hostingPlanModule.outputs.hostingPlanId
    storageAccountName: storageAccountModule.outputs.storageAccountName
    appInsightsInstrumentationKey: enableApplicationInsights ? appInsightsModule.outputs.instrumentationKey : ''
    appInsightsConnectionString: enableApplicationInsights ? appInsightsModule.outputs.connectionString : ''
    appSettings: appSettings
    connectionStrings: connectionStrings
    systemAssignedIdentity: systemAssignedIdentity
    userAssignedIdentities: userAssignedIdentities
    tags: tags
  }
  dependsOn: [
    storageAccountModule
    hostingPlanModule
    appInsightsModule
  ]
}

// Configure identity management and role assignments
module identityManagement '../app-service/identity-management.bicep' = if (systemAssignedIdentity || !empty(userAssignedIdentities)) {
  name: 'identityManagement-${functionAppName}'
  params: {
    appServiceName: functionAppName
    systemAssignedIdentity: systemAssignedIdentity
    userAssignedIdentities: userAssignedIdentities
    roleAssignments: roleAssignments
  }
  dependsOn: [
    functionAppModule
  ]
}

// Outputs
output functionAppId string = functionAppModule.outputs.functionAppId
output functionAppName string = functionAppModule.outputs.functionAppName
output defaultHostName string = functionAppModule.outputs.defaultHostName
output principalId string = systemAssignedIdentity ? functionAppModule.outputs.principalId : ''
output storageAccountId string = storageAccountModule.outputs.storageAccountId
output storageAccountName string = storageAccountModule.outputs.storageAccountName
output hostingPlanId string = hostingPlanModule.outputs.hostingPlanId
output hostingPlanName string = hostingPlanModule.outputs.hostingPlanName
output applicationInsightsId string = enableApplicationInsights ? appInsightsModule.outputs.appInsightsId : ''
output applicationInsightsName string = enableApplicationInsights ? appInsightsModule.outputs.appInsightsName : ''

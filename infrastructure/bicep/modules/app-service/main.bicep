@description('Name of the App Service')
param appServiceName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('SKU for the App Service Plan')
param sku string = 'B1'

@description('Runtime stack for the App Service')
param runtimeStack string = 'dotnet:6'

@description('Array of app settings')
param appSettings array = []

@description('Array of connection strings')
param connectionStrings array = []

@description('Tags to apply to resources')
param tags object = {}

@description('Enable system-assigned managed identity')
param systemAssignedIdentity bool = false

@description('User-assigned managed identities to assign to the App Service')
param userAssignedIdentities object = {}

@description('Role assignments to create for the App Service identity')
param roleAssignments array = []

@description('Enable diagnostic settings')
param enableDiagnostics bool = false

@description('Resource ID of the Log Analytics workspace for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Resource ID of the Storage Account for diagnostics')
param diagnosticsStorageAccountId string = ''

@description('Resource ID of the Event Hub for diagnostics')
param eventHubAuthorizationRuleId string = ''

@description('Resource ID of the Event Hub Namespace for diagnostics')
param eventHubNamespaceId string = ''

@description('Log categories to enable for diagnostics')
param diagnosticLogCategories array = [
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceAuditLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
]

@description('Retention days for diagnostic logs')
param diagnosticLogsRetentionInDays int = 30

@description('Enable Application Insights integration')
param enableApplicationInsights bool = false

@description('Name of the Application Insights instance')
param applicationInsightsName string = ''

@description('Array of deployment slots to create')
param deploymentSlots array = []

@description('Settings that should be sticky between slot swaps')
param stickySettings object = {
  appSettingNames: []
  connectionStringNames: []
  azureStorageConfigNames: []
}

@description('Traffic routing settings for deployment slots')
param slotTrafficSettings array = []

@description('Number of pre-warmed instances for the App Service')
param preWarmedCount int = 0

// Deploy the App Service
module appService './app-service.bicep' = {
  name: 'appService-${appServiceName}'
  params: {
    appServiceName: appServiceName
    location: location
    sku: sku
    runtimeStack: runtimeStack
    appSettings: appSettings
    tags: tags
    systemAssignedIdentity: systemAssignedIdentity
    userAssignedIdentities: userAssignedIdentities
    enableDiagnostics: enableDiagnostics
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    diagnosticsStorageAccountId: diagnosticsStorageAccountId
    eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
    eventHubNamespaceId: eventHubNamespaceId
    diagnosticLogCategories: diagnosticLogCategories
    diagnosticLogsRetentionInDays: diagnosticLogsRetentionInDays
  }
}

// Deploy connection strings if specified
module appConfiguration './app-configuration.bicep' = if (!empty(connectionStrings)) {
  name: 'appConfiguration-${appServiceName}'
  params: {
    appServiceName: appServiceName
    connectionStrings: connectionStrings
  }
  dependsOn: [
    appService
  ]
}

// Deploy deployment slots if specified
module slots './deployment-slots.bicep' = if (!empty(deploymentSlots)) {
  name: 'deploymentSlots-${appServiceName}'
  params: {
    appServiceName: appServiceName
    location: location
    slots: deploymentSlots
    tags: tags
  }
  dependsOn: [
    appService
  ]
}

// Configure slot sticky settings if specified
resource slotConfigNames 'Microsoft.Web/sites/config@2022-03-01' = if (!empty(deploymentSlots) && (!empty(stickySettings.appSettingNames) || !empty(stickySettings.connectionStringNames) || !empty(stickySettings.azureStorageConfigNames))) {
  name: '${appServiceName}/slotConfigNames'
  properties: {
    appSettingNames: stickySettings.appSettingNames
    connectionStringNames: stickySettings.connectionStringNames
    azureStorageConfigNames: stickySettings.azureStorageConfigNames
  }
  dependsOn: [
    appService
    slots
  ]
}

// Configure slot traffic routing if specified
module slotTraffic './slot-traffic.bicep' = if (!empty(slotTrafficSettings)) {
  name: 'slotTraffic-${appServiceName}'
  params: {
    appServiceName: appServiceName
    slotTrafficSettings: slotTrafficSettings
  }
  dependsOn: [
    appService
    slots
  ]
}

// Configure pre-warmed instances if specified
module preWarmed './slot-prewarmed.bicep' = if (preWarmedCount > 0) {
  name: 'preWarmed-${appServiceName}'
  params: {
    appServiceName: appServiceName
    preWarmedCount: preWarmedCount
  }
  dependsOn: [
    appService
  ]
}

// Configure identity management
module identityManagement './identity-management.bicep' = if (systemAssignedIdentity || !empty(userAssignedIdentities)) {
  name: 'identityManagement-${appServiceName}'
  params: {
    appServiceName: appServiceName
    systemAssignedIdentity: systemAssignedIdentity
    userAssignedIdentities: userAssignedIdentities
    roleAssignments: roleAssignments
  }
  dependsOn: [
    appService
  ]
}

// Configure advanced diagnostics
module advancedDiagnostics './advanced-diagnostics.bicep' = if (enableDiagnostics || enableApplicationInsights) {
  name: 'advancedDiagnostics-${appServiceName}'
  params: {
    appServiceName: appServiceName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    diagnosticsStorageAccountId: diagnosticsStorageAccountId
    eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
    eventHubNamespaceId: eventHubNamespaceId
    diagnosticLogCategories: diagnosticLogCategories
    diagnosticLogsRetentionInDays: diagnosticLogsRetentionInDays
    enableApplicationInsights: enableApplicationInsights
    applicationInsightsName: applicationInsightsName
    location: location
    tags: tags
  }
  dependsOn: [
    appService
  ]
}

// Outputs
output appServiceId string = appService.outputs.appServiceId
output appServiceName string = appService.outputs.appServiceName
output appServicePlanId string = appService.outputs.appServicePlanId
output appServicePlanName string = appService.outputs.appServicePlanName
output defaultHostName string = appService.outputs.defaultHostName
output principalId string = systemAssignedIdentity ? identityManagement.outputs.principalId : ''
output slotNames array = !empty(deploymentSlots) ? slots.outputs.slotNames : []
output applicationInsightsId string = enableApplicationInsights ? advancedDiagnostics.outputs.applicationInsightsId : ''
output applicationInsightsName string = enableApplicationInsights ? advancedDiagnostics.outputs.applicationInsightsName : ''
output applicationInsightsInstrumentationKey string = enableApplicationInsights ? advancedDiagnostics.outputs.applicationInsightsInstrumentationKey : ''
output applicationInsightsConnectionString string = enableApplicationInsights ? advancedDiagnostics.outputs.applicationInsightsConnectionString : ''

@description('The configuration object from bicep.config.json')
param config object

@description('Location for the resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Extract App Service configuration from the config object
var appServiceConfig = contains(config, 'moduleConfigurations') && contains(config.moduleConfigurations, 'appService') ? config.moduleConfigurations.appService : {}

// Extract project name and environment from metadata
var metadata = contains(config, 'metadata') ? config.metadata : {}
var projectName = contains(metadata, 'projectName') ? metadata.projectName : 'default'
var environment = contains(metadata, 'environment') ? metadata.environment : 'dev'

// Generate App Service name if not provided
var appServiceName = contains(appServiceConfig, 'name') ? appServiceConfig.name : '${projectName}-${environment}-app'

// Extract App Service settings
var sku = contains(appServiceConfig, 'sku') ? appServiceConfig.sku : 'B1'
var runtimeStack = contains(appServiceConfig, 'runtimeStack') ? appServiceConfig.runtimeStack : 'DOTNETCORE|6.0'
var systemAssignedIdentity = contains(appServiceConfig, 'systemAssignedIdentity') ? appServiceConfig.systemAssignedIdentity : false
var userAssignedIdentities = contains(appServiceConfig, 'userAssignedIdentities') ? appServiceConfig.userAssignedIdentities : {}
var appSettings = contains(appServiceConfig, 'appSettings') ? appServiceConfig.appSettings : []
var connectionStrings = contains(appServiceConfig, 'connectionStrings') ? appServiceConfig.connectionStrings : []

// Extract diagnostic settings
var diagnosticsConfig = contains(appServiceConfig, 'diagnostics') ? appServiceConfig.diagnostics : {}
var enableDiagnostics = contains(diagnosticsConfig, 'enabled') ? diagnosticsConfig.enabled : false
var logAnalyticsWorkspaceId = contains(diagnosticsConfig, 'logAnalyticsWorkspaceId') ? diagnosticsConfig.logAnalyticsWorkspaceId : ''
var diagnosticsStorageAccountId = contains(diagnosticsConfig, 'diagnosticsStorageAccountId') ? diagnosticsConfig.diagnosticsStorageAccountId : ''
var eventHubAuthorizationRuleId = contains(diagnosticsConfig, 'eventHubAuthorizationRuleId') ? diagnosticsConfig.eventHubAuthorizationRuleId : ''
var eventHubNamespaceId = contains(diagnosticsConfig, 'eventHubNamespaceId') ? diagnosticsConfig.eventHubNamespaceId : ''
var diagnosticLogCategories = contains(diagnosticsConfig, 'logCategories') ? diagnosticsConfig.logCategories : [
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceAuditLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
]
var diagnosticLogsRetentionInDays = contains(diagnosticsConfig, 'retentionDays') ? diagnosticsConfig.retentionDays : 30

// Extract deployment slots configuration
var deploymentSlots = contains(appServiceConfig, 'deploymentSlots') ? appServiceConfig.deploymentSlots : []
var stickySettings = contains(appServiceConfig, 'stickySettings') ? appServiceConfig.stickySettings : {
  appSettingNames: []
  connectionStringNames: []
  azureStorageConfigNames: []
}

// Deploy the App Service using the main module
module appService './main.bicep' = {
  name: 'appService-${appServiceName}'
  params: {
    appServiceName: appServiceName
    location: location
    sku: sku
    runtimeStack: runtimeStack
    appSettings: appSettings
    connectionStrings: connectionStrings
    tags: union(tags, contains(config, 'tags') ? config.tags : {})
    systemAssignedIdentity: systemAssignedIdentity
    userAssignedIdentities: userAssignedIdentities
    enableDiagnostics: enableDiagnostics
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    diagnosticsStorageAccountId: diagnosticsStorageAccountId
    eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
    eventHubNamespaceId: eventHubNamespaceId
    diagnosticLogCategories: diagnosticLogCategories
    diagnosticLogsRetentionInDays: diagnosticLogsRetentionInDays
    deploymentSlots: deploymentSlots
    stickySettings: stickySettings
  }
}

// Outputs
output appServiceId string = appService.outputs.appServiceId
output appServiceName string = appService.outputs.appServiceName
output appServicePlanId string = appService.outputs.appServicePlanId
output appServicePlanName string = appService.outputs.appServicePlanName
output defaultHostName string = appService.outputs.defaultHostName
output principalId string = appService.outputs.principalId
output slotNames array = appService.outputs.slotNames

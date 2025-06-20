@description('Operational mode for API Management: "shared" uses an existing instance, "dedicated" creates a new one')
param apimMode string = 'shared'

@description('Resource ID of the shared APIM instance (required when operationalMode is "shared")')
param sharedApimResourceId string = ''

@description('Project name used for namespacing and resource naming')
param projectName string

@description('Environment name (dev, test, prod)')
param environment string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('SKU for the API Management service (used only in dedicated mode)')
param apimSku string = 'Developer'

@description('SKU capacity for the API Management service (used only in dedicated mode)')
param apimCapacity int = 1

@description('Publisher email for the API Management service (used only in dedicated mode)')
param publisherEmail string = ''

@description('Publisher name for the API Management service (used only in dedicated mode)')
param publisherName string = ''

@description('Array of API configurations to register')
param apis array = []

@description('Global policy configuration')
param globalPolicy object = {}

@description('Policy configuration for the project')
param policyConfig object = {}

@description('Array of policy templates to create')
param policyTemplates array = []

@description('Array of named values to create')
param namedValues array = []

@description('Array of subscription configurations')
param subscriptions array = []

@description('Subscription approval workflow configuration')
param approvalWorkflow object = {}

@description('Usage quotas and rate limiting configuration')
param quotas array = []

@description('Usage tracking configuration')
param usageTracking object = {}

@description('Subscription lifecycle configuration')
param lifecycleConfig object = {}

@description('Subscription notification configuration')
param notificationConfig object = {}

// Validate required parameters based on mode
var sharedModeSelected = operationalMode == 'shared'
var dedicatedModeSelected = operationalMode == 'dedicated'

// Validation
resource sharedApimValidation 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (sharedModeSelected && empty(sharedApimResourceId)) {
  name: 'sharedApimValidation'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.30.0'
    retentionInterval: 'P1D'
    scriptContent: 'echo "Error: sharedApimResourceId is required when apimMode is set to shared" && exit 1'
  }
}

// Reference existing APIM in shared mode
resource sharedApim 'Microsoft.ApiManagement/service@2021-08-01' existing = if (sharedModeSelected) {
  name: split(sharedApimResourceId, '/')[8]
  scope: resourceGroup(split(sharedApimResourceId, '/')[4])
}

// Create new APIM in dedicated mode
resource dedicatedApim 'Microsoft.ApiManagement/service@2021-08-01' = if (dedicatedModeSelected) {
  name: '${projectName}-apim'
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: skuCapacity
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

// Get the APIM name based on mode
var apimName = sharedModeSelected ? sharedApim.name : dedicatedApim.name
var apimResourceGroup = sharedModeSelected ? split(sharedApimResourceId, '/')[4] : resourceGroup().name

// Apply global policies if specified
module globalPolicies 'global-policies.bicep' = if (!empty(globalPolicy)) {
  name: 'globalPolicies'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    policyContent: contains(globalPolicy, 'value') ? globalPolicy.value : ''
    policyFormat: contains(globalPolicy, 'format') ? globalPolicy.format : 'xml'
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
  ]
}

// Create named values
module namedValuesDeployment 'named-values.bicep' = if (!empty(namedValues)) {
  name: 'namedValuesDeployment'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    namedValues: namedValues
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
  ]
}

// Create policy templates
module policyTemplatesDeployment 'policy-templates.bicep' = if (!empty(policyTemplates)) {
  name: 'policyTemplatesDeployment'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    policyTemplates: policyTemplates
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
  ]
}

// Apply namespaced policies
module namespacedPolicies 'namespaced-policies.bicep' = if (!empty(policyConfig)) {
  name: 'namespacedPolicies'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    policyConfig: policyConfig
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
    namedValuesDeployment
  ]
}

// Register APIs using the api-registrations module
module apiRegistrations 'api-registrations.bicep' = {
  name: 'apiRegistrations'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    isSharedMode: sharedModeSelected
    apis: apis
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
    namespacedPolicies
    policyTemplatesDeployment
  ]
}

// Create subscriptions
module subscriptionManagement 'subscription-management.bicep' = if (!empty(subscriptions)) {
  name: 'subscriptionManagement'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    subscriptions: subscriptions
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
    apiRegistrations
  ]
}

// Configure subscription approval workflow
module subscriptionApproval 'subscription-approval.bicep' = if (!empty(approvalWorkflow)) {
  name: 'subscriptionApproval'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    approvalWorkflow: approvalWorkflow
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
  ]
}

// Configure usage quotas and rate limiting
module usageQuotas 'usage-quotas.bicep' = if (!empty(quotas)) {
  name: 'usageQuotas'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    quotas: quotas
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
  ]
}

// Configure usage tracking
module usageTrackingModule 'usage-tracking.bicep' = if (!empty(usageTracking)) {
  name: 'usageTrackingModule'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    usageTracking: usageTracking
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
    apiRegistrations
  ]
}

// Configure subscription lifecycle
module subscriptionLifecycle 'subscription-lifecycle.bicep' = if (!empty(lifecycleConfig)) {
  name: 'subscriptionLifecycle'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    lifecycleConfig: lifecycleConfig
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
  ]
}

// Configure subscription notifications
module subscriptionNotifications 'subscription-notifications.bicep' = if (!empty(notificationConfig)) {
  name: 'subscriptionNotifications'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    notificationConfig: notificationConfig
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
  ]
}

// Create and manage products
module productManagement 'product-management.bicep' = {
  name: 'productManagement'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    products: products
    location: location
    tags: tags
  }
  dependsOn: [
    sharedModeSelected ? sharedApim : dedicatedApim
  ]
}

// Outputs
output apimName string = apimName
output apimResourceGroup string = apimResourceGroup
output gatewayUrl string = sharedModeSelected ? sharedApim.properties.gatewayUrl : dedicatedApim.properties.gatewayUrl
output apiIds array = apiRegistrations.outputs.apiIds
output apiNames array = apiRegistrations.outputs.apiNames
output apiPaths array = apiRegistrations.outputs.apiPaths
output apiUrls array = apiRegistrations.outputs.apiUrls
output productIds array = productManagement.outputs.productIds

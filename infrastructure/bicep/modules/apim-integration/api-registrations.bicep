@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing in shared mode')
param projectName string

@description('Whether this is a shared APIM instance (true) or dedicated (false)')
param isSharedMode bool = false

@description('Array of API configurations to register')
param apis array = []

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Validate that we have APIs to register
resource apisValidation 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (empty(apis)) {
  name: 'apisValidation'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.30.0'
    retentionInterval: 'P1D'
    scriptContent: 'echo "Warning: No APIs provided for registration" && exit 0'
  }
}

// Deploy each API using the api-registration module
module apiRegistrations 'api-registration.bicep' = [for (api, i) in apis: {
  name: 'apiRegistration-${api.name}-${i}'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    projectName: projectName
    isSharedMode: isSharedMode
    apiName: api.name
    apiDisplayName: contains(api, 'displayName') ? api.displayName : '${projectName} ${api.name}'
    apiPath: api.path
    apiVersion: contains(api, 'version') ? api.version : 'v1'
    versioningScheme: contains(api, 'versioningScheme') ? api.versioningScheme : 'path'
    versionHeaderName: contains(api, 'versionHeaderName') ? api.versionHeaderName : 'Api-Version'
    versionQueryName: contains(api, 'versionQueryName') ? api.versionQueryName : 'api-version'
    apiSpecificationFormat: contains(api, 'specificationFormat') ? api.specificationFormat : 'openapi+json'
    apiSpecificationValue: api.specificationValue
    productName: contains(api, 'productName') ? api.productName : ''
    tags: tags
  }
}]

// Outputs
output apiIds array = [for (api, i) in apis: apiRegistrations[i].outputs.apiId]
output apiNames array = [for (api, i) in apis: apiRegistrations[i].outputs.apiName]
output apiPaths array = [for (api, i) in apis: apiRegistrations[i].outputs.apiPath]
output apiUrls array = [for (api, i) in apis: apiRegistrations[i].outputs.apiUrl]

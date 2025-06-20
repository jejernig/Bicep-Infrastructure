@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing in shared mode')
param projectName string

@description('Whether this is a shared APIM instance (true) or dedicated (false)')
param isSharedMode bool = false

@description('Name of the API to register')
param apiName string

@description('Display name for the API')
param apiDisplayName string = '${projectName} ${apiName}'

@description('Path segment for the API')
param apiPath string

@description('API version')
param apiVersion string = 'v1'

@description('API versioning scheme (path, header, query)')
@allowed([
  'path'
  'header'
  'query'
])
param versioningScheme string = 'path'

@description('API version header name (used when versioningScheme is "header")')
param versionHeaderName string = 'Api-Version'

@description('API version query parameter name (used when versioningScheme is "query")')
param versionQueryName string = 'api-version'

@description('API specification format')
@allowed([
  'openapi+json'
  'openapi+json-link'
  'openapi'
  'swagger-json'
  'swagger-link-json'
  'wadl-link-json'
  'wadl-xml'
  'wsdl'
  'wsdl-link'
])
param apiSpecificationFormat string = 'openapi+json'

@description('API specification content or URI depending on the format')
param apiSpecificationValue string

@description('Product name to associate the API with (optional)')
param productName string = ''

@description('Tags to apply to the API')
param tags object = {}

// Reference the APIM instance (works for both same resource group and cross-resource group scenarios)
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Calculate the final API path based on mode and versioning scheme
var basePath = isSharedMode ? '${projectName}/${apiPath}' : apiPath
var finalApiPath = versioningScheme == 'path' ? 
  (isSharedMode ? '${projectName}/${apiVersion}/${apiPath}' : '${apiVersion}/${apiPath}') : 
  basePath

// Validate API path to ensure it doesn't start with a slash
resource apiPathValidation 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (startsWith(apiPath, '/')) {
  name: 'apiPathValidation-${apiName}'
  location: resourceGroup().location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.30.0'
    retentionInterval: 'P1D'
    scriptContent: 'echo "Error: API path should not start with a slash (/)" && exit 1'
  }
}

// Register the API
resource api 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: '${apimName}/${apiName}'
  properties: {
    displayName: apiDisplayName
    path: finalApiPath
    protocols: ['https']
    format: apiSpecificationFormat
    value: apiSpecificationValue
    subscriptionRequired: true
    apiVersion: apiVersion
    apiVersionSetId: versioningScheme != 'path' ? apiVersionSet.id : null
    apiVersionDescription: 'Version ${apiVersion}'
  }
  tags: tags
}

// Create API version set for header or query parameter versioning
resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2021-08-01' = if (versioningScheme != 'path') {
  name: '${apimName}/${apiName}-versionset'
  properties: {
    displayName: '${apiDisplayName} Version Set'
    versioningScheme: versioningScheme
    versionHeaderName: versioningScheme == 'header' ? versionHeaderName : null
    versionQueryName: versioningScheme == 'query' ? versionQueryName : null
  }
}

// Associate with product if specified
resource apiProductLink 'Microsoft.ApiManagement/service/products/apis@2021-08-01' = if (!empty(productName)) {
  name: '${apimName}/${productName}/${apiName}'
  dependsOn: [
    api
  ]
}

// Outputs
output apiId string = api.id
output apiName string = api.name
output apiPath string = finalApiPath
output apiUrl string = '${apim.properties.gatewayUrl}/${finalApiPath}'

@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing in shared mode')
param projectName string

@description('Array of API configurations')
param apis array = []

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Extract unique product names from APIs
var productNames = union(map(filter(apis, api => contains(api, 'productName') && !empty(api.productName)), api => api.productName), [])

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create products
resource products 'Microsoft.ApiManagement/service/products@2021-08-01' = [for productName in productNames: {
  name: '${apimName}/${productName}'
  properties: {
    displayName: productName
    description: 'Product for ${projectName}'
    state: 'published'
    subscriptionRequired: true
    approvalRequired: false
  }
  tags: tags
}]

// Link APIs to products
module productApiLinks 'product-api-link.bicep' = [for (api, i) in apis: if (contains(api, 'productName') && !empty(api.productName)) {
  name: 'productApiLink-${api.name}-${i}'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    productName: api.productName
    apiName: api.name
  }
  dependsOn: [
    products
  ]
}]

// Outputs
output productNames array = productNames

@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Name of the product to link the API to')
param productName string

@description('Name of the API to link to the product')
param apiName string

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Link API to product
resource apiProductLink 'Microsoft.ApiManagement/service/products/apis@2021-08-01' = {
  name: '${productName}/${apiName}'
  parent: apim
}

// Output
output linkId string = apiProductLink.id

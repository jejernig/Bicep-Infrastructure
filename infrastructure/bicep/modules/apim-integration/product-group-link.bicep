@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Name of the group to link to products')
param groupName string

@description('Array of product names to link the group to')
param productNames array = []

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Link group to products
resource productGroupLinks 'Microsoft.ApiManagement/service/products/groups@2021-08-01' = [for productName in productNames: {
  name: '${apimName}/${productName}/${groupName}'
}]

// Outputs
output linkIds array = [for (productName, i) in productNames: {
  productName: productName
  groupName: groupName
  linkId: productGroupLinks[i].id
}]

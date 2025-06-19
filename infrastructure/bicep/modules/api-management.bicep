@description('The name of the API Management service')
param name string

@description('The Azure region for the resource')
param location string

@description('Resource tags')
param tags object

@description('The SKU of the API Management service')
param skuName string = 'Developer'

@description('The capacity of the API Management service')
param skuCapacity int = 1

@description('The email address of the publisher')
param publisherEmail string = 'admin@phantomline.io'

@description('The name of the publisher')
param publisherName string = 'PhantomLine'

// API Management resource
resource apiManagement 'Microsoft.ApiManagement/service@2022-08-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

// Outputs
output id string = apiManagement.id
output name string = apiManagement.name
output gatewayUrl string = apiManagement.properties.gatewayUrl

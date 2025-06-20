@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing and access control')
param projectName string

@description('Array of named values to create')
param namedValues array = []

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create named values
resource namedValue 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = [for nv in namedValues: {
  name: '${apimName}/${nv.name}'
  properties: {
    displayName: contains(nv, 'displayName') ? nv.displayName : nv.name
    value: nv.value
    secret: contains(nv, 'secret') ? nv.secret : false
    tags: contains(nv, 'tags') ? nv.tags : []
  }
  tags: tags
}]

// Outputs
output namedValueIds array = [for (nv, i) in namedValues: {
  name: nv.name
  id: namedValue[i].id
}]

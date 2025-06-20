@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing and access control')
param projectName string

@description('Array of product names to configure access control for')
param productNames array = []

@description('Array of group configurations')
param groups array = []

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create project-specific group if it doesn't exist
resource projectGroup 'Microsoft.ApiManagement/service/groups@2021-08-01' = {
  name: '${apimName}/${projectName}-contributors'
  properties: {
    displayName: '${projectName} Contributors'
    description: 'Contributors for ${projectName} APIs and products'
    type: 'custom'
  }
  tags: tags
}

// Create custom groups
resource customGroups 'Microsoft.ApiManagement/service/groups@2021-08-01' = [for group in groups: {
  name: '${apimName}/${projectName}-${group.name}'
  properties: {
    displayName: contains(group, 'displayName') ? group.displayName : '${projectName} ${group.name}'
    description: contains(group, 'description') ? group.description : 'Group for ${projectName} ${group.name}'
    type: 'custom'
  }
  tags: tags
}]

// Associate products with the project group
resource productGroupAssociations 'Microsoft.ApiManagement/service/products/groups@2021-08-01' = [for productName in productNames: {
  name: '${apimName}/${productName}/${projectName}-contributors'
  dependsOn: [
    projectGroup
  ]
}]

// Associate products with custom groups
module customGroupAssociations 'product-group-link.bicep' = [for (group, i) in groups: {
  name: 'customGroupAssociations-${group.name}'
  params: {
    apimName: apimName
    apimResourceGroup: apimResourceGroup
    groupName: '${projectName}-${group.name}'
    productNames: contains(group, 'products') ? group.products : productNames
  }
  dependsOn: [
    customGroups[i]
  ]
}]

// Outputs
output projectGroupId string = projectGroup.id
output projectGroupName string = projectGroup.name
output customGroupIds array = [for (group, i) in groups: {
  name: group.name
  id: customGroups[i].id
}]

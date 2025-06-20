@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing and access control')
param projectName string

@description('Array of policy templates to create')
param policyTemplates array = []

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create policy templates
resource policyTemplate 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = [for template in policyTemplates: {
  name: '${apimName}/${projectName}-${template.name}'
  properties: {
    description: contains(template, 'description') ? template.description : 'Policy template for ${projectName} - ${template.name}'
    format: contains(template, 'format') ? template.format : 'xml'
    value: template.value
  }
}]

// Outputs
output templateIds array = [for (template, i) in policyTemplates: {
  name: template.name
  id: policyTemplate[i].id
}]

@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing and access control')
param projectName string

@description('Array of subscription configurations')
param subscriptions array = []

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create subscriptions
resource subscription 'Microsoft.ApiManagement/service/subscriptions@2021-08-01' = [for sub in subscriptions: {
  name: '${apimName}/${projectName}-${sub.name}'
  properties: {
    displayName: contains(sub, 'displayName') ? sub.displayName : '${projectName} - ${sub.name}'
    scope: contains(sub, 'scope') ? sub.scope : '/products/${contains(sub, 'productName') ? sub.productName : '${projectName}-product'}'
    state: contains(sub, 'state') ? sub.state : 'active'
    allowTracing: contains(sub, 'allowTracing') ? sub.allowTracing : false
    ownerId: contains(sub, 'ownerId') ? sub.ownerId : null
    primaryKey: contains(sub, 'primaryKey') ? sub.primaryKey : null
    secondaryKey: contains(sub, 'secondaryKey') ? sub.secondaryKey : null
  }
}]

// Create subscription policies
resource subscriptionPolicy 'Microsoft.ApiManagement/service/subscriptions/policies@2021-08-01' = [for (sub, i) in subscriptions: if (contains(sub, 'policy')) {
  name: '${apimName}/${projectName}-${sub.name}/policy'
  properties: {
    format: contains(sub.policy, 'format') ? sub.policy.format : 'xml'
    value: sub.policy.value
  }
  dependsOn: [
    subscription[i]
  ]
}]

// Outputs
output subscriptionIds array = [for (sub, i) in subscriptions: {
  name: sub.name
  id: subscription[i].id
  primaryKey: subscription[i].properties.primaryKey
  secondaryKey: subscription[i].properties.secondaryKey
}]

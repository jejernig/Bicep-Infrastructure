@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing and access control')
param projectName string

@description('Array of product configurations to create')
param products array = []

@description('Default subscription settings for all products')
param defaultSubscriptionSettings object = {
  subscriptionRequired: true
  approvalRequired: false
  subscriptionsLimit: 1
  enableMultipleSubscriptions: false
}

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create products with standardized naming and configuration
resource apimProducts 'Microsoft.ApiManagement/service/products@2021-08-01' = [for product in products: {
  name: '${apimName}/${product.name}'
  properties: {
    displayName: contains(product, 'displayName') ? product.displayName : product.name
    description: contains(product, 'description') ? product.description : 'Product for ${projectName}'
    terms: contains(product, 'terms') ? product.terms : ''
    state: contains(product, 'state') ? product.state : 'published'
    subscriptionRequired: contains(product, 'subscriptionSettings') && contains(product.subscriptionSettings, 'subscriptionRequired') 
      ? product.subscriptionSettings.subscriptionRequired 
      : defaultSubscriptionSettings.subscriptionRequired
    approvalRequired: contains(product, 'subscriptionSettings') && contains(product.subscriptionSettings, 'approvalRequired') 
      ? product.subscriptionSettings.approvalRequired 
      : defaultSubscriptionSettings.approvalRequired
    subscriptionsLimit: contains(product, 'subscriptionSettings') && contains(product.subscriptionSettings, 'subscriptionsLimit') 
      ? product.subscriptionSettings.subscriptionsLimit 
      : defaultSubscriptionSettings.subscriptionsLimit
  }
  tags: union(tags, contains(product, 'tags') ? product.tags : {})
}]

// Create product policies
resource productPolicies 'Microsoft.ApiManagement/service/products/policies@2021-08-01' = [for (product, i) in products: if (contains(product, 'policy')) {
  name: '${apimName}/${product.name}/policy'
  properties: {
    format: contains(product.policy, 'format') ? product.policy.format : 'xml'
    value: product.policy.value
  }
  dependsOn: [
    apimProducts[i]
  ]
}]

// Create product groups (access control)
resource productGroups 'Microsoft.ApiManagement/service/products/groups@2021-08-01' = [for (product, i) in products: if (contains(product, 'groups')) {
  name: '${apimName}/${product.name}/administrators'
  dependsOn: [
    apimProducts[i]
  ]
}]

// Outputs
output productIds array = [for (product, i) in products: {
  name: product.name
  id: apimProducts[i].id
}]

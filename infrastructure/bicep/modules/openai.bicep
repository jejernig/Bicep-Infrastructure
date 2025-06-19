@description('The name of the Azure OpenAI service')
param name string

@description('The Azure region for the resource')
param location string = 'eastus' // Note: Azure OpenAI is only available in specific regions

@description('Resource tags')
param tags object

@description('The SKU name for Azure OpenAI')
param skuName string = 'S0'

@description('The model deployments to create')
param modelDeployments array = [
  {
    name: 'gpt-4'
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
    capacity: 10
  }
  {
    name: 'gpt-35-turbo'
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0613'
    }
    capacity: 30
  }
]

// Azure OpenAI Service
resource openAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: toLower(name)
    publicNetworkAccess: 'Enabled'
  }
}

// Model Deployments
@batchSize(1) // Deploy models one at a time to avoid conflicts
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in modelDeployments: {
  name: deployment.name
  parent: openAI
  properties: {
    model: deployment.model
    raiPolicyName: 'Default'
  }
  sku: {
    name: 'Standard'
    capacity: deployment.capacity
  }
}]

// Outputs
output id string = openAI.id
output name string = openAI.name
output endpoint string = openAI.properties.endpoint

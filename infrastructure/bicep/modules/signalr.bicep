@description('The name of the SignalR service')
param name string

@description('The Azure region for the resource')
param location string

@description('Resource tags')
param tags object

@description('The SKU of the SignalR service')
param skuName string = 'Standard_S1'

@description('The capacity of the SignalR service')
param skuCapacity int = 1

// SignalR Service
resource signalR 'Microsoft.SignalR/signalR@2022-02-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    features: [
      {
        flag: 'ServiceMode'
        value: 'Default'
      }
    ]
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
  }
}

// Outputs
output id string = signalR.id
output name string = signalR.name
output hostName string = signalR.properties.hostName

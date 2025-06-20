@description('Name of the SQL Server')
param sqlServerName string

@description('Name of the private endpoint')
param privateEndpointName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Subnet ID for the private endpoint')
param subnetId string

@description('Private DNS zone resource ID')
param privateDnsZoneId string = ''

@description('Tags to apply to resources')
param tags object = {}

// Reference the SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

// Create private endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

// Create private DNS zone group if privateDnsZoneId is provided
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = if (!empty(privateDnsZoneId)) {
  name: '${privateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-database-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}

// Outputs
output privateEndpointId string = privateEndpoint.id
output privateEndpointName string = privateEndpoint.name
output privateEndpointIpAddresses array = privateEndpoint.properties.customDnsConfigs[*].ipAddresses

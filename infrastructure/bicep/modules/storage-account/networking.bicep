param storageAccountName string
param location string = resourceGroup().location
param tags object = {}

@description('The virtual network rules to apply to the storage account')
param virtualNetworkRules array = []

@description('The IP address rules to apply to the storage account')
param ipRules array = []

@description('The default action to take when a request does not match any rules')
@allowed([
  'Allow'
  'Deny'
])
param defaultAction string = 'Deny'

@description('Specifies whether traffic is bypassed for Logging/Metrics/AzureServices')
@allowed([
  'None'
  'Logging'
  'Metrics'
  'AzureServices'
])
param bypass string = 'AzureServices'

@description('The private endpoint configurations for the storage account')
param privateEndpoints array = []

@description('The resource ID of the private DNS zone for blob service')
param privateDnsZoneIdBlob string = ''

@description('The resource ID of the private DNS zone for file service')
param privateDnsZoneIdFile string = ''

@description('The resource ID of the private DNS zone for queue service')
param privateDnsZoneIdQueue string = ''

@description('The resource ID of the private DNS zone for table service')
param privateDnsZoneIdTable string = ''

// Get the storage account resource ID
var storageAccountId = resourceId('Microsoft.Storage/storageAccounts', storageAccountName)

// Update the storage account network rules
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
  scope: resourceGroup()
}

resource storageAccountNetworkRules 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: storageAccount.sku
  kind: storageAccount.kind
  properties: {
    networkAcls: {
      bypass: bypass
      defaultAction: defaultAction
      ipRules: [for (ip, i) in ipRules: {
        value: ip.value
        action: ip.action
      }]
      virtualNetworkRules: [for (vnet, i) in virtualNetworkRules: {
        id: vnet.id
        action: vnet.action
        state: vnet.state
      }]
    }
  }
}

// Private endpoints
resource privateEndpointsResources 'Microsoft.Network/privateEndpoints@2022-07-01' = [for (pe, i) in privateEndpoints: {
  name: pe.name
  location: location
  tags: tags
  properties: {
    subnet: {
      id: pe.subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${pe.name}-connection'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: pe.groupIds
        }
      }
    ]
  }
}]

// Private DNS zone groups
resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = [for (pe, i) in privateEndpoints: {
  name: '${pe.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      if(contains(pe.groupIds, 'blob') && !empty(privateDnsZoneIdBlob)) {
        name: 'blob-privatelink-dns-zone'
        properties: {
          privateDnsZoneId: privateDnsZoneIdBlob
        }
      },
      if(contains(pe.groupIds, 'file') && !empty(privateDnsZoneIdFile)) {
        name: 'file-privatelink-dns-zone'
        properties: {
          privateDnsZoneId: privateDnsZoneIdFile
        }
      },
      if(contains(pe.groupIds, 'queue') && !empty(privateDnsZoneIdQueue)) {
        name: 'queue-privatelink-dns-zone'
        properties: {
          privateDnsZoneId: privateDnsZoneIdQueue
        }
      },
      if(contains(pe.groupIds, 'table') && !empty(privateDnsZoneIdTable)) {
        name: 'table-privatelink-dns-zone'
        properties: {
          privateDnsZoneId: privateDnsZoneIdTable
        }
      }
    ]
  }
}]

// Outputs
output privateEndpoints array = [for pe in privateEndpointsResources: {
  id: pe.id
  name: pe.name
  properties: pe.properties
}]

output networkRules object = {
  defaultAction: defaultAction
  bypass: bypass
  ipRules: ipRules
  virtualNetworkRules: virtualNetworkRules
}

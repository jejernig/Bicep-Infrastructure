param storageAccountName string
param location string = resourceGroup().location
param tags object = {}

// Import the storage account module
module storageAccount './storage-account.bicep' = {
  name: 'storageAccount-deployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: union(tags, {
      displayName: 'Storage Account'
    })
  }
}

// Deploy containers and file shares if specified
module containers './containers.bicep' = {
  name: 'storage-containers-deployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: tags
  }
  dependsOn: [
    storageAccount
  ]
}

// Configure networking if specified
module networking './networking.bicep' = {
  name: 'storage-networking-deployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: tags
  }
  dependsOn: [
    storageAccount
  ]
}

// Configure diagnostics if specified
module diagnostics './diagnostics.bicep' = {
  name: 'storage-diagnostics-deployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: tags
  }
  dependsOn: [
    storageAccount
  ]
}

// Outputs from the storage account module
output id string = storageAccount.outputs.id
output name string = storageAccount.outputs.name
output primaryEndpoints object = storageAccount.outputs.primaryEndpoints
output primaryLocation string = storageAccount.outputs.primaryLocation
output statusOfPrimary string = storageAccount.outputs.statusOfPrimary
output secondaryLocation string = storageAccount.outputs.secondaryLocation
output statusOfSecondary string = storageAccount.outputs.statusOfSecondary
output primaryEndpointsBlob string = storageAccount.outputs.primaryEndpointsBlob
output primaryEndpointsQueue string = storageAccount.outputs.primaryEndpointsQueue
output primaryEndpointsTable string = storageAccount.outputs.primaryEndpointsTable
output primaryEndpointsFile string = storageAccount.outputs.primaryEndpointsFile
output primaryEndpointsWeb string = storageAccount.outputs.primaryEndpointsWeb
output primaryLocationBlob string = storageAccount.outputs.primaryLocationBlob
output primaryLocationQueue string = storageAccount.outputs.primaryLocationQueue
output primaryLocationTable string = storageAccount.outputs.primaryLocationTable
output primaryLocationFile string = storageAccount.outputs.primaryLocationFile
output primaryLocationWeb string = storageAccount.outputs.primaryLocationWeb
output secondaryLocationBlob string = storageAccount.outputs.secondaryLocationBlob
output secondaryLocationQueue string = storageAccount.outputs.secondaryLocationQueue
output secondaryLocationTable string = storageAccount.outputs.secondaryLocationTable
output secondaryLocationFile string = storageAccount.outputs.secondaryLocationFile
output secondaryLocationWeb string = storageAccount.outputs.secondaryLocationWeb
output primaryAccessKey string = storageAccount.outputs.primaryAccessKey
output secondaryAccessKey string = storageAccount.outputs.secondaryAccessKey
output connectionString object = storageAccount.outputs.connectionString

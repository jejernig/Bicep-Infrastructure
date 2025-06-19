@description('Name of the container group')
param containerGroupName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Container image to deploy')
param image string

@description('Port to open on the container.')
param port int = 80

@description('The number of CPU cores to allocate to the container.')
param cpuCores int = 1

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb int = 2

@description('The behavior of Azure runtime if container has stopped.')
@allowed([
  'Always'
  'Never'
  'OnFailure'
])
param restartPolicy string = 'Always'

@description('Environment variables for the container')
param environmentVariables array = []

@description('Tags to apply to the resources')
param tags object = {}

@description('The Azure Container Registry login server')
param acrLoginServer string

@description('The Azure Container Registry username')
@secure()
param acrUsername string

@description('The Azure Container Registry password')
@secure()
param acrPassword string

@description('Volume mounts for the container')
param volumeMounts array = []

@description('Managed Identity ID to assign to the container group')
param managedIdentityId string = ''

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  tags: tags
  identity: !empty(managedIdentityId) ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  } : null
  properties: {
    containers: [
      {
        name: containerGroupName
        properties: {
          image: image
          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
          environmentVariables: environmentVariables
          volumeMounts: volumeMounts
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: restartPolicy
    imageRegistryCredentials: [
      {
        server: acrLoginServer
        username: acrUsername
        password: acrPassword
      }
    ]
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: port
          protocol: 'TCP'
        }
      ]
      dnsNameLabel: containerGroupName
    }
    volumes: !empty(volumeMounts) ? [for volume in volumeMounts: {
      name: volume.name
      azureFile: {
        shareName: volume.shareName
        storageAccountName: volume.storageAccountName
        storageAccountKey: volume.storageAccountKey
      }
    }] : null
  }
}

output containerGroupId string = containerGroup.id
output containerGroupFqdn string = containerGroup.properties.ipAddress.fqdn
output containerGroupIp string = containerGroup.properties.ipAddress.ip

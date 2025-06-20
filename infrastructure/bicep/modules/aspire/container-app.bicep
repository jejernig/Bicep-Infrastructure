param name string
param location string = resourceGroup().location
param tags object = {}

@description('The resource ID of the Container App Environment')
param containerAppEnvironmentId string

@description('The container image to deploy')
param containerImage string

@description('The container image tag')
param containerImageTag string = 'latest'

@description('The container port')
@minValue(1)
@maxValue(65535)
param containerPort int = 8080

@description('The number of replicas')
@minValue(0)
@maxValue(100)
param replicas int = 1

@description('The resource requirements for the container')
param resources object = {
  cpu: 0.5
  memory: '1Gi'
}

@description('Environment variables for the container')
param env array = []

@description('Secrets to be used as environment variables')
param secrets array = []

@description('The ingress configuration')
param ingress object = {
  external: true
  targetPort: containerPort
  traffic: [
    {
      latestRevision: true
      weight: 100
    }
  ]
  allowInsecure: false
}

@description('The registry configuration')
param registry object = {
  server: 'docker.io'
  username: ''
  passwordSecretRef: ''
}

// Parse the container app environment ID to get the name and resource group
var containerAppEnvironmentName = last(split(containerAppEnvironmentId, '/'))
var containerAppEnvironmentResourceGroup = resourceGroup().name

// Create the Container App
resource containerApp 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: name
  location: location
  tags: union(tags, {
    displayName: 'Container App'
    component: 'aspire'
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: [
        for secret in secrets: {
          name: secret.name
          value: secret.value
        }
      ]
      registries: !empty(registry.username) ? [
        {
          server: registry.server
          username: registry.username
          passwordSecretRef: registry.passwordSecretRef
        }
      ] : []
      ingress: {
        external: ingress.external
        targetPort: ingress.targetPort
        traffic: ingress.traffic
        allowInsecure: ingress.allowInsecure
      }
    }
    template: {
      scale: {
        minReplicas: replicas
        maxReplicas: replicas
      }
      containers: [
        {
          name: name
          image: '${containerImage}:${containerImageTag}'
          resources: {
            cpu: resources.cpu
            memory: resources.memory
          }
          env: [
            for envVar in env: envVar.secretRef ? {
              name: envVar.name
              secretRef: envVar.secretRef
            } : {
              name: envVar.name
              value: envVar.value
            }
          ]
        }
      ]
    }
  }
}

// Outputs
output id string = containerApp.id
output name string = containerApp.name
output properties object = containerApp.properties
output fqdn string = containerApp.properties.configuration.ingress.fqdn
output latestRevisionName string = containerApp.properties.latestRevisionName
output latestRevisionFqdn string = containerApp.properties.latestRevisionFqdn
output outboundIpAddresses array = containerApp.properties.outboundIpAddresses

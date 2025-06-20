param name string
param location string = resourceGroup().location
param tags object = {}

// Container Apps Environment parameters
param containerAppEnvironment object = {
  name: '${name}-env'
  internalLoadBalancerEnabled: false
  logAnalyticsWorkspaceId: ''
  infrastructureSubnetId: ''
  dockerBridgeCidr: ''
  platformReservedCidr: ''
  platformReservedDnsIp: ''
  zoneRedundant: false
}

// Container Apps parameters
param containerApps array = []

// Deploy the Container Apps Environment
module containerAppEnvironment './container-app-environment.bicep' = if (!empty(containerAppEnvironment.name)) {
  name: 'container-app-env-deployment'
  params: {
    name: containerAppEnvironment.name
    location: location
    tags: union(tags, {
      component: 'aspire-environment'
    })
    internalLoadBalancerEnabled: containerAppEnvironment.internalLoadBalancerEnabled
    logAnalyticsWorkspaceId: containerAppEnvironment.logAnalyticsWorkspaceId
    infrastructureSubnetId: containerAppEnvironment.infrastructureSubnetId
    dockerBridgeCidr: containerAppEnvironment.dockerBridgeCidr
    platformReservedCidr: containerAppEnvironment.platformReservedCidr
    platformReservedDnsIp: containerAppEnvironment.platformReservedDnsIp
    zoneRedundant: containerAppEnvironment.zoneRedundant
  }
}

// Deploy Container Apps
module containerAppsDeployment './container-app.bicep' = [for (app, i) in containerApps: {
  name: 'container-app-deployment-${i}'
  scope: resourceGroup()
  params: {
    name: app.name
    location: location
    tags: union(tags, {
      component: 'aspire-app'
      app: app.name
    })
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    containerImage: app.containerImage
    containerImageTag: app.containerImageTag
    containerPort: app.containerPort
    replicas: app.replicas
    resources: app.resources
    env: app.env
    secrets: app.secrets
    ingress: app.ingress
    registry: app.registry
  }
  dependsOn: [
    containerAppEnvironment
  ]
}]

// Outputs
output containerAppEnvironment object = !empty(containerAppEnvironment.name) ? {
  id: containerAppEnvironment.outputs.id
  name: containerAppEnvironment.outputs.name
  defaultDomain: containerAppEnvironment.outputs.defaultDomain
  staticIp: containerAppEnvironment.outputs.staticIp
  logAnalyticsWorkspaceId: containerAppEnvironment.outputs.logAnalyticsWorkspaceId
} : null

output containerApps array = [for (app, i) in containerApps: {
  name: app.name
  id: containerAppsDeployment[i].outputs.id
  fqdn: containerAppsDeployment[i].outputs.fqdn
  latestRevisionName: containerAppsDeployment[i].outputs.latestRevisionName
  latestRevisionFqdn: containerAppsDeployment[i].outputs.latestRevisionFqdn
  outboundIpAddresses: containerAppsDeployment[i].outputs.outboundIpAddresses
}]

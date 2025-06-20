param name string
param location string = resourceGroup().location
param tags object = {}

@description('The internal load balancer configuration')
param internalLoadBalancerEnabled bool = false

@description('The log analytics workspace ID for the Container Apps environment')
param logAnalyticsWorkspaceId string = ''

@description('The infrastructure subnet ID for the Container Apps environment')
param infrastructureSubnetId string = ''

@description('The Docker bridge CIDR')
@minLength(7)
@maxLength(18)
param dockerBridgeCidr string = ''

@description('The platform reserved CIDR')
@minLength(7)
@maxLength(18)
param platformReservedCidr string = ''

@description('The platform reserved DNS IP')
@minLength(7)
@maxLength(15)
param platformReservedDnsIp string = ''

@description('The zone redundancy configuration')
param zoneRedundant bool = false

// Create the Container Apps Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-04-01-preview' = {
  name: name
  location: location
  tags: union(tags, {
    displayName: 'Container Apps Environment'
    component: 'aspire'
  })
  properties: {
    appLogsConfiguration: !empty(logAnalyticsWorkspaceId) ? {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2020-08-01').customerId
        sharedKey: listKeys('${logAnalyticsWorkspaceId}/sharedKeys', '2020-08-01').primarySharedKey
      }
    } : null
    vnetConfiguration: !empty(infrastructureSubnetId) ? {
      internal: internalLoadBalancerEnabled
      infrastructureSubnetId: infrastructureSubnetId
      dockerBridgeCidr: !empty(dockerBridgeCidr) ? dockerBridgeCidr : null
      platformReservedCidr: !empty(platformReservedCidr) ? platformReservedCidr : null
      platformReservedDnsIP: !empty(platformReservedDnsIp) ? platformReservedDnsIp : null
    } : null
    zoneRedundant: zoneRedundant
  }
}

// Outputs
output id string = containerAppEnvironment.id
output name string = containerAppEnvironment.name
output properties object = containerAppEnvironment.properties
output staticIp string = containerAppEnvironment.properties.staticIp
output defaultDomain string = containerAppEnvironment.properties.defaultDomain
output infrastructureResourceGroup string = containerAppEnvironment.properties.appLogsConfiguration?.logAnalyticsConfiguration?.sharedKey == null ? '' : containerAppEnvironment.properties.appLogsConfiguration.logAnalyticsConfiguration.sharedKey
output logAnalyticsWorkspaceId string = logAnalyticsWorkspaceId

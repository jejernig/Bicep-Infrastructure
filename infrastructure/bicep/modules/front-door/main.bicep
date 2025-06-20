@description('The name of the Front Door profile')
@minLength(1)
@maxLength(64)
@description('The name must be between 1 and 64 characters long and can only contain letters, numbers, and hyphens.')
param frontDoorName string

@description('The location for the Front Door')
param location string = 'global'

@description('Tags for the Front Door')
param tags object = {}

@description('The host name of the backend')
param backendHostName string

@description('The host header to send to the backend')
param backendHostHeader string = backendHostName

@description('The HTTP port for the backend')
@minValue(1)
@maxValue(65535)
param backendHttpPort int = 80

@description('The HTTPS port for the backend')
@minValue(1)
@maxValue(65535)
param backendHttpsPort int = 443

@description('The path to match for the routing rule')
@minLength(1)
param path string = '/*'

@description('The protocol to use for the routing rule')
@allowed([
  'HttpOnly'
  'HttpsOnly'
  'HttpAndHttps'
])
param acceptedProtocols string = 'HttpsOnly'

@description('The type of routing to use')
@allowed([
  'Forwarding'
  'Redirect'
  'HttpsRedirect'
])
param routeType string = 'Forwarding'

@description('Whether to enable caching for the route')
param enableCaching bool = false

@description('The name of the custom domain')
param customDomainName string = ''

@description('The host name of the custom domain')
param customDomainHostName string = ''

@description('The resource ID of the Key Vault certificate for the custom domain')
param keyVaultCertificateId string = ''

// Front Door resource
resource frontDoor 'Microsoft.Network/frontDoors@2020-11-01' = {
  name: frontDoorName
  location: location
  tags: tags
  properties: {
    routingRules: [
      {
        name: 'defaultRoutingRule'
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', frontDoorName, 'defaultFrontendEndpoint')
            }
          ]
          acceptedProtocols: [
            acceptedProtocols
          ]
          patternsToMatch: [
            path
          ]
          enabledState: 'Enabled'
          routeConfiguration: {
            '@odata.type': routeType == 'Forwarding' ? '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration' : 
                          routeType == 'Redirect' ? '#Microsoft.Azure.FrontDoor.Models.FrontdoorRedirectConfiguration' :
                          '#Microsoft.Azure.FrontDoor.Models.FrontdoorRedirectConfiguration'
            customForwardingPath: routeType == 'Forwarding' ? '' : null
            forwardingProtocol: 'HttpsOnly'
            cacheConfiguration: routeType == 'Forwarding' ? (enableCaching ? {
              queryParameterStripDirective: 'StripNone'
              dynamicCompression: 'Enabled'
            } : null) : null
            redirectType: routeType != 'Forwarding' ? 'Moved' : null
            redirectProtocol: routeType != 'Forwarding' ? 'HttpsOnly' : null
            customHost: routeType != 'Forwarding' ? backendHostName : null
            customPath: routeType != 'Forwarding' ? path : null
            customFragment: null
            customQueryString: null
          }
        }
      }
    ]
    backendPools: [
      {
        name: 'defaultBackendPool'
        properties: {
          backends: [
            {
              address: backendHostName
              httpPort: backendHttpPort
              httpsPort: backendHttpsPort
              hostHeader: backendHostHeader
              priority: 1
              weight: 50
              enabled: 'Enabled'
              privateLinkResourceId: ''
              privateLinkLocation: ''
              privateLinkApprovalMessage: ''
            }
          ]
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', frontDoorName, 'defaultLoadBalancingSettings')
          }
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorName, 'defaultHealthProbeSettings')
          }
        }
      }
    ]
    frontendEndpoints: [
      {
        name: 'defaultFrontendEndpoint'
        properties: {
          hostName: '${frontDoorName}.azurefd.net'
          sessionAffinityEnabledState: 'Disabled'
          sessionAffinityTtlSeconds: 0
        }
      }
    ]
    backendPoolsSettings: {
      enforceCertificateNameCheck: 'Enabled'
      sendRecvTimeoutSeconds: 30
    }
    enabledState: 'Enabled'
    loadBalancingSettings: [
      {
        name: 'defaultLoadBalancingSettings'
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
          additionalLatencyMilliseconds: 0
        }
      }
    ]
    healthProbeSettings: [
      {
        name: 'defaultHealthProbeSettings'
        properties: {
          path: '/'
          protocol: 'Https'
          intervalInSeconds: 30
          healthProbeMethod: 'HEAD'
          enabledState: 'Enabled'
        }
      }
    ]
  }
}

// Custom domain if provided
resource customDomain 'Microsoft.Network/frontDoors/frontendEndpoints@2020-11-01' = if (!empty(customDomainName) && !empty(customDomainHostName)) {
  name: customDomainName
  parent: frontDoor
  properties: {
    hostName: customDomainHostName
    sessionAffinityEnabledState: 'Disabled'
    sessionAffinityTtlSeconds: 0
  }
}

// Custom domain HTTPS if certificate is provided
resource customDomainHttps 'Microsoft.Network/frontDoors/frontendEndpoints/customHttpsConfiguration@2020-11-01' = if (!empty(customDomainName) && !empty(customDomainHostName) && !empty(keyVaultCertificateId)) {
  name: '${customDomainName}/default'
  parent: frontDoor
  properties: {
    protocolType: 'ServerNameIndication'
    keyVaultCertificateSourceParameters: {
      '@odata.type': '#Microsoft.Azure.FrontDoor.Models.KeyVaultCertificateSourceParameters'
      vault: {
        id: keyVaultCertificateId
      }
      secretName: keyVaultCertificateId
    }
    certificateSource: 'AzureKeyVault'
    minimumTlsVersion: '1.2'
  }
  dependsOn: [
    customDomain
  ]
}

output id string = frontDoor.id
output name string = frontDoor.name
output frontendEndpointHostName string = '${frontDoorName}.azurefd.net'
output frontendEndpointId string = resourceId('Microsoft.Network/frontDoors/frontendEndpoints', frontDoorName, 'defaultFrontendEndpoint')
output customDomainHostName string = !empty(customDomainHostName) ? customDomainHostName : ''

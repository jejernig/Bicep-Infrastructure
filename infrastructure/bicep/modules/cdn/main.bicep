@description('The name of the CDN profile')
@minLength(1)
@maxLength(260)
@description('The name must be between 1 and 260 characters long and can only contain alphanumeric characters, hyphens, and periods.')
param cdnProfileName string

@description('The location for the CDN profile')
param location string = resourceGroup().location

@description('Tags for the CDN profile')
param tags object = {}

@description('The pricing tier of the CDN profile')
@allowed([
  'Standard_Verizon'
  'Premium_Verizon'
  'Custom_Verizon'
  'Standard_Akamai'
  'Standard_ChinaCdn'
  'Standard_Microsoft'
  'Standard_AzureFrontDoor'
])
param sku string = 'Standard_Microsoft'

@description('The name of the CDN endpoint')
param endpointName string = '${cdnProfileName}-endpoint'

@description('The origin URL for the CDN endpoint')
param originUrl string

@description('The host header to send to the origin')
param originHostHeader string = ''

@description('Whether HTTP traffic is allowed on the endpoint')
param isHttpAllowed bool = true

@description('Whether HTTPS traffic is allowed on the endpoint')
param isHttpsAllowed bool = true

@description('The query string caching behavior')
@allowed([
  'IgnoreQueryString'
  'BypassCaching'
  'UseQueryString'
  'NotSet'
])
param queryStringCachingBehavior string = 'IgnoreQueryString'

@description('The optimization type for the CDN endpoint')
@allowed([
  'GeneralWebDelivery'
  'GeneralMediaStreaming'
  'VideoOnDemandMediaStreaming'
  'LargeFileDownload'
  'DynamicSiteAcceleration'
])
param optimizationType string = 'GeneralWebDelivery'

resource cdnProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: cdnProfileName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {}
}

resource cdnEndpoint 'Microsoft.Cdn/profiles/endpoints@2021-06-01' = {
  name: endpointName
  location: 'global'
  tags: tags
  properties: {
    originHostHeader: empty(originHostHeader) ? originUrl : originHostHeader
    isHttpAllowed: isHttpAllowed
    isHttpsAllowed: isHttpsAllowed
    queryStringCachingBehavior: queryStringCachingBehavior
    optimizationType: optimizationType
    origins: [
      {
        name: 'origin'
        properties: {
          hostName: originUrl
          httpPort: 80
          httpsPort: 443
        }
      }
    ]
  }
  dependsOn: [
    cdnProfile
  ]
}

output id string = cdnProfile.id
output name string = cdnProfile.name
output endpointHostName string = cdnEndpoint.properties.hostName
output endpointId string = cdnEndpoint.id
output endpointName string = cdnEndpoint.name

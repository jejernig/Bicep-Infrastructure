@description('The name of the Redis cache')
@minLength(1)
@maxLength(63)
@description('The name must be between 1 and 63 characters long, and can only contain letters, numbers, and hyphens. The first and last character must be a letter or number.')
param redisCacheName string

@description('The location for the Redis cache')
param location string = resourceGroup().location

@description('Tags for the Redis cache')
param tags object = {}

@description('The SKU of the Redis cache to deploy')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('The SKU family to use')
@allowed([
  'C'
  'P'
])
param family string = 'C'

@description('The size of the Redis cache to deploy')
@minValue(0)
@maxValue(6)
param capacity int = 0

@description('Whether or not to enable the non-SSL Redis server port (6379)')
param enableNonSslPort bool = false

@description('The minimum TLS version required for connections to the cache')
@allowed([
  '1.0'
  '1.1'
  '1.2'
])
param minimumTlsVersion string = '1.2'

@description('Whether or not public network access is allowed for the Redis cache')
param publicNetworkAccess string = 'Enabled'

@description('The SKU name of the Redis cache')
var skuName = '${sku}'

@description('The SKU family of the Redis cache')
var skuFamily = '${family}'

@description('The SKU capacity of the Redis cache')
var skuCapacity = capacity

resource redisCache 'Microsoft.Cache/redis@2023-04-01' = {
  name: redisCacheName
  location: location
  tags: tags
  properties: {
    enableNonSslPort: enableNonSslPort
    minimumTlsVersion: minimumTlsVersion
    publicNetworkAccess: publicNetworkAccess
    sku: {
      name: skuName
      family: skuFamily
      capacity: skuCapacity
    }
  }
}

output id string = redisCache.id
output name string = redisCache.name
output hostName string = redisCache.properties.hostName
output sslPort int = redisCache.properties.sslPort
output nonSslPort int = redisCache.properties.port
output primaryKey string = listKeys(redisCache.id, redisCache.apiVersion).primaryKey
output secondaryKey string = listKeys(redisCache.id, redisCache.apiVersion).secondaryKey
output connectionString string = '${redisCache.properties.hostName}:${redisCache.properties.sslPort},password=${listKeys(redisCache.id, redisCache.apiVersion).primaryKey},ssl=True,abortConnect=False'

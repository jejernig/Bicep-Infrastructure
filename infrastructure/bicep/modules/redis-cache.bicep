@description('The name of the Redis Cache')
param name string

@description('The Azure region for the resource')
param location string

@description('Resource tags')
param tags object

@description('The SKU of the Redis Cache')
param skuName string = 'Standard'

@description('The family of the Redis Cache SKU')
param skuFamily string = 'C'

@description('The capacity of the Redis Cache')
param skuCapacity int = 1

@description('Enable non-SSL port (6379)')
param enableNonSslPort bool = false

// Redis Cache
resource redisCache 'Microsoft.Cache/redis@2022-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
      family: skuFamily
      capacity: skuCapacity
    }
    enableNonSslPort: enableNonSslPort
    minimumTlsVersion: '1.2'
    redisConfiguration: {
      'maxmemory-policy': 'volatile-lru'
    }
  }
}

// Outputs
output id string = redisCache.id
output name string = redisCache.name
output hostName string = redisCache.properties.hostName
output sslPort int = redisCache.properties.sslPort

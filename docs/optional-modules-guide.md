# Optional Modules Toggle System

This guide explains how to use the optional modules toggle system in the Bicep infrastructure templates. The system allows you to enable or disable specific Azure resources based on your requirements, making your infrastructure more modular and cost-effective.

## Table of Contents

- [Overview](#overview)
- [Available Optional Modules](#available-optional-modules)
- [Enabling/Disabling Modules](#enablingdisabling-modules)
- [Module Configuration](#module-configuration)
  - [Redis Cache](#redis-cache)
  - [CDN](#cdn)
  - [Front Door](#front-door)
- [Outputs](#outputs)
- [Example Configurations](#example-configurations)

## Overview

The optional modules toggle system uses feature flags in the `featureToggles` section of your configuration file to control which resources are deployed. When a module is disabled, its resources are not created, and any dependent resources automatically adjust their behavior accordingly.

## Available Optional Modules

The following modules can be toggled on/off:

| Module | Feature Toggle | Default | Description |
|--------|----------------|---------|-------------|
| Redis Cache | `enableRedisCache` | `false` | Azure Cache for Redis instance for caching and pub/sub |
| CDN | `enableCdn` | `false` | Azure Content Delivery Network for static content |
| Front Door | `enableFrontDoor` | `false` | Global HTTP/HTTPS load balancer with WAF |

## Enabling/Disabling Modules

To enable or disable a module, set its corresponding feature toggle in your configuration file:

```yaml
featureToggles:
  enableRedisCache: true  # Enable Redis Cache
  enableCdn: false        # Disable CDN
  enableFrontDoor: true   # Enable Front Door
```

## Module Configuration

### Redis Cache

When enabled, creates an Azure Cache for Redis instance with configurable settings:

```yaml
moduleConfigurations:
  redisCache:
    sku: Standard        # Basic, Standard, or Premium
    family: C            # C (Basic/Standard) or P (Premium)
    capacity: 1          # 0-6 (varies by SKU)
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
```

### CDN

When enabled, creates a CDN profile and endpoint for content delivery:

```yaml
moduleConfigurations:
  cdn:
    sku: Standard_Microsoft  # Standard_Microsoft, Standard_Akamai, etc.
    originUrl: your-app.azurewebsites.net
    originHostHeader: your-app.azurewebsites.net
    isHttpAllowed: false
    isHttpsAllowed: true
    queryStringCachingBehavior: IgnoreQueryString
    optimizationType: GeneralWebDelivery
```

### Front Door

When enabled, creates an Azure Front Door instance for global load balancing and WAF:

```yaml
moduleConfigurations:
  frontDoor:
    backendHostName: your-app.azurewebsites.net
    backendHostHeader: your-app.azurewebsites.net
    backendHttpPort: 80
    backendHttpsPort: 443
    path: '/*'
    acceptedProtocols: HttpsOnly
    routeType: Forwarding
    enableCaching: true
    # Optional custom domain configuration
    # customDomainName: myapp-frontend
    # customDomainHostName: myapp.contoso.com
    # keyVaultCertificateId: /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.KeyVault/vaults/{vault-name}/secrets/{certificate-name}
```

## Outputs

The following outputs are available for optional modules:

### Redis Cache

- `redisCacheName`: Name of the Redis Cache
- `redisCacheHostName`: Hostname of the Redis Cache
- `redisCachePort`: SSL port number
- `redisCacheConnectionString`: Connection string with primary key
- `redisCachePrimaryKey`: Primary access key
- `redisCacheSecondaryKey`: Secondary access key

### CDN

- `cdnProfileName`: Name of the CDN profile
- `cdnEndpointName`: Name of the CDN endpoint
- `cdnEndpointHostName`: Hostname of the CDN endpoint
- `cdnProvisioningState`: Current provisioning state
- `cdnResourceState`: Current resource state

### Front Door

- `frontDoorName`: Name of the Front Door profile
- `frontDoorEndpoint`: Front Door endpoint hostname
- `frontDoorCustomDomain`: Custom domain name (if configured)
- `frontDoorCname`: CNAME record for Front Door
- `frontDoorProvisioningState`: Current provisioning state
- `frontDoorResourceState`: Current resource state

### Combined Outputs

- `webAppEndpoints`: Object with all web endpoints (Function App, CDN, Front Door)
- `connectionStrings`: Object with connection strings for all enabled services
- `resourceIds`: Object with resource IDs for all enabled resources
- `enabledModules`: Object showing which modules are currently enabled

## Example Configurations

### Basic Web Application with CDN

```yaml
featureToggles:
  enableRedisCache: true
  enableCdn: true
  enableFrontDoor: false

moduleConfigurations:
  redisCache:
    sku: Basic
    family: C
    capacity: 0
    
  cdn:
    sku: Standard_Microsoft
    originUrl: myapp.azurewebsites.net
    originHostHeader: myapp.azurewebsites.net
    isHttpAllowed: false
    isHttpsAllowed: true
```

### Enterprise-Grade Global Application

```yaml
featureToggles:
  enableRedisCache: true
  enableCdn: true
  enableFrontDoor: true

moduleConfigurations:
  redisCache:
    sku: Premium
    family: P
    capacity: 1
    
  cdn:
    sku: Standard_Microsoft
    originUrl: myapp.azurewebsites.net
    originHostHeader: myapp.azurewebsites.net
    isHttpAllowed: false
    isHttpsAllowed: true
    
  frontDoor:
    backendHostName: myapp.azurewebsites.net
    backendHostHeader: myapp.azurewebsites.net
    backendHttpPort: 80
    backendHttpsPort: 443
    path: '/*'
    acceptedProtocols: HttpsOnly
    routeType: Forwarding
    enableCaching: true
    customDomainName: myapp-frontend
    customDomainHostName: app.contoso.com
    keyVaultCertificateId: /subscriptions/.../secrets/ssl-cert
```

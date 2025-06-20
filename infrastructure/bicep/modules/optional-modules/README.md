# Optional Modules

This directory contains optional Azure resource modules that can be enabled or disabled via feature toggles in your Bicep configuration.

## Available Optional Modules

1. **Redis Cache** - In-memory data store for caching and message brokering
   - Path: `./redis/`
   - Toggle: `enableRedisCache`

2. **Content Delivery Network (CDN)** - Global content delivery with caching and optimization
   - Path: `./cdn/`
   - Toggle: `enableCdn`

3. **Azure Front Door** - Global HTTP/HTTPS load balancer with WAF and DDoS protection
   - Path: `./front-door/`
   - Toggle: `enableFrontDoor`

## Usage

### Enabling/Disabling Modules

To enable or disable an optional module, update the `featureToggles` section in your `bicep.config.yaml`:

```yaml
featureToggles:
  enableRedisCache: true  # Enable Redis Cache
  enableCdn: false        # Disable CDN
  enableFrontDoor: true   # Enable Front Door
```

### Configuration

Each module can be configured using the `moduleConfigurations` section in your configuration file. Refer to the individual module documentation for available options.

## Module Details

### Redis Cache

Provides a managed Redis cache service for session management, caching, and pub/sub messaging.

**Key Features:**
- Multiple SKUs (Basic, Standard, Premium)
- Data persistence
- Redis clustering
- Geo-replication
- Virtual network integration

**Example Configuration:**
```yaml
moduleConfigurations:
  redisCache:
    sku: Premium
    family: P
    capacity: 1
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
```

### Content Delivery Network (CDN)

Delivers high-bandwidth content with low latency using Microsoft's global network.

**Key Features:**
- Multiple SKUs (Standard_Microsoft, Standard_Akamai, etc.)
- Custom domain with HTTPS
- URL rewrite and redirect rules
- Caching policies
- DDoS protection

**Example Configuration:**
```yaml
moduleConfigurations:
  cdn:
    sku: Standard_Microsoft
    originUrl: your-app.azurewebsites.net
    isHttpsAllowed: true
    optimizationType: DynamicSiteAcceleration
```

### Azure Front Door

A global, scalable entry-point that uses the Microsoft global edge network.

**Key Features:**
- Global HTTP load balancing
- SSL offloading
- Web Application Firewall (WAF)
- URL-based routing
- Session affinity
- Custom domains with SSL

**Example Configuration:**
```yaml
moduleConfigurations:
  frontDoor:
    backendHostName: your-app.azurewebsites.net
    acceptedProtocols: HttpsOnly
    routeType: Forwarding
    enableCaching: true
```

## Dependencies

- **Redis Cache**: None
- **CDN**: Requires a publicly accessible origin (e.g., App Service, Storage Account)
- **Front Door**: Requires a backend service (e.g., App Service, API Management)

## Best Practices

1. **Development vs Production**: Use minimal configurations in development to reduce costs.
2. **Security**: Always enable HTTPS and disable non-SSL ports in production.
3. **Monitoring**: Set up alerts and monitoring for all production resources.
4. **Cost Management**: Use the appropriate SKU and capacity for your workload.
5. **Documentation**: Keep your configuration files well-documented for team members.

## Troubleshooting

### Redis Cache
- **Connection Issues**: Verify network security groups and firewall rules
- **Performance**: Monitor cache metrics and scale up if needed
- **Failover**: Configure geo-replication for high availability

### CDN
- **Caching Issues**: Check cache control headers and purge if needed
- **HTTPS Errors**: Verify SSL certificate configuration
- **Origin Issues**: Ensure the origin is accessible and responding correctly

### Front Door
- **Routing Issues**: Verify backend pool health and routing rules
- **WAF Blocks**: Check WAF logs for blocked requests
- **Performance**: Monitor backend health and latency metrics

## Related Documentation

- [Azure Redis Cache Documentation](https://docs.microsoft.com/azure/azure-cache-for-redis/)
- [Azure CDN Documentation](https://docs.microsoft.com/azure/cdn/)
- [Azure Front Door Documentation](https://docs.microsoft.com/azure/frontdoor/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/overview)

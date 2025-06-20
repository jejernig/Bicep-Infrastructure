# API Versioning Strategy

This document outlines the strategy for versioning APIs within Azure API Management, ensuring a consistent approach across both shared and dedicated APIM operational modes.

## Overview

API versioning is essential for maintaining backward compatibility while allowing for evolution of your APIs. This strategy document defines how API versions should be structured, managed, and communicated to consumers in both shared and dedicated APIM operational modes.

## Version Numbering Scheme

### Semantic Versioning

All APIs should follow semantic versioning principles:

```
MAJOR.MINOR.PATCH
```

- **MAJOR**: Incremented for incompatible API changes
- **MINOR**: Incremented for backward-compatible functionality additions
- **PATCH**: Incremented for backward-compatible bug fixes

For URL paths and display names, only the MAJOR version is typically used (e.g., `v1`, `v2`).

## Versioning Approaches

The infrastructure supports three versioning approaches:

### 1. Path-Based Versioning (Recommended)

Version is included in the URL path:

```
https://{apim-name}.azure-api.net/{path}/{version}/{resource}
```

#### Shared Mode Example:
```
https://central-apim.azure-api.net/billing/v1/invoices
https://central-apim.azure-api.net/billing/v2/invoices
```

#### Dedicated Mode Example:
```
https://billing-apim.azure-api.net/v1/invoices
https://billing-apim.azure-api.net/v2/invoices
```

### 2. Header-Based Versioning

Version is specified in a custom header:

```
GET /invoices HTTP/1.1
Host: {apim-name}.azure-api.net
Api-Version: v1
```

### 3. Query Parameter Versioning

Version is specified as a query parameter:

```
https://{apim-name}.azure-api.net/{path}/invoices?api-version=v1
```

## Implementation in Bicep

### Configuration Structure

API versioning is configured in the `bicep.config.json` file under each API entry:

```json
{
  "apis": [
    {
      "name": "invoices-api-v1",
      "displayName": "Invoices API v1",
      "path": "invoices",
      "version": "v1",
      "versioningScheme": "path",
      "specificationFormat": "openapi+json-link",
      "specificationValue": "https://example.com/specs/invoices-v1.json"
    },
    {
      "name": "invoices-api-v2",
      "displayName": "Invoices API v2",
      "path": "invoices",
      "version": "v2",
      "versioningScheme": "path",
      "specificationFormat": "openapi+json-link",
      "specificationValue": "https://example.com/specs/invoices-v2.json"
    }
  ]
}
```

### Versioning Scheme Options

The `versioningScheme` property can be set to:

- `path`: Version in URL path (default)
- `header`: Version in custom header
- `query`: Version in query parameter

## Version Management

### Maintaining Multiple Versions

Multiple versions of an API can coexist by:

1. Registering each version as a separate API with the same base path but different versions
2. Using different backend services or routing logic for each version
3. Applying version-specific policies

### Version Lifecycle Management

#### Active Development
- Latest version under active development
- May have frequent changes
- Should be clearly marked as "in development" or "preview"

#### Current Stable
- Latest stable version
- Fully supported
- Recommended for new integrations

#### Maintained Legacy
- Previous stable versions
- Still supported but may receive only critical updates
- Not recommended for new integrations

#### Deprecated
- Versions scheduled for retirement
- Minimal support
- Clear migration path to newer versions provided
- Warning headers added to responses

#### Retired
- Versions no longer available
- Requests return appropriate error responses with migration information

## Version Deprecation Process

1. **Announcement Phase**:
   - Notify users through developer portal
   - Add deprecation notice in API documentation
   - Set `x-api-deprecated` header in responses

2. **Grace Period**:
   - Continue supporting the deprecated version
   - Provide migration guides and support
   - Monitor usage to identify active consumers

3. **Retirement**:
   - Remove the API version or return 410 Gone responses
   - Redirect documentation to newer versions

## Version-Specific Policies

Different policies can be applied to different API versions:

### Example: Rate Limiting by Version

```xml
<policies>
  <inbound>
    <base />
    <choose>
      <when condition="@(context.Api.Version.Equals("v1"))">
        <rate-limit calls="5" renewal-period="60" />
      </when>
      <when condition="@(context.Api.Version.Equals("v2"))">
        <rate-limit calls="10" renewal-period="60" />
      </when>
    </choose>
  </inbound>
</policies>
```

### Example: Feature Toggles by Version

```xml
<policies>
  <inbound>
    <base />
    <choose>
      <when condition="@(context.Api.Version.Equals("v2"))">
        <set-backend-service base-url="https://v2-service.example.com" />
      </when>
      <otherwise>
        <set-backend-service base-url="https://v1-service.example.com" />
      </otherwise>
    </choose>
  </inbound>
</policies>
```

## Documentation Requirements

### Version Information in API Documentation

All API documentation should include:

1. Current version number
2. Release date
3. Support status (preview, current, deprecated, etc.)
4. End-of-life date (if applicable)
5. Changes from previous versions
6. Migration guides (when applicable)

### OpenAPI Specification

Version information should be included in OpenAPI specifications:

```json
{
  "openapi": "3.0.0",
  "info": {
    "title": "Invoices API",
    "version": "2.0.0",
    "description": "API for managing invoices",
    "x-api-lifecycle-stage": "current",
    "x-api-deprecated": false,
    "x-api-end-of-life-date": null
  }
}
```

## Best Practices

1. **Be Consistent**: Use the same versioning approach across all APIs
2. **Version from the Start**: Even initial releases should be explicitly versioned
3. **Avoid Breaking Changes**: Make backward-compatible changes when possible
4. **Clear Communication**: Provide clear documentation about version differences
5. **Gradual Transition**: Allow adequate time for consumers to migrate
6. **Monitor Usage**: Track which versions are being used to inform deprecation decisions
7. **Test All Versions**: Maintain test suites for all supported versions

## Implementation Checklist

- [ ] Define version numbering scheme
- [ ] Choose versioning approach (path, header, query)
- [ ] Update API registration module to support versioning
- [ ] Implement version-specific policy application
- [ ] Create documentation templates with version information
- [ ] Establish version lifecycle management process
- [ ] Set up monitoring for version usage

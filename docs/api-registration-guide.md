# API Registration Guide

This guide explains how to register APIs with the APIM integration module in both shared and dedicated operational modes.

## Overview

The API registration process allows you to register one or more APIs with an API Management instance. The process works for both shared and dedicated APIM modes, with appropriate namespace isolation in shared mode.

## Configuration Structure

API registration is configured in the `bicep.config.json` file under the `moduleConfigurations.apiManagement.apis` array. Each entry in this array represents an API to be registered.

### Example Configuration

```json
{
  "moduleConfigurations": {
    "apiManagement": {
      "operationalMode": "shared",
      "sharedApimResourceId": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/central-apis-rg/providers/Microsoft.ApiManagement/service/central-apim",
      "apis": [
        {
          "name": "users-api",
          "path": "users",
          "version": "v1",
          "specificationFormat": "openapi+json-link",
          "specificationValue": "https://raw.githubusercontent.com/example/apis/main/users-api-spec.json",
          "productName": "internal"
        }
      ]
    }
  }
}
```

## API Configuration Properties

| Property | Description | Required | Default |
|----------|-------------|----------|---------|
| `name` | Unique name for the API | Yes | - |
| `path` | URL path segment for the API | Yes | - |
| `version` | API version (used in path for shared mode) | No | `v1` |
| `specificationFormat` | Format of the API specification | No | `openapi+json` |
| `specificationValue` | Content or URI of the API specification | Yes | - |
| `productName` | Product to associate the API with | No | - |
| `policies` | API policies configuration | No | - |

## Path Structure

### Shared Mode

In shared mode, APIs are automatically namespaced under the project name and version:

```
https://{shared-apim-name}.azure-api.net/{projectName}/{apiVersion}/{apiPath}
```

For example, if your project name is "billing", API version is "v1", and API path is "invoices", the full path would be:

```
https://central-apim.azure-api.net/billing/v1/invoices
```

### Dedicated Mode

In dedicated mode, APIs use the path as specified:

```
https://{projectName}-apim.azure-api.net/{apiPath}
```

For example, if your API path is "invoices", the full path would be:

```
https://billing-apim.azure-api.net/invoices
```

## API Versioning

API versioning is handled differently depending on the operational mode:

### Shared Mode

In shared mode, the version is included in the URL path:

```
/{projectName}/{apiVersion}/{apiPath}
```

This allows multiple versions of the same API to coexist under different paths.

### Dedicated Mode

In dedicated mode, you have two options for versioning:

1. **Path-based versioning**: Include the version in the API path
   ```
   /v1/users
   /v2/users
   ```

2. **Header-based versioning**: Use the same path but differentiate with an API version header
   ```
   /users (with header "Api-Version: v1")
   /users (with header "Api-Version: v2")
   ```

## API Specification Formats

The following specification formats are supported:

- `openapi+json`: OpenAPI specification in JSON format (inline)
- `openapi+json-link`: OpenAPI specification in JSON format (URL)
- `openapi`: OpenAPI specification (inline)
- `swagger-json`: Swagger specification in JSON format (inline)
- `swagger-link-json`: Swagger specification in JSON format (URL)
- `wadl-link-json`: WADL specification in JSON format (URL)
- `wadl-xml`: WADL specification in XML format (inline)
- `wsdl`: WSDL specification (inline)
- `wsdl-link`: WSDL specification (URL)

## Validation

Before deploying, you can validate your API configurations to ensure there are no path conflicts:

```bash
node infrastructure/scripts/validate-api-paths.js --config path/to/bicep.config.json
```

This script checks for:
- Duplicate API names
- Invalid path formats (e.g., paths starting with a slash)
- Potential namespace conflicts in shared mode

## Best Practices

1. **Use consistent naming**: Follow a consistent naming convention for your APIs
2. **Keep paths simple**: Use noun-based paths that reflect the resource
3. **Version all APIs**: Always include a version, even for the first version
4. **Use descriptive product names**: Products should clearly indicate their purpose
5. **Document your APIs**: Provide comprehensive OpenAPI specifications
6. **Test before deployment**: Validate configurations before deploying

## Troubleshooting

### Common Issues

1. **Path conflicts**: In shared mode, ensure your API paths don't conflict with other projects
2. **Invalid specifications**: Verify your API specification is valid
3. **Cross-resource group permissions**: For shared mode, ensure you have proper permissions

### Error Messages

- "API path should not start with a slash": Remove the leading slash from your API path
- "Duplicate API names found": Ensure all API names within your project are unique
- "API path does not start with project name": In shared mode, this is a warning that your path may not follow conventions

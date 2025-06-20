# APIM Product Association Strategy

This document outlines the strategy for organizing APIs into products within Azure API Management, maintaining proper boundaries between different projects, and managing the product lifecycle.

## Overview

Products in Azure API Management serve as containers for APIs, allowing you to group related APIs together and apply consistent policies, access controls, and subscription requirements. This strategy document defines how products should be created, managed, and associated with APIs in both shared and dedicated APIM operational modes.

## Product Naming Conventions

### Shared Mode

In shared APIM mode, product names should follow this convention:

```
{projectName}-{productType}
```

For example:
- `billing-internal`
- `billing-public`
- `users-partner`

### Dedicated Mode

In dedicated APIM mode, product names can be simpler:

```
{productType}
```

For example:
- `internal`
- `public`
- `partner`

## Product Types

The following standard product types are recommended:

| Product Type | Description | Subscription Required | Approval Required |
|-------------|-------------|----------------------|-------------------|
| `internal` | APIs for internal consumption | Yes | Yes |
| `public` | APIs for public consumption | Yes | No |
| `partner` | APIs for partner integration | Yes | Yes |
| `system` | APIs for system-to-system integration | Yes | Yes |
| `free` | APIs with no subscription requirement | No | No |

## Product Configuration

### Required Metadata

Each product should include the following metadata:

- `name`: Unique identifier for the product
- `displayName`: Human-readable name
- `description`: Clear description of the product's purpose
- `state`: Published or not published
- `subscriptionSettings`: Configuration for subscriptions
- `tags`: Organizational tags

### Example Configuration

```json
{
  "products": [
    {
      "name": "billing-internal",
      "displayName": "Billing Internal APIs",
      "description": "APIs for internal billing operations",
      "state": "published",
      "subscriptionSettings": {
        "subscriptionRequired": true,
        "approvalRequired": true,
        "subscriptionsLimit": 5
      },
      "tags": {
        "department": "finance",
        "environment": "production"
      }
    }
  ]
}
```

## Access Control

### Group-Based Access Control

Products should use APIM groups for access control:

- `Administrators`: Full control over the product
- `Developers`: Can view and test the product
- `Guests`: Limited access to published documentation

### Project Isolation

In shared mode, access control should be implemented to ensure projects can only modify their own products:

1. Create a custom group for each project team
2. Associate the group with the project's products
3. Use Azure RBAC to restrict access to specific products

## API Association Process

### Association Guidelines

1. Each API should be associated with at least one product
2. APIs should be associated with products based on their intended audience
3. The same API can be associated with multiple products if needed
4. Product association should be defined in the API configuration

### Configuration Example

```json
{
  "apis": [
    {
      "name": "invoices-api",
      "path": "invoices",
      "version": "v1",
      "specificationFormat": "openapi+json-link",
      "specificationValue": "https://example.com/specs/invoices-v1.json",
      "productName": "billing-internal"
    }
  ]
}
```

## Product Lifecycle Management

### Creation

1. Define product in the `bicep.config.json` file
2. Deploy using the APIM integration module
3. Apply appropriate access controls
4. Associate APIs with the product

### Updates

1. Modify product configuration in `bicep.config.json`
2. Redeploy using the APIM integration module
3. Update documentation as needed

### Deprecation

1. Mark product as deprecated in configuration
2. Set state to "not published" for gradual deprecation
3. Notify subscribers of deprecation timeline
4. Eventually remove product from configuration

## Subscription Management

### Subscription Settings

Each product should define:

- Whether subscriptions are required
- Whether subscription approval is required
- Maximum number of subscriptions per user/application
- Whether multiple active subscriptions are allowed

### Subscription Keys

- Primary and secondary keys are automatically generated
- Keys should be rotated regularly according to security policies
- Key rotation should be coordinated with API consumers

## Implementation in Bicep

The product association strategy is implemented through three main Bicep modules:

1. `product-management.bicep`: Creates and configures products
2. `api-registration.bicep`: Registers individual APIs
3. `product-api-link.bicep`: Associates APIs with products

These modules work together to ensure consistent product creation and API association across deployments.

## Best Practices

1. **Logical Grouping**: Group APIs by function, audience, or business domain
2. **Consistent Naming**: Follow naming conventions consistently
3. **Minimal Products**: Create only as many products as needed
4. **Documentation**: Document each product's purpose and intended audience
5. **Access Control**: Apply appropriate access controls to each product
6. **Policy Consistency**: Apply consistent policies at the product level
7. **Versioning**: Consider versioning in product strategy (e.g., separate products for major versions)

## Monitoring and Governance

1. **Usage Metrics**: Monitor product usage and subscription activity
2. **Policy Compliance**: Regularly audit products for policy compliance
3. **Access Reviews**: Conduct periodic access reviews for product groups
4. **Documentation Updates**: Keep product documentation up to date

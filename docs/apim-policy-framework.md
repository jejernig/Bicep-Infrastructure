# APIM Policy Framework

This document outlines the policy framework for Azure API Management (APIM), explaining the hierarchical structure, inheritance model, and best practices for policy management.

## Policy Hierarchy

Policies in Azure API Management are applied at four levels, with each level inheriting from the level above:

1. **Global**: Applied to all APIs in the APIM instance
2. **Product**: Applied to all APIs associated with a specific product
3. **API**: Applied to all operations within a specific API
4. **Operation**: Applied to a specific API operation

The inheritance flow is:
```
Global → Product → API → Operation
```

## Policy Inheritance Model

Policies use a base-inheritance model where each level can reference the policies from its parent level using the `<base />` element. This allows for:

- Extending parent policies with additional functionality
- Overriding specific behaviors while maintaining others
- Creating a consistent policy foundation across all APIs

### Example: Policy Inheritance

**Global Policy:**
```xml
<policies>
  <inbound>
    <cors />
    <set-header name="X-Request-ID" exists-action="skip">
      <value>@(context.RequestId)</value>
    </set-header>
  </inbound>
</policies>
```

**API Policy (inheriting from Global):**
```xml
<policies>
  <inbound>
    <base />
    <rate-limit calls="5" renewal-period="60" />
  </inbound>
</policies>
```

**Operation Policy (inheriting from API):**
```xml
<policies>
  <inbound>
    <base />
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" />
  </inbound>
</policies>
```

In this example, the Operation policy effectively includes CORS, request ID, rate limiting, and JWT validation.

## Project Isolation in Shared Mode

In shared APIM mode, it's crucial to prevent policy conflicts between different projects. Our framework implements several mechanisms to ensure isolation:

### 1. Namespaced Named Values

Each project has its own set of named values with project-specific prefixes:

```
{projectName}-appinsights-key
{projectName}-backend-url
{projectName}-namespace
```

### 2. Project-Specific Policy Fragments

Policy fragments are created with project-specific naming:

```
{projectName}-cors-policy
{projectName}-rate-limit-policy
```

### 3. Scoped Access Control

Access to policies is controlled through APIM groups with project-specific permissions.

### 4. Path-Based Isolation

APIs are deployed with project-specific path prefixes to prevent path conflicts.

## Policy Templates

Our framework provides several policy templates that can be customized for each project:

### Basic Security Policy
```xml
<policies>
  <inbound>
    <base />
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401">
      <openid-config url="{{oidc-config-url}}" />
      <required-claims>
        <claim name="aud" match="any">
          <value>{{api-audience}}</value>
        </claim>
      </required-claims>
    </validate-jwt>
  </inbound>
</policies>
```

### Rate Limiting Policy
```xml
<policies>
  <inbound>
    <base />
    <rate-limit calls="{{rate-limit-calls}}" renewal-period="{{rate-limit-period}}" />
  </inbound>
</policies>
```

### CORS Policy
```xml
<policies>
  <inbound>
    <base />
    <cors allow-credentials="true">
      <allowed-origins>
        <origin>{{allowed-origin}}</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
        <method>PATCH</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
      <expose-headers>
        <header>*</header>
      </expose-headers>
    </cors>
  </inbound>
</policies>
```

### Caching Policy
```xml
<policies>
  <inbound>
    <base />
    <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" downstream-caching-type="none">
      <vary-by-header>Accept</vary-by-header>
      <vary-by-header>Accept-Charset</vary-by-header>
    </cache-lookup>
  </inbound>
  <outbound>
    <base />
    <cache-store duration="{{cache-duration}}" />
  </outbound>
</policies>
```

## Policy Application in Bicep

Our Bicep modules apply policies at different levels:

1. **Global Policies**: Applied using the `global-policies.bicep` module
2. **Project-Specific Policies**: Applied using the `namespaced-policies.bicep` module
3. **Product Policies**: Applied in the `product-management.bicep` module
4. **API Policies**: Applied in the `api-registration.bicep` module
5. **Version-Specific Policies**: Applied in the `api-version-policies.bicep` module

## Policy Testing Framework

To validate policy behavior, we recommend:

1. **Unit Testing**: Test individual policy fragments with mock contexts
2. **Integration Testing**: Deploy policies to a test APIM instance and validate behavior
3. **Regression Testing**: Ensure policy changes don't break existing functionality

## Best Practices

1. **Use the Base Element**: Always include `<base />` to inherit parent policies
2. **Namespace Your Policies**: Use project-specific prefixes for named values and policy fragments
3. **Minimize Global Policies**: Keep global policies minimal to avoid affecting all APIs
4. **Use Named Values**: Store configuration in named values rather than hardcoding
5. **Document Policy Changes**: Maintain a changelog for policy modifications
6. **Test Before Deployment**: Validate policies in a test environment before production
7. **Use Policy Fragments**: Reuse common policy logic through fragments
8. **Monitor Policy Performance**: Watch for policies that might impact API performance
9. **Implement Gradual Rollout**: For significant policy changes, consider a phased approach
10. **Regular Audits**: Periodically review policies to ensure they meet security and performance requirements

# Subscription Management Guide

This guide provides comprehensive documentation for the subscription management system implemented in the Bicep Infrastructure project. It covers subscription lifecycle, approval workflows, usage tracking, quotas, rate limiting, and notification systems.

## Table of Contents

- [Overview](#overview)
- [Subscription Lifecycle](#subscription-lifecycle)
- [Approval Workflows](#approval-workflows)
- [Usage Quotas and Rate Limiting](#usage-quotas-and-rate-limiting)
- [Usage Tracking and Reporting](#usage-tracking-and-reporting)
- [Notification Systems](#notification-systems)
- [Configuration Examples](#configuration-examples)

## Overview

The subscription management system provides a comprehensive framework for managing API subscriptions in Azure API Management. It enables project-specific access control, usage tracking, and subscription lifecycle management. The system is designed to work in both shared and dedicated APIM operational modes.

The system consists of the following components:

- **Subscription Management**: Core subscription creation and management
- **Approval Workflows**: Processes for subscription requests and approvals
- **Usage Quotas and Rate Limiting**: Controls for API usage
- **Usage Tracking**: Monitoring and reporting of API usage
- **Subscription Lifecycle**: Management of subscription states and expiration
- **Notification Systems**: Alerts for subscription-related events

## Subscription Lifecycle

### States

Subscriptions in the system can exist in the following states:

1. **Submitted**: Initial state when a subscription is requested but not yet approved
2. **Active**: Subscription is approved and in use
3. **Suspended**: Subscription is temporarily disabled
4. **Cancelled**: Subscription has been terminated
5. **Expired**: Subscription has reached its end date

### Lifecycle Stages

The subscription lifecycle includes the following stages:

1. **Creation**: A subscription is created, either automatically or through a request
2. **Approval**: For subscriptions requiring approval, an admin reviews and approves/rejects
3. **Active Use**: The subscription is active and can be used to access APIs
4. **Renewal**: Before expiration, the subscription can be renewed
5. **Expiration**: If not renewed, the subscription expires
6. **Grace Period**: Optional period after expiration where limited access is still allowed
7. **Revocation**: Subscription can be revoked at any time if terms are violated

### Configuration

The subscription lifecycle is configured using the `lifecycleConfig` parameter in the deployment template:

```json
"lifecycleConfig": {
  "value": {
    "expirationHandling": true,
    "renewalNotification": {
      "daysBeforeExpiration": 30
    },
    "gracePeriod": {
      "days": 7
    },
    "revocationHandling": true
  }
}
```

## Approval Workflows

### Approval Process

The subscription approval workflow supports the following scenarios:

1. **Automatic Approval**: Subscriptions are automatically approved
2. **Email Notification**: Administrators are notified via email for manual approval
3. **Webhook Integration**: External systems can be integrated for approval decisions

### Configuration

Approval workflows are configured using the `approvalWorkflow` parameter:

```json
"approvalWorkflow": {
  "value": {
    "notificationEmails": [
      "api-admin@example.com"
    ],
    "expirationEmails": [
      "api-admin@example.com"
    ],
    "webhookUrl": "https://example.com/api/subscription-approval",
    "webhookCredential": "SharedAccessSignature sr=https%3A%2F%2Fexample.com&sig=ABC123"
  }
}
```

### Webhook Payload

When a subscription request is received, the following JSON payload is sent to the webhook:

```json
{
  "event": "subscription-request",
  "projectName": "project-name",
  "subscriptionId": "subscription-id",
  "productId": "product-id",
  "productName": "product-name",
  "userId": "user-id",
  "userEmail": "user@example.com",
  "timestamp": "2023-06-19T12:34:56.789Z"
}
```

## Usage Quotas and Rate Limiting

### Quota Types

The system supports the following types of usage controls:

1. **Call Quotas**: Limit the total number of calls within a period
2. **Rate Limits**: Restrict the number of calls per time unit
3. **Spike Arrest**: Prevent traffic spikes by limiting bursts
4. **Per-Key Quotas**: Apply quotas based on custom keys (e.g., client IP)

### Configuration

Quotas and rate limits are configured using the `quotas` parameter:

```json
"quotas": {
  "value": [
    {
      "name": "basic-quota",
      "description": "Basic tier quota",
      "calls": 1000,
      "renewalPeriod": "86400",
      "rateLimit": {
        "calls": 10,
        "renewalPeriod": "60"
      }
    }
  ]
}
```

### Policy Implementation

Quotas and rate limits are implemented as policy fragments that can be referenced in API policies. The system creates the following policy fragments:

- `{projectName}-{quotaName}-quota`
- `{projectName}-{quotaName}-rate-limit`
- `{projectName}-{quotaName}-quota-by-key`
- `{projectName}-{quotaName}-spike-arrest`

## Usage Tracking and Reporting

### Tracking Mechanisms

The system provides the following mechanisms for tracking API usage:

1. **Application Insights Integration**: Detailed logging of API calls
2. **Custom Dimensions**: Project-specific tracking dimensions
3. **Diagnostic Settings**: Configuration of logging detail level

### Configuration

Usage tracking is configured using the `usageTracking` parameter:

```json
"usageTracking": {
  "value": {
    "applicationInsightsId": "/subscriptions/.../microsoft.insights/components/app-insights",
    "applicationInsightsKey": "instrumentation-key",
    "apis": [
      {
        "name": "example-api",
        "alwaysLog": "allErrors",
        "logClientIp": true,
        "samplingPercentage": 100,
        "verbosity": "information",
        "requestHeaders": [
          "User-Agent",
          "Referer"
        ],
        "responseHeaders": [
          "Content-Type"
        ]
      }
    ]
  }
}
```

### Reporting

The system creates a policy fragment (`{projectName}-usage-tracking`) that adds custom dimensions to API calls for reporting purposes. These dimensions include:

- Project name
- Subscription ID
- Product ID
- API ID
- Operation ID
- User ID
- IP address
- Timestamp

## Notification Systems

### Notification Types

The system supports the following notification types:

1. **Subscription Creation**: Notifications when new subscriptions are created
2. **Subscription Cancellation**: Notifications when subscriptions are cancelled
3. **Quota Limit Approaching**: Notifications when usage approaches quota limits
4. **Webhook Integration**: Real-time notifications to external systems

### Configuration

Notifications are configured using the `notificationConfig` parameter:

```json
"notificationConfig": {
  "value": {
    "creationEmails": [
      "api-admin@example.com"
    ],
    "cancellationEmails": [
      "api-admin@example.com"
    ],
    "quotaEmails": [
      "api-admin@example.com"
    ],
    "webhookUrl": "https://example.com/api/subscription-events",
    "webhookCredential": "SharedAccessSignature sr=https%3A%2F%2Fexample.com&sig=XYZ789"
  }
}
```

### Webhook Payload

When a subscription event occurs, the following JSON payload is sent to the webhook:

```json
{
  "event": "subscription-activity",
  "projectName": "project-name",
  "subscriptionId": "subscription-id",
  "subscriptionName": "subscription-name",
  "productId": "product-id",
  "productName": "product-name",
  "userId": "user-id",
  "userEmail": "user@example.com",
  "timestamp": "2023-06-19T12:34:56.789Z"
}
```

## Configuration Examples

### Basic Configuration

```json
{
  "subscriptions": [
    {
      "name": "basic-subscription",
      "displayName": "Basic API Access",
      "productName": "example-product",
      "state": "active"
    }
  ]
}
```

### Complete Configuration

See the [subscription-management-sample.json](../infrastructure/bicep/templates/subscription-management-sample.json) file for a complete configuration example that includes all features of the subscription management system.

## Best Practices

1. **Use Namespacing**: Always use project-specific names for subscriptions and related resources
2. **Implement Approval Workflows**: For sensitive APIs, use approval workflows
3. **Set Appropriate Quotas**: Define quotas based on expected usage patterns
4. **Configure Usage Tracking**: Enable detailed tracking for important APIs
5. **Set Up Notifications**: Configure notifications for critical events
6. **Document Subscription Terms**: Clearly document the terms of use for each subscription
7. **Regular Auditing**: Periodically review active subscriptions and usage patterns

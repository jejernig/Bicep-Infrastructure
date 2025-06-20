@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing and access control')
param projectName string

@description('Notification configuration')
param notificationConfig object = {}

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create notification recipients for subscription creation
resource creationRecipient 'Microsoft.ApiManagement/service/notifications/recipientEmails@2021-08-01' = [for email in (contains(notificationConfig, 'creationEmails') ? notificationConfig.creationEmails : []): {
  name: '${apimName}/SubscriptionCreatedNotificationMessage/${email}'
}]

// Create notification recipients for subscription cancellation
resource cancellationRecipient 'Microsoft.ApiManagement/service/notifications/recipientEmails@2021-08-01' = [for email in (contains(notificationConfig, 'cancellationEmails') ? notificationConfig.cancellationEmails : []): {
  name: '${apimName}/SubscriptionCancelledNotificationMessage/${email}'
}]

// Create notification recipients for quota limit approaching
resource quotaRecipient 'Microsoft.ApiManagement/service/notifications/recipientEmails@2021-08-01' = [for email in (contains(notificationConfig, 'quotaEmails') ? notificationConfig.quotaEmails : []): {
  name: '${apimName}/QuotaLimitApproachingNotificationMessage/${email}'
}]

// Create webhook for subscription events if specified
resource webhookUrl 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = if (contains(notificationConfig, 'webhookUrl')) {
  name: '${apimName}/${projectName}-notification-webhook-url'
  properties: {
    displayName: '${projectName}-notification-webhook-url'
    value: notificationConfig.webhookUrl
    secret: true
  }
  tags: tags
}

// Create webhook credential if specified
resource webhookCredential 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = if (contains(notificationConfig, 'webhookCredential')) {
  name: '${apimName}/${projectName}-notification-webhook-credential'
  properties: {
    displayName: '${projectName}-notification-webhook-credential'
    value: notificationConfig.webhookCredential
    secret: true
  }
  tags: tags
}

// Create policy fragment for subscription event notification webhook
resource notificationWebhookFragment 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = if (contains(notificationConfig, 'webhookUrl')) {
  name: '${apimName}/${projectName}-subscription-notification-webhook'
  properties: {
    description: 'Subscription notification webhook for ${projectName}'
    format: 'xml'
    value: '''
<fragment>
  <choose>
    <when condition="@(context.Subscription != null && !String.IsNullOrEmpty(context.Subscription.Id))">
      <send-one-way-request mode="new" timeout="60" ignore-error="true">
        <set-url>{{${projectName}-notification-webhook-url}}</set-url>
        <set-method>POST</set-method>
        <set-header name="Content-Type" exists-action="override">
          <value>application/json</value>
        </set-header>
        <set-header name="Authorization" exists-action="override">
          <value>{{${projectName}-notification-webhook-credential}}</value>
        </set-header>
        <set-body>@{
          return new JObject(
            new JProperty("event", "subscription-activity"),
            new JProperty("projectName", "${projectName}"),
            new JProperty("subscriptionId", context.Subscription.Id),
            new JProperty("subscriptionName", context.Subscription.Name),
            new JProperty("productId", context.Product?.Id ?? "none"),
            new JProperty("productName", context.Product?.Name ?? "none"),
            new JProperty("userId", context.User?.Id ?? "anonymous"),
            new JProperty("userEmail", context.User?.Email ?? "anonymous"),
            new JProperty("timestamp", DateTime.UtcNow.ToString("o"))
          ).ToString();
        }</set-body>
      </send-one-way-request>
    </when>
  </choose>
</fragment>
'''
  }
  dependsOn: [
    webhookUrl
    webhookCredential
  ]
}

// Outputs
output creationRecipientIds array = [for (email, i) in (contains(notificationConfig, 'creationEmails') ? notificationConfig.creationEmails : []): {
  email: email
  id: creationRecipient[i].id
}]
output cancellationRecipientIds array = [for (email, i) in (contains(notificationConfig, 'cancellationEmails') ? notificationConfig.cancellationEmails : []): {
  email: email
  id: cancellationRecipient[i].id
}]
output quotaRecipientIds array = [for (email, i) in (contains(notificationConfig, 'quotaEmails') ? notificationConfig.quotaEmails : []): {
  email: email
  id: quotaRecipient[i].id
}]
output notificationWebhookFragmentId string = contains(notificationConfig, 'webhookUrl') ? notificationWebhookFragment.id : ''

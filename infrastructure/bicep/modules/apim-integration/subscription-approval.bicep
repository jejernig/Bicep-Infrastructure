@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing and access control')
param projectName string

@description('Subscription approval workflow configuration')
param approvalWorkflow object = {}

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create notification recipients for subscription approval
resource notificationRecipient 'Microsoft.ApiManagement/service/notifications/recipientEmails@2021-08-01' = [for email in (contains(approvalWorkflow, 'notificationEmails') ? approvalWorkflow.notificationEmails : []): {
  name: '${apimName}/RequestPublisherNotificationMessage/${email}'
}]

// Create notification recipients for subscription expiration
resource expirationRecipient 'Microsoft.ApiManagement/service/notifications/recipientEmails@2021-08-01' = [for email in (contains(approvalWorkflow, 'expirationEmails') ? approvalWorkflow.expirationEmails : []): {
  name: '${apimName}/SubscriptionExpiration/${email}'
}]

// Create a named value for approval webhook URL if specified
resource webhookUrl 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = if (contains(approvalWorkflow, 'webhookUrl')) {
  name: '${apimName}/${projectName}-approval-webhook-url'
  properties: {
    displayName: '${projectName}-approval-webhook-url'
    value: approvalWorkflow.webhookUrl
    secret: true
  }
  tags: tags
}

// Create a named value for approval webhook credentials if specified
resource webhookCredential 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = if (contains(approvalWorkflow, 'webhookCredential')) {
  name: '${apimName}/${projectName}-approval-webhook-credential'
  properties: {
    displayName: '${projectName}-approval-webhook-credential'
    value: approvalWorkflow.webhookCredential
    secret: true
  }
  tags: tags
}

// Create a policy fragment for subscription approval webhook
resource approvalWebhookFragment 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = if (contains(approvalWorkflow, 'webhookUrl')) {
  name: '${apimName}/${projectName}-subscription-approval-webhook'
  properties: {
    description: 'Subscription approval webhook for ${projectName}'
    format: 'xml'
    value: '''
<fragment>
  <send-request mode="new" response-variable-name="webhookResponse" timeout="60" ignore-error="true">
    <set-url>{{${projectName}-approval-webhook-url}}</set-url>
    <set-method>POST</set-method>
    <set-header name="Content-Type" exists-action="override">
      <value>application/json</value>
    </set-header>
    <set-header name="Authorization" exists-action="override">
      <value>{{${projectName}-approval-webhook-credential}}</value>
    </set-header>
    <set-body>@{
      return new JObject(
        new JProperty("event", "subscription-request"),
        new JProperty("projectName", "${projectName}"),
        new JProperty("subscriptionId", context.Subscription.Id),
        new JProperty("productId", context.Product.Id),
        new JProperty("productName", context.Product.Name),
        new JProperty("userId", context.User.Id),
        new JProperty("userEmail", context.User.Email),
        new JProperty("timestamp", DateTime.UtcNow.ToString("o"))
      ).ToString();
    }</set-body>
  </send-request>
</fragment>
'''
  }
  dependsOn: [
    webhookUrl
    webhookCredential
  ]
}

// Outputs
output notificationRecipientIds array = [for (email, i) in (contains(approvalWorkflow, 'notificationEmails') ? approvalWorkflow.notificationEmails : []): {
  email: email
  id: notificationRecipient[i].id
}]
output webhookFragmentId string = contains(approvalWorkflow, 'webhookUrl') ? approvalWebhookFragment.id : ''

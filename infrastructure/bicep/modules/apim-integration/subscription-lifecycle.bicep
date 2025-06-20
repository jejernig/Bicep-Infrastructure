@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing and access control')
param projectName string

@description('Subscription lifecycle configuration')
param lifecycleConfig object = {}

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create policy fragment for subscription expiration handling
resource expirationFragment 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = if (contains(lifecycleConfig, 'expirationHandling')) {
  name: '${apimName}/${projectName}-subscription-expiration'
  properties: {
    description: 'Subscription expiration handling for ${projectName}'
    format: 'xml'
    value: '''
<fragment>
  <choose>
    <when condition="@(context.Subscription != null && context.Subscription.ExpirationDate.HasValue && context.Subscription.ExpirationDate.Value < DateTime.UtcNow)">
      <return-response>
        <set-status code="403" reason="Subscription Expired" />
        <set-header name="Retry-After" exists-action="override">
          <value>3600</value>
        </set-header>
        <set-body>{"error": "subscription_expired", "message": "Your subscription has expired. Please renew your subscription to continue using this API."}</set-body>
      </return-response>
    </when>
  </choose>
</fragment>
'''
  }
}

// Create policy fragment for subscription renewal notification
resource renewalNotificationFragment 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = if (contains(lifecycleConfig, 'renewalNotification')) {
  name: '${apimName}/${projectName}-renewal-notification'
  properties: {
    description: 'Subscription renewal notification for ${projectName}'
    format: 'xml'
    value: '''
<fragment>
  <choose>
    <when condition="@(context.Subscription != null && context.Subscription.ExpirationDate.HasValue && context.Subscription.ExpirationDate.Value.Subtract(DateTime.UtcNow).TotalDays < ${lifecycleConfig.renewalNotification.daysBeforeExpiration})">
      <set-header name="X-Subscription-Expiring-Soon" exists-action="override">
        <value>@(context.Subscription.ExpirationDate.Value.ToString("o"))</value>
      </set-header>
    </when>
  </choose>
</fragment>
'''
  }
}

// Create policy fragment for subscription grace period
resource gracePeriodFragment 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = if (contains(lifecycleConfig, 'gracePeriod')) {
  name: '${apimName}/${projectName}-grace-period'
  properties: {
    description: 'Subscription grace period for ${projectName}'
    format: 'xml'
    value: '''
<fragment>
  <choose>
    <when condition="@(context.Subscription != null && context.Subscription.ExpirationDate.HasValue && context.Subscription.ExpirationDate.Value < DateTime.UtcNow && context.Subscription.ExpirationDate.Value.AddDays(${lifecycleConfig.gracePeriod.days}) > DateTime.UtcNow)">
      <set-header name="X-Subscription-Grace-Period" exists-action="override">
        <value>true</value>
      </set-header>
      <set-header name="X-Subscription-Grace-Period-Ends" exists-action="override">
        <value>@(context.Subscription.ExpirationDate.Value.AddDays(${lifecycleConfig.gracePeriod.days}).ToString("o"))</value>
      </set-header>
    </when>
  </choose>
</fragment>
'''
  }
}

// Create policy fragment for subscription revocation
resource revocationFragment 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = if (contains(lifecycleConfig, 'revocationHandling')) {
  name: '${apimName}/${projectName}-subscription-revocation'
  properties: {
    description: 'Subscription revocation handling for ${projectName}'
    format: 'xml'
    value: '''
<fragment>
  <choose>
    <when condition="@(context.Subscription != null && context.Subscription.State == "suspended")">
      <return-response>
        <set-status code="403" reason="Subscription Suspended" />
        <set-body>{"error": "subscription_suspended", "message": "Your subscription has been suspended. Please contact support for assistance."}</set-body>
      </return-response>
    </when>
  </choose>
</fragment>
'''
  }
}

// Outputs
output expirationFragmentId string = contains(lifecycleConfig, 'expirationHandling') ? expirationFragment.id : ''
output renewalNotificationFragmentId string = contains(lifecycleConfig, 'renewalNotification') ? renewalNotificationFragment.id : ''
output gracePeriodFragmentId string = contains(lifecycleConfig, 'gracePeriod') ? gracePeriodFragment.id : ''
output revocationFragmentId string = contains(lifecycleConfig, 'revocationHandling') ? revocationFragment.id : ''

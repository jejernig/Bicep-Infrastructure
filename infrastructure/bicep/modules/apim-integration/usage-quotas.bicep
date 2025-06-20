@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing and access control')
param projectName string

@description('Array of quota configurations')
param quotas array = []

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create quota policy fragments
resource quotaFragment 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = [for quota in quotas: {
  name: '${apimName}/${projectName}-${quota.name}-quota'
  properties: {
    description: contains(quota, 'description') ? quota.description : 'Usage quota for ${projectName} - ${quota.name}'
    format: 'xml'
    value: '''
<fragment>
  <quota calls="${quota.calls}" renewal-period="${quota.renewalPeriod}" counter-key="@(context.Subscription.Id)" />
</fragment>
'''
  }
}]

// Create rate limit policy fragments
resource rateLimitFragment 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = [for quota in quotas: if (contains(quota, 'rateLimit')) {
  name: '${apimName}/${projectName}-${quota.name}-rate-limit'
  properties: {
    description: contains(quota, 'description') ? quota.description : 'Rate limit for ${projectName} - ${quota.name}'
    format: 'xml'
    value: '''
<fragment>
  <rate-limit calls="${quota.rateLimit.calls}" renewal-period="${quota.rateLimit.renewalPeriod}" counter-key="@(context.Subscription.Id)" />
</fragment>
'''
  }
}]

// Create quota by key policy fragments for multi-tenant scenarios
resource quotaByKeyFragment 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = [for quota in quotas: if (contains(quota, 'quotaByKey')) {
  name: '${apimName}/${projectName}-${quota.name}-quota-by-key'
  properties: {
    description: contains(quota, 'description') ? quota.description : 'Usage quota by key for ${projectName} - ${quota.name}'
    format: 'xml'
    value: '''
<fragment>
  <quota-by-key calls="${quota.quotaByKey.calls}" 
                renewal-period="${quota.quotaByKey.renewalPeriod}" 
                counter-key="@(context.Request.Headers.GetValueOrDefault("${quota.quotaByKey.headerName}", ""))" />
</fragment>
'''
  }
}]

// Create spike arrest policy fragments for traffic shaping
resource spikeArrestFragment 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = [for quota in quotas: if (contains(quota, 'spikeArrest')) {
  name: '${apimName}/${projectName}-${quota.name}-spike-arrest'
  properties: {
    description: contains(quota, 'description') ? quota.description : 'Spike arrest for ${projectName} - ${quota.name}'
    format: 'xml'
    value: '''
<fragment>
  <rate-limit-by-key calls="${quota.spikeArrest.calls}" 
                     renewal-period="${quota.spikeArrest.renewalPeriod}" 
                     counter-key="@(context.Request.IpAddress)" />
</fragment>
'''
  }
}]

// Outputs
output quotaFragmentIds array = [for (quota, i) in quotas: {
  name: quota.name
  id: quotaFragment[i].id
}]
output rateLimitFragmentIds array = [for (quota, i) in quotas: if (contains(quota, 'rateLimit')) {
  name: quota.name
  id: rateLimitFragment[i].id
}]

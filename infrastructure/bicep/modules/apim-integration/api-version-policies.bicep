@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('API name')
param apiName string

@description('API version')
param apiVersion string

@description('Policy configuration for the API version')
param policy object = {}

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Reference the API
resource api 'Microsoft.ApiManagement/service/apis@2021-08-01' existing = {
  name: '${apimName}/${apiName}'
}

// Apply API policy
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = if (contains(policy, 'value')) {
  name: '${apimName}/${apiName}/policy'
  properties: {
    format: contains(policy, 'format') ? policy.format : 'xml'
    value: policy.value
  }
}

// Apply operation policies if specified
resource operationPolicies 'Microsoft.ApiManagement/service/apis/operations/policies@2021-08-01' = [for operation in (contains(policy, 'operations') ? policy.operations : []): {
  name: '${apimName}/${apiName}/${operation.name}/policy'
  properties: {
    format: contains(operation, 'format') ? operation.format : 'xml'
    value: operation.value
  }
}]

// Create API version set tag for documentation
resource apiVersionTag 'Microsoft.ApiManagement/service/apis/tags@2021-08-01' = {
  name: '${apimName}/${apiName}/version-${apiVersion}'
  properties: {
    displayName: 'Version ${apiVersion}'
  }
}

// Create lifecycle stage tag (current, deprecated, etc.)
resource lifecycleTag 'Microsoft.ApiManagement/service/apis/tags@2021-08-01' = if (contains(policy, 'lifecycleStage')) {
  name: '${apimName}/${apiName}/lifecycle-${policy.lifecycleStage}'
  properties: {
    displayName: toUpper(first(policy.lifecycleStage)) + substring(policy.lifecycleStage, 1)
  }
}

// Add deprecation header if API is deprecated
resource deprecationPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = if (contains(policy, 'lifecycleStage') && policy.lifecycleStage == 'deprecated') {
  name: '${apimName}/${apiName}/policy'
  properties: {
    format: 'xml'
    value: contains(policy, 'value') ? policy.value : '''
<policies>
  <inbound>
    <base />
    <set-header name="Deprecation" exists-action="override">
      <value>true</value>
    </set-header>
    <set-header name="Sunset" exists-action="override">
      <value>${contains(policy, 'endOfLifeDate') ? policy.endOfLifeDate : 'TBD'}</value>
    </set-header>
    <set-header name="Link" exists-action="override">
      <value><![CDATA[<${contains(policy, 'migrationDocUrl') ? policy.migrationDocUrl : 'https://developer.example.com/api-migration'}>; rel="deprecation"; type="text/html"]]></value>
    </set-header>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
'''
  }
}

// Outputs
output policyId string = contains(policy, 'value') ? apiPolicy.id : ''
output versionTagId string = apiVersionTag.id
output lifecycleTagId string = contains(policy, 'lifecycleStage') ? lifecycleTag.id : ''

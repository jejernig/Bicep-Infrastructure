@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Global policy XML content')
param policyContent string = '''
<policies>
  <inbound>
    <cors allow-credentials="true">
      <allowed-origins>
        <origin>https://*.example.com</origin>
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
    <set-header name="X-Request-ID" exists-action="skip">
      <value>@(context.RequestId)</value>
    </set-header>
    <base />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <set-header name="X-Powered-By" exists-action="delete" />
    <set-header name="X-AspNet-Version" exists-action="delete" />
    <set-header name="Server" exists-action="delete" />
    <base />
  </outbound>
  <on-error>
    <base />
    <set-header name="X-Error-ID" exists-action="override">
      <value>@(context.RequestId)</value>
    </set-header>
  </on-error>
</policies>
'''

@description('Format of the policy content (xml or xml-link)')
@allowed([
  'xml'
  'xml-link'
])
param policyFormat string = 'xml'

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Apply global policy
resource globalPolicy 'Microsoft.ApiManagement/service/policies@2021-08-01' = {
  name: '${apimName}/policy'
  properties: {
    format: policyFormat
    value: policyContent
  }
}

// Output
output policyId string = globalPolicy.id

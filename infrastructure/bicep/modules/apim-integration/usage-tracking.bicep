@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing and access control')
param projectName string

@description('Usage tracking configuration')
param usageTracking object = {}

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create logger for Application Insights
resource logger 'Microsoft.ApiManagement/service/loggers@2021-08-01' = if (contains(usageTracking, 'applicationInsightsId')) {
  name: '${apimName}/${projectName}-usage-logger'
  properties: {
    loggerType: 'applicationInsights'
    description: 'Usage tracking logger for ${projectName}'
    resourceId: usageTracking.applicationInsightsId
    credentials: {
      instrumentationKey: '{{${projectName}-usage-insights-key}}'
    }
  }
}

// Create named value for Application Insights key
resource appInsightsKey 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = if (contains(usageTracking, 'applicationInsightsKey')) {
  name: '${apimName}/${projectName}-usage-insights-key'
  properties: {
    displayName: '${projectName}-usage-insights-key'
    value: usageTracking.applicationInsightsKey
    secret: true
  }
  tags: tags
}

// Create diagnostic settings for APIs
resource apiDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2021-08-01' = [for api in (contains(usageTracking, 'apis') ? usageTracking.apis : []): {
  name: '${apimName}/${api.name}/applicationinsights'
  properties: {
    alwaysLog: contains(api, 'alwaysLog') ? api.alwaysLog : 'allErrors'
    httpCorrelationProtocol: contains(api, 'httpCorrelationProtocol') ? api.httpCorrelationProtocol : 'W3C'
    logClientIp: contains(api, 'logClientIp') ? api.logClientIp : true
    loggerId: logger.id
    sampling: {
      percentage: contains(api, 'samplingPercentage') ? api.samplingPercentage : 100
      samplingType: 'fixed'
    }
    verbosity: contains(api, 'verbosity') ? api.verbosity : 'information'
    frontend: {
      request: {
        headers: contains(api, 'requestHeaders') ? api.requestHeaders : []
        body: {
          bytes: contains(api, 'requestBodyBytes') ? api.requestBodyBytes : 0
        }
      }
      response: {
        headers: contains(api, 'responseHeaders') ? api.responseHeaders : []
        body: {
          bytes: contains(api, 'responseBodyBytes') ? api.responseBodyBytes : 0
        }
      }
    }
    backend: {
      request: {
        headers: contains(api, 'backendRequestHeaders') ? api.backendRequestHeaders : []
        body: {
          bytes: contains(api, 'backendRequestBodyBytes') ? api.backendRequestBodyBytes : 0
        }
      }
      response: {
        headers: contains(api, 'backendResponseHeaders') ? api.backendResponseHeaders : []
        body: {
          bytes: contains(api, 'backendResponseBodyBytes') ? api.backendResponseBodyBytes : 0
        }
      }
    }
  }
  dependsOn: [
    logger
    appInsightsKey
  ]
}]

// Create usage tracking policy fragment
resource usageTrackingFragment 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = {
  name: '${apimName}/${projectName}-usage-tracking'
  properties: {
    description: 'Usage tracking policy for ${projectName}'
    format: 'xml'
    value: '''
<fragment>
  <trace source="API Management" severity="information">
    <message>@{
      return new JObject(
        new JProperty("projectName", "${projectName}"),
        new JProperty("subscriptionId", context.Subscription?.Id ?? "none"),
        new JProperty("productId", context.Product?.Id ?? "none"),
        new JProperty("apiId", context.Api.Id),
        new JProperty("operationId", context.Operation.Id),
        new JProperty("userId", context.User?.Id ?? "anonymous"),
        new JProperty("ipAddress", context.Request.IpAddress),
        new JProperty("timestamp", DateTime.UtcNow.ToString("o"))
      ).ToString();
    }</message>
    <metadata name="Correlation-Id" value="@(context.RequestId)" />
  </trace>
</fragment>
'''
  }
}

// Outputs
output loggerId string = contains(usageTracking, 'applicationInsightsId') ? logger.id : ''
output usageTrackingFragmentId string = usageTrackingFragment.id

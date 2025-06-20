@description('Name of the API Management service')
param apimName string

@description('Resource group of the API Management service (for cross-resource group scenarios)')
param apimResourceGroup string = resourceGroup().name

@description('Project name used for namespacing and access control')
param projectName string

@description('Policy configuration for the project')
param policyConfig object = {}

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Reference the APIM instance
resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimName
  scope: resourceGroup(apimResourceGroup)
}

// Create a named value for project namespace
resource projectNamespace 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  name: '${apimName}/${projectName}-namespace'
  properties: {
    displayName: '${projectName}-namespace'
    value: projectName
    secret: false
  }
  tags: tags
}

// Create project-specific policy fragments
resource policyFragments 'Microsoft.ApiManagement/service/policyFragments@2021-08-01' = [for fragment in contains(policyConfig, 'fragments') ? policyConfig.fragments : []: {
  name: '${apimName}/${projectName}-${fragment.name}'
  properties: {
    description: contains(fragment, 'description') ? fragment.description : 'Policy fragment for ${projectName}'
    format: contains(fragment, 'format') ? fragment.format : 'xml'
    value: fragment.value
  }
}]

// Create project-specific diagnostic settings
resource diagnosticSettings 'Microsoft.ApiManagement/service/diagnostics@2021-08-01' = if (contains(policyConfig, 'diagnostics')) {
  name: '${apimName}/${projectName}-applicationinsights'
  properties: {
    alwaysLog: contains(policyConfig.diagnostics, 'alwaysLog') ? policyConfig.diagnostics.alwaysLog : 'allErrors'
    httpCorrelationProtocol: contains(policyConfig.diagnostics, 'httpCorrelationProtocol') ? policyConfig.diagnostics.httpCorrelationProtocol : 'W3C'
    logClientIp: contains(policyConfig.diagnostics, 'logClientIp') ? policyConfig.diagnostics.logClientIp : true
    sampling: {
      percentage: contains(policyConfig.diagnostics, 'samplingPercentage') ? policyConfig.diagnostics.samplingPercentage : 100
      samplingType: 'fixed'
    }
    frontend: {
      request: {
        headers: contains(policyConfig.diagnostics, 'requestHeaders') ? policyConfig.diagnostics.requestHeaders : []
        body: {
          bytes: contains(policyConfig.diagnostics, 'requestBodyBytes') ? policyConfig.diagnostics.requestBodyBytes : 0
        }
      }
      response: {
        headers: contains(policyConfig.diagnostics, 'responseHeaders') ? policyConfig.diagnostics.responseHeaders : []
        body: {
          bytes: contains(policyConfig.diagnostics, 'responseBodyBytes') ? policyConfig.diagnostics.responseBodyBytes : 0
        }
      }
    }
    backend: {
      request: {
        headers: contains(policyConfig.diagnostics, 'backendRequestHeaders') ? policyConfig.diagnostics.backendRequestHeaders : []
        body: {
          bytes: contains(policyConfig.diagnostics, 'backendRequestBodyBytes') ? policyConfig.diagnostics.backendRequestBodyBytes : 0
        }
      }
      response: {
        headers: contains(policyConfig.diagnostics, 'backendResponseHeaders') ? policyConfig.diagnostics.backendResponseHeaders : []
        body: {
          bytes: contains(policyConfig.diagnostics, 'backendResponseBodyBytes') ? policyConfig.diagnostics.backendResponseBodyBytes : 0
        }
      }
    }
  }
}

// Create project-specific logger (if Application Insights is provided)
resource logger 'Microsoft.ApiManagement/service/loggers@2021-08-01' = if (contains(policyConfig, 'applicationInsightsId')) {
  name: '${apimName}/${projectName}-appinsights'
  properties: {
    loggerType: 'applicationInsights'
    description: 'Application Insights logger for ${projectName}'
    resourceId: policyConfig.applicationInsightsId
    credentials: {
      instrumentationKey: '{{${projectName}-appinsights-key}}'
    }
  }
}

// Create named value for Application Insights key (if provided)
resource appInsightsKey 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = if (contains(policyConfig, 'applicationInsightsKey')) {
  name: '${apimName}/${projectName}-appinsights-key'
  properties: {
    displayName: '${projectName}-appinsights-key'
    value: policyConfig.applicationInsightsKey
    secret: true
  }
  tags: tags
}

// Outputs
output namespaceId string = projectNamespace.id
output fragmentIds array = [for (fragment, i) in (contains(policyConfig, 'fragments') ? policyConfig.fragments : []): {
  name: fragment.name
  id: policyFragments[i].id
}]
output diagnosticId string = contains(policyConfig, 'diagnostics') ? diagnosticSettings.id : ''
output loggerId string = contains(policyConfig, 'applicationInsightsId') ? logger.id : ''

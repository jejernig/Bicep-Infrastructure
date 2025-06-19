@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Container group ID to monitor')
param containerGroupId string

@description('Tags to apply to the resources')
param tags object = {}

@description('Number of days to retain data in Log Analytics')
param retentionInDays int = 30

@description('Alert email addresses (comma-separated)')
param alertEmailAddresses string = ''

@description('Enable diagnostic settings')
param enableDiagnostics bool = true

// Create Log Analytics workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

// Create Action Group for alerts
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = if (!empty(alertEmailAddresses)) {
  name: '${workspaceName}-action-group'
  location: 'global'
  properties: {
    groupShortName: 'MCP-Alerts'
    enabled: true
    emailReceivers: [for email in split(alertEmailAddresses, ','): {
      name: 'Email-${index(split(alertEmailAddresses, ','), email)}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
  }
}

// Create diagnostic settings for container group
resource containerDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: '${workspaceName}-diagnostics'
  scope: resourceId('Microsoft.ContainerInstance/containerGroups', last(split(containerGroupId, '/')))
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'ContainerInstanceLog'
        enabled: true
      }
      {
        category: 'ContainerEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Create CPU usage alert
resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (!empty(alertEmailAddresses)) {
  name: '${workspaceName}-cpu-alert'
  location: 'global'
  properties: {
    description: 'Alert when CPU usage exceeds 80%'
    severity: 2
    enabled: true
    scopes: [
      containerGroupId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CPU Usage'
          metricName: 'CpuUsage'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: !empty(alertEmailAddresses) ? [
      {
        actionGroupId: actionGroup.id
      }
    ] : []
  }
}

// Create Memory usage alert
resource memoryAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (!empty(alertEmailAddresses)) {
  name: '${workspaceName}-memory-alert'
  location: 'global'
  properties: {
    description: 'Alert when memory usage exceeds 85%'
    severity: 2
    enabled: true
    scopes: [
      containerGroupId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Memory Usage'
          metricName: 'MemoryUsage'
          operator: 'GreaterThan'
          threshold: 85
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: !empty(alertEmailAddresses) ? [
      {
        actionGroupId: actionGroup.id
      }
    ] : []
  }
}

// Create container restart count alert
resource restartAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (!empty(alertEmailAddresses)) {
  name: '${workspaceName}-restart-alert'
  location: 'global'
  properties: {
    description: 'Alert when container restarts occur'
    severity: 1
    enabled: true
    scopes: [
      containerGroupId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Container Restarts'
          metricName: 'RestartCount'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: !empty(alertEmailAddresses) ? [
      {
        actionGroupId: actionGroup.id
      }
    ] : []
  }
}

output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name

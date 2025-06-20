@description('Name of the Application Insights instance')
param appInsightsName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Type of application being monitored')
param applicationType string = 'web'

@description('Retention period in days')
param retentionInDays int = 90

@description('Daily data cap in GB')
param dailyQuotaInGB int = 0

@description('Enable public network access for ingestion')
param publicNetworkAccessForIngestion string = 'Enabled'

@description('Enable public network access for query')
param publicNetworkAccessForQuery string = 'Enabled'

@description('Tags to apply to resources')
param tags object = {}

// Create Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: applicationType
    Flow_Type: 'Redfield'
    Request_Source: 'rest'
    RetentionInDays: retentionInDays
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
    SamplingPercentage: 100
    DisableIpMasking: false
    WorkspaceResourceId: null // Can be set to a Log Analytics workspace ID if needed
    IngestionMode: 'ApplicationInsights'
    DisableLocalAuth: false
  }
}

// Create daily cap alert if a cap is specified
resource dailyCapAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = if (dailyQuotaInGB > 0) {
  name: '${appInsightsName}-daily-cap-alert'
  location: location
  tags: tags
  properties: {
    displayName: 'Daily Cap Alert'
    description: 'Alert when daily data cap is approaching'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT1H'
    scopes: [
      appInsights.id
    ]
    windowSize: 'PT1H'
    criteria: {
      allOf: [
        {
          query: 'union customEvents, pageViews, browserTimings, requests, dependencies, exceptions, traces, performanceCounters, availabilityResults | where timestamp > ago(24h) | summarize count()'
          timeAggregation: 'Total'
          metricMeasureColumn: 'count_'
          operator: 'GreaterThan'
          threshold: dailyQuotaInGB * 0.8 * 1000000 // 80% of daily quota in bytes
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: []
    }
  }
}

// Outputs
output appInsightsId string = appInsights.id
output appInsightsName string = appInsights.name
output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString

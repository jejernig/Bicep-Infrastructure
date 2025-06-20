@description('Name of the hosting plan')
param hostingPlanName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('SKU for the hosting plan')
@allowed([
  'Y1'    // Consumption
  'EP1'   // Premium
  'EP2'   // Premium
  'EP3'   // Premium
  'B1'    // Basic
  'B2'    // Basic
  'B3'    // Basic
  'S1'    // Standard
  'S2'    // Standard
  'S3'    // Standard
  'P1v2'  // PremiumV2
  'P2v2'  // PremiumV2
  'P3v2'  // PremiumV2
  'P1v3'  // PremiumV3
  'P2v3'  // PremiumV3
  'P3v3'  // PremiumV3
])
param sku string = 'Y1'

@description('OS type (Windows or Linux)')
@allowed([
  'Windows'
  'Linux'
])
param osType string = 'Windows'

@description('Number of instances')
param capacity int = 0

@description('Enable zone redundancy')
param zoneRedundant bool = false

@description('Enable autoscale')
param enableAutoscale bool = false

@description('Minimum instance count for autoscale')
param minInstanceCount int = 1

@description('Maximum instance count for autoscale')
param maxInstanceCount int = 10

@description('Default instance count for autoscale')
param defaultInstanceCount int = 1

@description('Tags to apply to resources')
param tags object = {}

// Determine if this is a consumption plan
var isConsumptionPlan = sku == 'Y1'

// Determine if this is a premium plan
var isPremiumPlan = startsWith(sku, 'EP')

// Create the hosting plan
resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: capacity > 0 ? capacity : null
  }
  kind: osType == 'Windows' ? 'functionapp' : 'linux'
  properties: {
    reserved: osType == 'Linux'
    zoneRedundant: zoneRedundant
    targetWorkerCount: capacity > 0 ? capacity : null
    targetWorkerSizeId: null
    elasticScaleEnabled: isPremiumPlan
    maximumElasticWorkerCount: isPremiumPlan ? maxInstanceCount : null
  }
}

// Create autoscale settings if enabled and not a consumption plan
resource autoscaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (enableAutoscale && !isConsumptionPlan) {
  name: '${hostingPlanName}-autoscale'
  location: location
  tags: tags
  properties: {
    name: '${hostingPlanName}-autoscale'
    enabled: true
    targetResourceUri: hostingPlan.id
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: minInstanceCount
          maximum: maxInstanceCount
          default: defaultInstanceCount
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'microsoft.web/serverfarms'
              metricResourceUri: hostingPlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT10M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'microsoft.web/serverfarms'
              metricResourceUri: hostingPlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT10M'
            }
          }
        ]
      }
    ]
    predictiveAutoscalePolicy: {
      scaleMode: 'Disabled'
    }
  }
  dependsOn: [
    hostingPlan
  ]
}

// Outputs
output hostingPlanId string = hostingPlan.id
output hostingPlanName string = hostingPlan.name
output sku string = sku
output isConsumptionPlan bool = isConsumptionPlan
output isPremiumPlan bool = isPremiumPlan

@description('The name of the Service Bus namespace')
param namespaceName string

@description('The location for all resources')
param location string = resourceGroup().location

@description('The SKU of the Service Bus namespace')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Standard'

@description('The capacity (throughput units) of the Service Bus namespace (only for Premium SKU)')
@minValue(1)
@maxValue(16)
param capacity int = 1

@description('Whether or not this namespace requires infrastructure encryption')
param enableInfrastructureEncryption bool = false

@description('The minimum TLS version for the namespace')
@allowed([
  '1.0'
  '1.1'
  '1.2'
])
param minimumTlsVersion string = '1.2'

@description('Whether or not network rule set is enabled')
param publicNetworkAccess string = 'Enabled'

@description('Configuration for queues in the Service Bus namespace')
param queues array = []

@description('Configuration for topics in the Service Bus namespace')
param topics array = []

@description('Configuration for authorization rules')
param authorizationRules array = []

// Deploy the Service Bus namespace with queues and topics
module serviceBus './service-bus.bicep' = {
  name: 'service-bus-deployment'
  params: {
    namespaceName: namespaceName
    location: location
    sku: sku
    capacity: capacity
    enableInfrastructureEncryption: enableInfrastructureEncryption
    minimumTlsVersion: minimumTlsVersion
    publicNetworkAccess: publicNetworkAccess
    queues: queues
    topics: topics
  }
}

// Deploy authorization rules
module authRules './authorization-rules.bicep' = [for rule in authorizationRules: {
  name: 'auth-rule-${replace(rule.name, '/[^\w-]/', '-')}'
  scope: resourceGroup()
  params: {
    namespaceName: namespaceName
    parentResourceName: rule.parentResourceName
    parentResourceType: rule.parentResourceType
    ruleName: rule.name
    rights: rule.rights
  }
}]

// Outputs from the Service Bus deployment
output namespaceName string = serviceBus.outputs.namespaceName
output namespacePrimaryConnectionString string = serviceBus.outputs.namespacePrimaryConnectionString
output namespacePrimaryKey string = serviceBus.outputs.namespacePrimaryKey
output namespaceSecondaryConnectionString string = serviceBus.outputs.namespaceSecondaryConnectionString
output namespaceSecondaryKey string = serviceBus.outputs.namespaceSecondaryKey
output queueNames array = serviceBus.outputs.queueNames
output topicNames array = serviceBus.outputs.topicNames

// Outputs from authorization rules
output authorizationRuleOutputs array = [for rule in authRules: {
  name: rule.name
  primaryConnectionString: rule.outputs.primaryConnectionString
  primaryKey: rule.outputs.primaryKey
  secondaryConnectionString: rule.outputs.secondaryConnectionString
  secondaryKey: rule.outputs.secondaryKey
}]

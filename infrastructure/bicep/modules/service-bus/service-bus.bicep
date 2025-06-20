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

// Service Bus Namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: namespaceName
  location: location
  sku: {
    name: sku
    tier: sku
    capacity: contains('Premium', sku) ? capacity : null
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    minimumTlsVersion: minimumTlsVersion
    publicNetworkAccess: publicNetworkAccess
    zoneRedundant: sku == 'Premium' ? true : false
    encryption: {
      keyVaultProperties: []
      keySource: 'Microsoft.KeyVault'
      requireInfrastructureEncryption: enableInfrastructureEncryption
    }
  }
}

// Queues
@batchSize(1)
resource serviceBusQueues 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = [for (queue, index) in queues: {
  name: queue.name
  parent: serviceBusNamespace
  properties: {
    lockDuration: queue.lockDuration ?? 'PT5M'
    maxSizeInMegabytes: queue.maxSizeInMegabytes ?? 1024
    requiresDuplicateDetection: queue.requiresDuplicateDetection ?? false
    requiresSession: queue.requiresSession ?? false
    defaultMessageTimeToLive: queue.defaultMessageTimeToLive ?? 'P14D'
    deadLetteringOnMessageExpiration: queue.deadLetteringOnMessageExpiration ?? false
    duplicateDetectionHistoryTimeWindow: queue.duplicateDetectionHistoryTimeWindow ?? 'PT10M'
    maxDeliveryCount: queue.maxDeliveryCount ?? 10
    enableBatchedOperations: queue.enableBatchedOperations ?? true
    status: queue.status ?? 'Active'
    enablePartitioning: queue.enablePartitioning ?? (sku == 'Premium' ? false : true)
    maxMessageSizeInKilobytes: sku == 'Premium' ? (queue.maxMessageSizeInKilobytes ?? 1024) : 1024
  }
}]

// Topics
@batchSize(1)
resource serviceBusTopics 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = [for (topic, index) in topics: {
  name: topic.name
  parent: serviceBusNamespace
  properties: {
    defaultMessageTimeToLive: topic.defaultMessageTimeToLive ?? 'P14D'
    maxSizeInMegabytes: topic.maxSizeInMegabytes ?? 1024
    requiresDuplicateDetection: topic.requiresDuplicateDetection ?? false
    duplicateDetectionHistoryTimeWindow: topic.duplicateDetectionHistoryTimeWindow ?? 'PT10M'
    enableBatchedOperations: topic.enableBatchedOperations ?? true
    status: topic.status ?? 'Active'
    supportOrdering: topic.supportOrdering ?? true
    enablePartitioning: topic.enablePartitioning ?? (sku == 'Premium' ? false : true)
    maxMessageSizeInKilobytes: sku == 'Premium' ? (topic.maxMessageSizeInKilobytes ?? 1024) : 1024
  }
}]

// Subscriptions for each topic
@batchSize(1)
resource serviceBusSubscriptions 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = [for (topic, topicIndex) in topics: {
  name: '${topic.name}-subscription-${subscriptionIndex + 1}'
  parent: serviceBusTopics[topicIndex]
  properties: {
    lockDuration: subscription.lockDuration ?? 'PT1M'
    requiresSession: subscription.requiresSession ?? false
    defaultMessageTimeToLive: subscription.defaultMessageTimeToLive ?? 'P14D'
    deadLetteringOnMessageExpiration: subscription.deadLetteringOnMessageExpiration ?? false
    maxDeliveryCount: subscription.maxDeliveryCount ?? 10
    enableBatchedOperations: subscription.enableBatchedOperations ?? true
    status: subscription.status ?? 'Active'
    forwardTo: subscription.forwardTo ?? ''
    forwardDeadLetteredMessagesTo: subscription.forwardDeadLetteredMessagesTo ?? ''
  }
} for subscription in topic.subscriptions ?? []]

// Outputs
output namespaceName string = serviceBusNamespace.name
output namespacePrimaryConnectionString string = serviceBusNamespace.listKeys(serviceBusNamespace.name, 'RootManageSharedAccessKey').primaryConnectionString
output namespacePrimaryKey string = serviceBusNamespace.listKeys(serviceBusNamespace.name, 'RootManageSharedAccessKey').primaryKey
output namespaceSecondaryConnectionString string = serviceBusNamespace.listKeys(serviceBusNamespace.name, 'RootManageSharedAccessKey').secondaryConnectionString
output namespaceSecondaryKey string = serviceBusNamespace.listKeys(serviceBusNamespace.name, 'RootManageSharedAccessKey').secondaryKey
output queueNames array = [for queue in serviceBusQueues: queue.name]
topicNames array = [for topic in serviceBusTopics: topic.name]

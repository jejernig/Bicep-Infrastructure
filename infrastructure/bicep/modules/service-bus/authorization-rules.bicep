@description('The name of the Service Bus namespace')
param namespaceName string

@description('The name of the parent resource (queue or topic)')
param parentResourceName string

@description('The type of parent resource (queue or topic)')
@allowed([
  'queues'
  'topics'
])
param parentResourceType string

@description('The name of the rule')
param ruleName string

@description('The rights to be granted by this rule')
@allowed([
  'Listen'
  'Send'
  'Manage'
  'Listen, Send'
  'Listen, Manage'
  'Send, Manage'
  'Listen, Send, Manage'
])
param rights string

@description('The type of the authorization rule')
@allowed([
  'SharedAccessAuthorizationRule'
])
param type string = 'SharedAccessAuthorizationRule'

resource authorizationRule 'Microsoft.ServiceBus/namespaces/authorizationRules@2022-10-01-preview' = if (parentResourceType == 'namespaces') {
  name: ruleName
  parent: parent
  properties: {
    rights: split(rights, ', ')
  }
}

resource queueAuthorizationRule 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-10-01-preview' = if (parentResourceType == 'queues') {
  name: ruleName
  parent: parent
  properties: {
    rights: split(rights, ', ')
  }
}

resource topicAuthorizationRule 'Microsoft.ServiceBus/namespaces/topics/authorizationRules@2022-10-01-preview' = if (parentResourceType == 'topics') {
  name: ruleName
  parent: parent
  properties: {
    rights: split(rights, ', ')
  }
}

// Outputs
output primaryConnectionString string = parentResourceType == 'namespaces' 
  ? listKeys(authorizationRule.name, authorizationRule.id).primaryConnectionString 
  : parentResourceType == 'queues' 
    ? listKeys(queueAuthorizationRule.name, queueAuthorizationRule.id, queueAuthorizationRule.apiVersion).primaryConnectionString
    : listKeys(topicAuthorizationRule.name, topicAuthorizationRule.id, topicAuthorizationRule.apiVersion).primaryConnectionString

output primaryKey string = parentResourceType == 'namespaces'
  ? listKeys(authorizationRule.name, authorizationRule.id).primaryKey
  : parentResourceType == 'queues'
    ? listKeys(queueAuthorizationRule.name, queueAuthorizationRule.id, queueAuthorizationRule.apiVersion).primaryKey
    : listKeys(topicAuthorizationRule.name, topicAuthorizationRule.id, topicAuthorizationRule.apiVersion).primaryKey

output secondaryConnectionString string = parentResourceType == 'namespaces'
  ? listKeys(authorizationRule.name, authorizationRule.id).secondaryConnectionString
  : parentResourceType == 'queues'
    ? listKeys(queueAuthorizationRule.name, queueAuthorizationRule.id, queueAuthorizationRule.apiVersion).secondaryConnectionString
    : listKeys(topicAuthorizationRule.name, topicAuthorizationRule.id, topicAuthorizationRule.apiVersion).secondaryConnectionString

output secondaryKey string = parentResourceType == 'namespaces'
  ? listKeys(authorizationRule.name, authorizationRule.id).secondaryKey
  : parentResourceType == 'queues'
    ? listKeys(queueAuthorizationRule.name, queueAuthorizationRule.id, queueAuthorizationRule.apiVersion).secondaryKey
    : listKeys(topicAuthorizationRule.name, topicAuthorizationRule.id, topicAuthorizationRule.apiVersion).secondaryKey

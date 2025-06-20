@description('Name of the SQL Server')
param sqlServerName string

@description('Array of virtual network rules')
param virtualNetworkRules array = []

// Reference the SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

// Create virtual network rules
resource vnetRule 'Microsoft.Sql/servers/virtualNetworkRules@2022-05-01-preview' = [for rule in virtualNetworkRules: {
  parent: sqlServer
  name: contains(rule, 'name') ? rule.name : '${last(split(rule.subnetId, '/'))}-rule'
  properties: {
    virtualNetworkSubnetId: rule.subnetId
    ignoreMissingVnetServiceEndpoint: contains(rule, 'ignoreMissingVnetServiceEndpoint') ? rule.ignoreMissingVnetServiceEndpoint : false
  }
}]

// Outputs
output virtualNetworkRulesCount int = length(virtualNetworkRules)

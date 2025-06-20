@description('Name of the SQL Server')
param sqlServerName string

@description('Allow Azure services and resources to access the server')
param allowAzureServices bool = true

@description('Array of firewall rules')
param firewallRules array = []

// Reference the SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

// Allow Azure services and resources to access the server
resource allowAllAzureIPs 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = if (allowAzureServices) {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Create firewall rules
resource firewallRule 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = [for rule in firewallRules: {
  parent: sqlServer
  name: rule.name
  properties: {
    startIpAddress: rule.startIpAddress
    endIpAddress: rule.endIpAddress
  }
}]

// Outputs
output firewallRulesCount int = length(firewallRules)
output allowAzureServices bool = allowAzureServices

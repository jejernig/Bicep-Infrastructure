@description('Name of the SQL Server')
param sqlServerName string

@description('Name of the SQL Database')
param sqlDatabaseName string

@description('Long-term retention policy')
param longTermRetentionPolicy object = {
  weeklyRetention: 'P1M'
  monthlyRetention: 'P1Y'
  yearlyRetention: 'P5Y'
  weekOfYear: 1
}

@description('Short-term retention policy')
param shortTermRetentionPolicy object = {
  retentionDays: 7
  diffBackupIntervalInHours: 24
}

// Reference the SQL Server and Database
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' existing = {
  parent: sqlServer
  name: sqlDatabaseName
}

// Configure long-term retention policy
resource longTermRetention 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2022-05-01-preview' = {
  parent: sqlDatabase
  name: 'default'
  properties: {
    weeklyRetention: longTermRetentionPolicy.weeklyRetention
    monthlyRetention: longTermRetentionPolicy.monthlyRetention
    yearlyRetention: longTermRetentionPolicy.yearlyRetention
    weekOfYear: longTermRetentionPolicy.weekOfYear
  }
}

// Configure short-term retention policy
resource shortTermRetention 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2022-05-01-preview' = {
  parent: sqlDatabase
  name: 'default'
  properties: {
    retentionDays: shortTermRetentionPolicy.retentionDays
    diffBackupIntervalInHours: shortTermRetentionPolicy.diffBackupIntervalInHours
  }
}

// Outputs
output longTermRetentionWeekly string = longTermRetention.properties.weeklyRetention
output longTermRetentionMonthly string = longTermRetention.properties.monthlyRetention
output longTermRetentionYearly string = longTermRetention.properties.yearlyRetention
output shortTermRetentionDays int = shortTermRetention.properties.retentionDays

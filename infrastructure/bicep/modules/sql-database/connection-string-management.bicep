@description('Name of the SQL Server')
param sqlServerName string

@description('Name of the SQL Database')
param sqlDatabaseName string

@description('Key Vault name to store connection strings')
param keyVaultName string = ''

@description('Secret name for the connection string in Key Vault')
param connectionStringSecretName string = '${sqlServerName}-${sqlDatabaseName}-ConnectionString'

@description('SQL Server admin username')
@secure()
param administratorLogin string = ''

@description('SQL Server admin password')
@secure()
param administratorLoginPassword string = ''

@description('Use managed identity for authentication')
param useManagedIdentity bool = false

@description('Connection string type')
@allowed([
  'ADO.NET'
  'JDBC'
  'ODBC'
  'PHP'
  'PHP PDO'
  'Python'
  'Ruby'
])
param connectionStringType string = 'ADO.NET'

@description('Output connection string')
param outputConnectionString bool = false

// Reference the SQL Server and Database
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' existing = {
  parent: sqlServer
  name: sqlDatabaseName
}

// Reference Key Vault if provided
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!empty(keyVaultName)) {
  name: keyVaultName
}

// Generate connection string based on type
var baseConnectionString = {
  'ADO.NET': 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabaseName};'
  'JDBC': 'jdbc:sqlserver://${sqlServer.properties.fullyQualifiedDomainName}:1433;database=${sqlDatabaseName};'
  'ODBC': 'Driver={ODBC Driver 17 for SQL Server};Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlDatabaseName};'
  'PHP': 'sqlsrv:Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlDatabaseName}'
  'PHP PDO': 'sqlsrv:Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlDatabaseName}'
  'Python': 'Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlDatabaseName};'
  'Ruby': 'Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlDatabaseName};'
}[connectionStringType]

var authConnectionString = useManagedIdentity ? {
  'ADO.NET': '${baseConnectionString}Authentication=Active Directory Managed Identity;'
  'JDBC': '${baseConnectionString}authentication=ActiveDirectoryMSI;'
  'ODBC': '${baseConnectionString}Authentication=ActiveDirectoryMSI;'
  'PHP': '${baseConnectionString};Authentication=ActiveDirectoryMSI'
  'PHP PDO': '${baseConnectionString};Authentication=ActiveDirectoryMSI'
  'Python': '${baseConnectionString}Authentication=ActiveDirectoryMSI;'
  'Ruby': '${baseConnectionString}Authentication=ActiveDirectoryMSI;'
}[connectionStringType] : {
  'ADO.NET': '${baseConnectionString}User ID=${administratorLogin};Password=${administratorLoginPassword};'
  'JDBC': '${baseConnectionString}user=${administratorLogin};password=${administratorLoginPassword};'
  'ODBC': '${baseConnectionString}Uid=${administratorLogin};Pwd=${administratorLoginPassword};'
  'PHP': '${baseConnectionString};UID=${administratorLogin};PWD=${administratorLoginPassword}'
  'PHP PDO': '${baseConnectionString};UID=${administratorLogin};PWD=${administratorLoginPassword}'
  'Python': '${baseConnectionString}UID=${administratorLogin};PWD=${administratorLoginPassword};'
  'Ruby': '${baseConnectionString}UID=${administratorLogin};PWD=${administratorLoginPassword};'
}[connectionStringType]

var finalConnectionString = {
  'ADO.NET': '${authConnectionString}Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  'JDBC': '${authConnectionString}encrypt=true;trustServerCertificate=false;'
  'ODBC': '${authConnectionString}Encrypt=YES;TrustServerCertificate=NO;'
  'PHP': '${authConnectionString};Encrypt=1;TrustServerCertificate=0'
  'PHP PDO': '${authConnectionString};Encrypt=1;TrustServerCertificate=0'
  'Python': '${authConnectionString}Encrypt=yes;TrustServerCertificate=no;'
  'Ruby': '${authConnectionString}Encrypt=true;TrustServerCertificate=false;'
}[connectionStringType]

// Store connection string in Key Vault if provided
resource connectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = if (!empty(keyVaultName)) {
  parent: keyVault
  name: connectionStringSecretName
  properties: {
    value: finalConnectionString
    contentType: 'text/plain'
  }
}

// Outputs
output connectionStringSecretUri string = !empty(keyVaultName) ? connectionStringSecret.properties.secretUri : ''
output connectionStringSecretName string = !empty(keyVaultName) ? connectionStringSecret.name : ''
output connectionString string = outputConnectionString ? finalConnectionString : ''

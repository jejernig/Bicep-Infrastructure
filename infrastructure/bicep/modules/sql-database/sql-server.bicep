@description('Name of the SQL Server')
param sqlServerName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('Administrator login name')
param administratorLogin string

@description('Administrator login password')
@secure()
param administratorLoginPassword string

@description('Azure AD administrator configuration')
param aadAdministrator object = {}

@description('Enable or disable Azure AD-only authentication')
param azureADOnlyAuthentication bool = false

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
  'SecuredByPerimeter'
])
param publicNetworkAccess string = 'Enabled'

@description('Minimal TLS version')
@allowed([
  '1.0'
  '1.1'
  '1.2'
])
param minimalTlsVersion string = '1.2'

@description('Enable or disable system managed identity')
param systemAssignedIdentity bool = false

@description('User assigned identities')
param userAssignedIdentities object = {}

@description('Tags to apply to resources')
param tags object = {}

// Determine identity type
var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

// Create SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: '12.0'
    minimalTlsVersion: minimalTlsVersion
    publicNetworkAccess: publicNetworkAccess
    administrators: !empty(aadAdministrator) ? {
      administratorType: 'ActiveDirectory'
      principalType: contains(aadAdministrator, 'principalType') ? aadAdministrator.principalType : 'User'
      login: aadAdministrator.login
      sid: aadAdministrator.sid
      tenantId: contains(aadAdministrator, 'tenantId') ? aadAdministrator.tenantId : subscription().tenantId
      azureADOnlyAuthentication: azureADOnlyAuthentication
    } : null
  }
  identity: identityType != 'None' ? {
    type: identityType
    userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
  } : null
}

// Outputs
output sqlServerId string = sqlServer.id
output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output systemAssignedIdentityPrincipalId string = systemAssignedIdentity && contains(sqlServer, 'identity') ? sqlServer.identity.principalId : ''

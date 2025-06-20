@description('Name of the SQL Server')
param sqlServerName string

@description('Azure AD administrator configuration')
param aadAdministrator object = {}

@description('Enable or disable Azure AD-only authentication')
param azureADOnlyAuthentication bool = false

@description('Enable system-assigned managed identity')
param systemAssignedIdentity bool = false

@description('User-assigned managed identities')
param userAssignedIdentities object = {}

// Reference the SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

// Configure Azure AD administrator
resource azureADAdmin 'Microsoft.Sql/servers/administrators@2022-05-01-preview' = if (!empty(aadAdministrator)) {
  parent: sqlServer
  name: 'activeDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: aadAdministrator.login
    sid: aadAdministrator.sid
    tenantId: contains(aadAdministrator, 'tenantId') ? aadAdministrator.tenantId : subscription().tenantId
    azureADOnlyAuthentication: azureADOnlyAuthentication
    principalType: contains(aadAdministrator, 'principalType') ? aadAdministrator.principalType : 'User'
  }
}

// Determine identity type
var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

// Update SQL Server with identity
resource sqlServerIdentity 'Microsoft.Sql/servers@2022-05-01-preview' = if (identityType != 'None') {
  name: sqlServerName
  location: sqlServer.location
  identity: {
    type: identityType
    userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
  }
  properties: sqlServer.properties
}

// Outputs
output aadAdminConfigured bool = !empty(aadAdministrator)
output azureADOnlyAuthentication bool = azureADOnlyAuthentication
output identityType string = identityType
output systemAssignedIdentityPrincipalId string = (systemAssignedIdentity && (identityType == 'SystemAssigned' || identityType == 'SystemAssigned,UserAssigned')) ? sqlServerIdentity.identity.principalId : ''

@description('Name of the App Service')
param appServiceName string

@description('Name of the slot (if any)')
param slotName string = ''

@description('Enable system-assigned managed identity')
param systemAssignedIdentity bool = false

@description('User-assigned managed identities to assign to the App Service')
param userAssignedIdentities object = {}

@description('Role assignments to create for the App Service identity')
param roleAssignments array = []

// Determine the identity type based on parameters
var identityType = systemAssignedIdentity && !empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : (systemAssignedIdentity ? 'SystemAssigned' : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None'))

// Reference the App Service
resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

// Reference the App Service slot if specified
resource appServiceSlot 'Microsoft.Web/sites/slots@2022-03-01' existing = if (!empty(slotName)) {
  name: '${appServiceName}/${slotName}'
}

// Update the App Service identity
resource appServiceIdentity 'Microsoft.Web/sites@2022-03-01' = if (empty(slotName)) {
  name: appServiceName
  identity: {
    type: identityType
    userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
  }
}

// Update the App Service slot identity if specified
resource slotIdentity 'Microsoft.Web/sites/slots@2022-03-01' = if (!empty(slotName)) {
  name: '${appServiceName}/${slotName}'
  identity: {
    type: identityType
    userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
  }
}

// Create role assignments for the App Service identity
resource appServiceRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (assignment, i) in roleAssignments: if (empty(slotName) && systemAssignedIdentity) {
  name: guid(appServiceName, assignment.roleDefinitionId, assignment.scope)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: assignment.roleDefinitionId
    principalId: appServiceIdentity.identity.principalId
    principalType: 'ServicePrincipal'
    description: contains(assignment, 'description') ? assignment.description : 'Role assignment for ${appServiceName}'
  }
}]

// Create role assignments for the App Service slot identity if specified
resource slotRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (assignment, i) in roleAssignments: if (!empty(slotName) && systemAssignedIdentity) {
  name: guid('${appServiceName}-${slotName}', assignment.roleDefinitionId, assignment.scope)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: assignment.roleDefinitionId
    principalId: slotIdentity.identity.principalId
    principalType: 'ServicePrincipal'
    description: contains(assignment, 'description') ? assignment.description : 'Role assignment for ${appServiceName}/${slotName}'
  }
}]

// Outputs
output principalId string = empty(slotName) ? (systemAssignedIdentity ? appServiceIdentity.identity.principalId : '') : (systemAssignedIdentity ? slotIdentity.identity.principalId : '')
output identityType string = identityType

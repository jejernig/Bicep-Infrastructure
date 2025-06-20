@description('Name of the parent App Service')
param appServiceName string

@description('Name of the source slot')
param sourceSlotName string

@description('Name of the target slot (usually production)')
param targetSlotName string = 'production'

@description('Whether to preserve Virtual Network settings during swap')
param preserveVnet bool = true

@description('Tags to apply to resources')
param tags object = {}

// Reference the parent App Service
resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

// Reference the source slot
resource sourceSlot 'Microsoft.Web/sites/slots@2022-03-01' existing = {
  name: '${appServiceName}/${sourceSlotName}'
}

// Reference the target slot if it's not production
resource targetSlot 'Microsoft.Web/sites/slots@2022-03-01' existing = if (targetSlotName != 'production') {
  name: '${appServiceName}/${targetSlotName}'
}

// Perform the slot swap
resource slotSwap 'Microsoft.Web/sites/slots/slotsdiffs@2022-03-01' = {
  name: '${appServiceName}/${sourceSlotName}/slotsdiffs'
  properties: {
    targetSlot: targetSlotName
    preserveVnet: preserveVnet
  }
}

// Output the result of the swap operation
output swapStatus string = slotSwap.properties.status
output sourceSlotName string = sourceSlotName
output targetSlotName string = targetSlotName

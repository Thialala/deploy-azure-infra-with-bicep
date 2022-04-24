param aspResourceGroupName string = resourceGroup().name
param aspName string
param webAppName string
param managedIdentityName string = ''
param location string = resourceGroup().location
param appSettings array = []

var shouldUseManagedIdentity =  !empty(managedIdentityName)

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' existing = {
  name: aspName
  scope: resourceGroup(aspResourceGroupName)
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = if (shouldUseManagedIdentity) {
  name: managedIdentityName
}

resource appService 'Microsoft.Web/sites@2021-03-01' = {
  name: webAppName
  location: location
  properties:{
    serverFarmId: appServicePlan.id
    siteConfig:{
      alwaysOn: true
      ftpsState: 'Disabled'
      appSettings: appSettings
      use32BitWorkerProcess: false
    }
    httpsOnly: true    
  }
  
  identity:  {
    type: shouldUseManagedIdentity ? 'UserAssigned' : 'None'
    userAssignedIdentities: shouldUseManagedIdentity ? {
      '${managedIdentity.id}': {}
    }: null
  }
}

param aspName string
param aspSku string
param webAppNamePrefix string = uniqueString(resourceGroup().id)
param location string = resourceGroup().location

var webSiteName = 'webapp-${webAppNamePrefix}'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: aspName
  location: location
  sku: {
    name: aspSku
    capacity: 1
  }
  properties:{
    reserved: true
  }
  kind: 'linux'
}

resource webApplication 'Microsoft.Web/sites@2018-11-01' = {
  name: webSiteName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      alwaysOn: true
      use32BitWorkerProcess: false
      linuxFxVersion: 'DOTNETCORE|6.0'
     }
  }
}


param aspName string
param aspSku string
param location string = resourceGroup().location

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

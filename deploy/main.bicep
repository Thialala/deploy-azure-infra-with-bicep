param aspName string
param aspSku string
param webAppName string
param location string = resourceGroup().location

param sqlServerName string
param databaseName string
param databaseTier string
param databaseSkuName string
param databaseMaxSizeBytes int
param longTermBackupProperties object = { 
  monthlyRetention: ''
  weeklyRetention: ''
  yearlyRetention: ''
  weekOfYear: 1
}

@allowed([
  'Geo'
  'GeoZone'
  'Local'
  'Zone'
])
param requestedBackupStorageRedundancy string = 'Zone'

param sqlServerUserAdminLogin string 
param sqlServerUserAdminObjectId string

param managedIdentityName string = ''

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}


module sqlDatabase 'modules/sql-database/main.bicep' = {
  name: 'deploy-sqlserver-and-database'
  params: {
    databaseMaxSizeBytes: databaseMaxSizeBytes
    databaseName: databaseName
    databaseSkuName: databaseSkuName
    databaseTier: databaseTier
    requestedBackupStorageRedundancy: requestedBackupStorageRedundancy
    serverName: sqlServerName
    sqlServerUserAdminLogin: sqlServerUserAdminLogin 
    sqlServerUserAdminObjectId: sqlServerUserAdminObjectId
    location: location
    longTermBackupProperties: longTermBackupProperties
  }
}

module appServicePlan 'modules/app-service-plan/main.bicep' = {
  name: 'deploy-asp'
  params: {
    aspName: aspName
    aspSku: aspSku
    location: location
  }
}

module webApp 'modules/web-app/main.bicep' = {
  name: 'deploy-web-app'
  params: {
    webAppName: webAppName
    aspName: aspName
    location: location
    managedIdentityName: managedIdentityName
    appSettings: [
      {
        name: 'SqlServerConnectionString'
        value: 'Server=tcp:${sqlDatabase.outputs.sqlServerFQDN};Database=${databaseName};Authentication=Active Directory Managed Identity;User ID=${managedIdentity.properties.principalId};'
      }
    ]
  }
  dependsOn:[
    appServicePlan
    sqlDatabase
  ]
}

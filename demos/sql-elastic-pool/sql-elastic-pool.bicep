
param location string = resourceGroup().location
param serverName string
param sqlServerUserAdminLogin string 
param sqlServerUserAdminObjectId string

@allowed([
  'Geo'
  'GeoZone'
  'Local'
  'Zone'
])
param requestedBackupStorageRedundancy string = 'Geo'

param elasticPoolName string
param elasticPoolSkuName string
param elasticPoolTier string
param elasticPoolCapacity int
var elasticPoolMaxSizeBytes = 268435456000

var databasePoolSkuName = 'ElasticPool'
var databasePoolTier = elasticPoolTier
param databaseMaxSizeBytes int = 21474836480

param databaseList object

param tags object = {}

var isZoneRedundant = toLower(elasticPoolTier) == 'premium' || toLower(elasticPoolTier) == 'businesscritical'

resource server 'Microsoft.Sql/servers@2021-08-01-preview' = {
  location: location
  name: serverName
  tags: tags
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    administrators: {
      administratorType:'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: sqlServerUserAdminLogin
      principalType: 'User'
      sid: sqlServerUserAdminObjectId
      tenantId: tenant().tenantId
    }
    publicNetworkAccess: 'Disabled'
  }
}

resource elasticPool 'Microsoft.Sql/servers/elasticPools@2021-08-01-preview' = {
  parent: server
  name: elasticPoolName
  location: location
  tags: tags
  sku: {
    name: elasticPoolSkuName
    tier: elasticPoolTier
    capacity: elasticPoolCapacity
  }
  properties: {
    maxSizeBytes: elasticPoolMaxSizeBytes
    zoneRedundant: isZoneRedundant
  }
}

resource databases 'Microsoft.Sql/servers/databases@2021-08-01-preview' = [for database in items(databaseList) : {
  parent: server
  name: database.key
  location: location
  tags: tags
  sku: {
    name: databasePoolSkuName
    tier: databasePoolTier
  }
  properties: {
    maxSizeBytes: databaseMaxSizeBytes
    elasticPoolId: elasticPool.id
    zoneRedundant: isZoneRedundant
    requestedBackupStorageRedundancy: requestedBackupStorageRedundancy
  }
}]

resource shortermBackup 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2021-08-01-preview' = [for i in range(0, length(items(databaseList))) : {
  name: 'default'
  parent: databases[i]
  properties: {
    diffBackupIntervalInHours: 24
    retentionDays: 35
  }
}]

resource longTermBackup 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2021-08-01-preview' = [for i in range(0, length(items(databaseList))) : {
  name: 'default'
  parent: databases[i]
  properties: databaseList[databases[i].name].longTermBackup
}]

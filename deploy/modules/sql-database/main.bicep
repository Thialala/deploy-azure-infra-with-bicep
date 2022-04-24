param serverName string
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
param requestedBackupStorageRedundancy string

param sqlServerUserAdminLogin string 
param sqlServerUserAdminObjectId string

param location string = resourceGroup().location

var isZoneRedundant = toLower(databaseTier) == 'premium' || toLower(databaseTier) == 'businesscritical'

resource server 'Microsoft.Sql/servers@2021-08-01-preview' = {
  location: location
  name: serverName
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
  }

  resource sqlServerFirewallRules 'firewallRules' = {
    name: 'allow-azure-services'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}

resource database 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: server
  location: location
  name: databaseName
  properties: {
    maxSizeBytes: databaseMaxSizeBytes
    requestedBackupStorageRedundancy: requestedBackupStorageRedundancy
    zoneRedundant: isZoneRedundant
  }
  sku: {
    name: databaseSkuName
    tier: databaseTier
  }

  resource shortermBackup 'backupShortTermRetentionPolicies' = {
    name: 'default'
    properties: {
      diffBackupIntervalInHours: 24
      retentionDays: 35
    }
  }

  resource longTermBackup 'backupLongTermRetentionPolicies' = {
    name: 'default'
    properties: longTermBackupProperties
  }
}

output sqlServerFQDN string = server.properties.fullyQualifiedDomainName

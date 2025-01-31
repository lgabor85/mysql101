@description('Provide a prefix for creating resource names.')
param resourceNamePrefix string

@description('Provide the location for all the resources.')
param location string = resourceGroup().location

@description('Provide the administrator login username for the flexible server.')
param administratorLogin string

@description('Provide the administrator login password for the flexible server.')
@secure()
param administratorLoginPassword string

@description('Provide an array of firewall rules to apply to the flexible server.')
param firewallRules array = [
  {
    name: 'rule1'
    startIPAddress: '185.65.134.229'
    endIPAddress: '185.65.134.229'
  }
]

@description('The tier of the particular SKU. High availability mode is available only in the GeneralPurpose and MemoryOptimized SKUs.')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param serverEdition string = 'Burstable'

@description('Server version')
@allowed([
  '5.7'
  '8.0.21'
])
param version string = '8.0.21'

@description('The availability zone information for the server. (If you don`t have a preference, leave blank.)')
param availabilityZone string = '1'

@description('High availability mode for a server: Disabled, SameZone, or ZoneRedundant.')
@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
param haEnabled string = 'Disabled'

@description('The availability zone of the standby server.')
param standbyAvailabilityZone string = '2'

param storageSizeGB int = 20
param storageIops int = 360
@allowed([
  'Enabled'
  'Disabled'
])
param storageAutogrow string = 'Enabled'

@description('The name of the SKU, such as Standard_D32ds_v4.')
param skuName string = 'Standard_B1ms'

param backupRetentionDays int = 7
@allowed([
  'Disabled'
  'Enabled'
])
param geoRedundantBackup string = 'Disabled'

param serverName string = '${resourceNamePrefix}sqlserver'
param databaseName string = '${resourceNamePrefix}mysqldb'

resource server 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  location: location
  name: serverName
  sku: {
    name: skuName
    tier: serverEdition
  }
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    availabilityZone: availabilityZone
    highAvailability: {
      mode: haEnabled
      standbyAvailabilityZone: standbyAvailabilityZone
    }
    storage: {
      storageSizeGB: storageSizeGB
      iops: storageIops
      autoGrow: storageAutogrow
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }
}

@batchSize(1)
module createFirewallRules './CreateFirewallRules.bicep' = [for i in range(0, ((length(firewallRules) > 0) ? length(firewallRules) : 1)): {
  name: 'firewallRules-${i}'
  params: {
    ip: firewallRules[i]
    serverName: serverName
  }
  dependsOn: [
    server
  ]
}]

resource database 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  parent: server
  name: databaseName
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}

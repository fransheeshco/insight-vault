  @description('Deployment location for all resources')
  param location string

  // Cosmos DB Parameters
  @description('CosmosDB account name')
  param cosmosAccountName string

  @description('The primary region for the Cosmos DB account.')
  param primaryRegion string

  @description('The secondary region for the Cosmos DB account.')
  param secondaryRegion string

  @description('Cosmos DB default consistency level')
  param defaultConsistencyLevel string

  @description('Max stale requests for BoundedStaleness.')
  param maxStalenessPrefix int

  @description('Max lag time in seconds for BoundedStaleness.')
  param maxIntervalInSeconds int

  @description('Enable system-managed failover for regions')
  param systemManagedFailover bool

  @description('Enable analytical storage for Cosmos DB account.')
  param enableAnalyticalStorage bool

  @description('Cosmos DB SQL database name.')
  param databaseName string

  @description('Name for the user container.')
  param userContainerName string

  @description('Name for the file container.')
  param fileContainerName string

  @description('Container/database throughput (RU/s).')
  param throughput int

  // Network Parameters
  @description('Virtual network name')
  param vnetName string

  @description('Subnet 1 name')
  param subnet1name string

  @description('Subnet 2 name')
  param subnet2name string

  @description('VNet address prefix')
  param vnetAddressPrefix string

  @description('Subnet 1 address prefix')
  param subnet1AddressPrefix string

  @description('Subnet 2 address prefix')
  param subnet2AddressPrefix string

  // Storage Parameters
  @description('Storage account name')
  @minLength(3)
  @maxLength(24)
  param storageAccountName string

  @description('Storage account SKU')
  param storageAccountSku string

  param appServiceName string

  @description('App Insight name.')
  param appInsightName string

  @allowed([
    'nonprod'
    'prod'
  ])
  @description('Specifies the environment type, which controls the SKU.')
  param environmentType string = 'nonprod'


  module networkModule 'modules/network/main.bicep' = {
    name: 'networkDeployment'
    params: {
      location: location
      vnetName: vnetName
      subnet1name: subnet1name
      subnet2name: subnet2name
      vnetAddressPrefix: vnetAddressPrefix
      subnet1AddressPrefix: subnet1AddressPrefix
      subnet2AddressPrefix: subnet2AddressPrefix
    }
  }

  module appInsights 'modules/appinsights/main.bicep' = {
    name: 'AppInsightsDeployment'
    params: {
      location: location
      appInsightName: appInsightName
    }
  }

  module appServiceModule 'modules/appservice/main.bicep' = {
    name: 'appServiceDeployment'  
    params: {
      location: location
      appServiceAppName: appServiceName 
      environmentType: environmentType
      appInsightsKey: appInsights.outputs.appInsightsKey
      cosmosDbAccountId: cosmosDbModule.outputs.cosmosDbAccountId
      cosmosDbAccountName: cosmosDbModule.outputs.cosmosDbAccountName
      cosmosDbEndpoint: cosmosDbModule.outputs.cosmosDbEndpoint
      storageAccountName: storageModule.outputs.storageAccountName
      networkName: networkModule.outputs.vnetName
    }
  }

  module storageModule 'modules/storage/main.bicep' = {
    name: 'storageDeployment'
    params: {
      storageAccountName: storageAccountName
      location: location
      storageAccountSku: storageAccountSku
    }
  }

  module cosmosDbModule './modules/cosmosDb/main.bicep' = {
    name: 'cosmosDbDeployment'
    params: {
      accountName: cosmosAccountName
      location: location
      primaryRegion: primaryRegion
      secondaryRegion: secondaryRegion
      defaultConsistencyLevel: defaultConsistencyLevel
      maxStalenessPrefix: maxStalenessPrefix
      maxIntervalInSeconds: maxIntervalInSeconds
      systemManagedFailover: systemManagedFailover
      enableAnalyticalStorage: enableAnalyticalStorage
      databaseName: databaseName
      userContainerName: userContainerName
      fileContainerName: fileContainerName
      throughput: throughput
    }
  }

  module identity './modules/identitymanager/main.bicep' = {
  name: 'assignRoles'
  params: {
    appServiceAppName: appServiceName
    appServicePrincipalID: appServiceModule.outputs.appServicePrincipalID
    storageAccountId: storageModule.outputs.storageAccountId
  }
}


  output cosmosDbName string = cosmosDbModule.outputs.cosmosDbAccountName
  output cosmosDbId string = cosmosDbModule.outputs.cosmosDbDatabaseId
  output storageId string = storageModule.outputs.storageAccountId
  output vnetId string = networkModule.outputs.vnetId
  output subnet1Id string = networkModule.outputs.subnet1Id
  output subnet2Id string = networkModule.outputs.subnet2Id

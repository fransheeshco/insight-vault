@description('Base name for all resources (e.g., insightvaultdev)')
param baseName string

@description('Deployment location for all resources')
param location string

@allowed([
  'nonprod'
  'prod'
])
@description('Specifies the environment type, which controls the SKU.')
param environmentType string = 'nonprod'

// Cosmos DB config
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

@description('Container/database throughput (RU/s).')
param throughput int

// Network
@description('VNet address prefix')
param vnetAddressPrefix string

@description('Subnet 1 address prefix')
param subnet1AddressPrefix string

@description('Subnet 2 address prefix')
param subnet2AddressPrefix string

// Storage
@description('Storage account SKU')
param storageAccountSku string

// Generate suffix and derived names
var suffix = uniqueString(resourceGroup().id)

var cosmosAccountName = '${baseName}cosmos${suffix}'
var databaseName = '${baseName}db${suffix}'
var userContainerName = '${baseName}user${suffix}'
var fileContainerName = '${baseName}file${suffix}'
var vnetName = '${baseName}vnet${suffix}'
var subnet1name = '${baseName}subnet1${suffix}'
var subnet2name = '${baseName}subnet2${suffix}'
var storageAccountName = toLower('${baseName}stor${suffix}')
var appServiceName = '${baseName}appsvc${suffix}'
var staticAppName = '${baseName}static${suffix}'
var typescriptFunctionAppName = '${baseName}tsfunc${suffix}'
var pythonFunctionAppName = '${baseName}pyfunc${suffix}'
var appInsightName = '${baseName}ai${suffix}'
var aiModelName = '${baseName}model${suffix}'

// Network module
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

// App Insights
module appInsights 'modules/appinsights/main.bicep' = {
  name: 'AppInsightsDeployment'
  params: {
    location: location
    appInsightName: appInsightName
  }
}

// App Service
module appServiceModule 'modules/appservice/main.bicep' = {
  name: 'appServiceDeployment'
  params: {
    location: location
    environmentType: environmentType
    appInsightsKey: appInsights.outputs.appInsightsKey
    cosmosDbAccountId: cosmosDbModule.outputs.cosmosDbAccountId
    cosmosDbAccountName: cosmosDbModule.outputs.cosmosDbAccountName
    cosmosDbEndpoint: cosmosDbModule.outputs.cosmosDbEndpoint
    storageAccountName: storageModule.outputs.storageAccountName
    networkName: networkModule.outputs.vnetName
    staticAppName: staticAppName
    openAIEndpoint: openAIModule.outputs.openAIEndpoint
    typescriptFunctionAppName: typescriptFunctionAppName
    pythonFunctionAppName: pythonFunctionAppName
  }
}

// Storage
module storageModule 'modules/storage/main.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    storageAccountSku: storageAccountSku
  }
}

// Cosmos DB
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

// Identity and Role Assignments
module identity './modules/identitymanager/main.bicep' = {
  name: 'assignRoles'
  params: {
    appServiceAppName: appServiceName
    appServicePrincipalID: appServiceModule.outputs.appServicePrincipalID
    storageAccountId: storageModule.outputs.storageAccountId
    openAIResourceId: openAIModule.outputs.modelInstanceID
  }
}

// OpenAI Module
module openAIModule './modules/openai/main.bicep' = {
  name: aiModelName
  params: {
    aiModelName: aiModelName
    location: location
  }
}

// Outputs
output cosmosDbName string = cosmosDbModule.outputs.cosmosDbAccountName
output cosmosDbId string = cosmosDbModule.outputs.cosmosDbDatabaseId
output storageId string = storageModule.outputs.storageAccountId
output vnetId string = networkModule.outputs.vnetId
output subnet1Id string = networkModule.outputs.subnet1Id
output subnet2Id string = networkModule.outputs.subnet2Id

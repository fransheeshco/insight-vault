@description('Base name for all resources (e.g., insightvaultdev)')
param baseName string

@description('Deployment location for all resources')
param location string

@allowed([
  'nonprod'
  'prod'
  'free'
])
@description('Specifies the environment type, which controls the SKU.')
param environmentType string = 'nonprod'

@description('Enable free tier resources (overrides environmentType for cost optimization)')
param enableFreeTier bool = false

@description('Storage account SKU')
param storageAccountSku string

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

@description('Name for the App Service plan (consumption plan)')
param planName string

@description('Name for the TypeScript Function App')
param tsFuncName string

@description('Name for the Python Function App')
param pyFuncName string

// Generate suffix and derived names
var suffix = uniqueString(resourceGroup().id)

var cosmosAccountName = '${baseName}cosmos${suffix}'
var databaseName = '${baseName}db${suffix}'
var userContainerName = '${baseName}user${suffix}'
var fileContainerName = '${baseName}file${suffix}'
var storageAccountName = toLower('${baseName}stor${suffix}')
var appInsightName = '${baseName}ai${suffix}'

// Determine if we should use free tier
var useFreeTier = enableFreeTier || environmentType == 'free'

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
    planName: planName
    tsFuncName: tsFuncName
    pyFuncName: pyFuncName
    storageAccountName: storageAccountName
    location: location
  }
}

// Storage
module storageModule 'modules/storage/main.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    storageAccountSku: storageAccountSku
    enableFreeTier: useFreeTier
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
    enableFreeTier: useFreeTier
  }
}

// Identity and Role Assignments (only if not using free tier)
// TODO: Pass the correct principal ID for the app service if identity assignment is required
// module identity './modules/identitymanager/main.bicep' = if (!useFreeTier) {
//   name: 'assignRoles'
//   params: {
//     appServiceAppName: appServiceName
//     appServicePrincipalID: appServiceModule.outputs.appServicePrincipalID
//     storageAccountId: storageModule.outputs.storageAccountId
//   }
// }

// Outputs
output cosmosDbName string = cosmosDbModule.outputs.cosmosDbAccountName
output cosmosDbId string = cosmosDbModule.outputs.cosmosDbDatabaseId
output storageId string = storageModule.outputs.storageAccountId
output isFreeTier string = useFreeTier ? 'true' : 'false'

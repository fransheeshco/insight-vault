@description('The Azure region to deploy resources in.')
param location string

@description('The name of the App Service application.')
param appServiceAppName string

@allowed([
  'nonprod'
  'prod'
])
@description('Specifies the environment type, which controls the SKU.')
param environmentType string = 'nonprod'

@description('Instrumentation Key for Application Insights.')
param appInsightsKey string

@description('Cosmos DB Account Name')
param cosmosDbAccountName string

@description('Cosmos DB Account ID')
param cosmosDbAccountId string

@description('Cosmos DB Account Endpoint')
param cosmosDbEndpoint string

param storageAccountName string

param networkName string

var appServicePlanName = 'insightVaultASP'

var appServicePlanSkuName = (environmentType == 'prod') ? 'P1v3' : 'F1'

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
  }
}

resource appServiceApp 'Microsoft.Web/sites@2024-04-01' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsKey
        }
        {
          name: 'COSMOS_DB_ACCOUNT'
          value: cosmosDbAccountName
        }
        {
          name: 'COSMOS_DB_KEY'
          value: listKeys(cosmosDbAccountId, '2021-04-15').primaryMasterKey
        }
        {
          name: 'COSMOS_DB_URI'
          value: cosmosDbEndpoint
        }
        {
          name: 'STORAGE_ACCOUNT_NAME'
          value: storageAccountName
        }
        {
          name: 'NETWORK_NAME'
          value: networkName
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output appServiceAppHostName string = appServiceApp.properties.defaultHostName
output appServiceAppResourceId string = appServiceApp.id
output appServicePlanResourceId string = appServicePlan.id
output appServicePrincipalID string = appServiceApp.identity.principalId

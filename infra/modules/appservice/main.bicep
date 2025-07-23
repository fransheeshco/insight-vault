@description('The Azure region to deploy resources in.')
param location string

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

param staticAppName string  

param openAIEndpoint string

param typescriptFunctionAppName string
param pythonFunctionAppName string

var appServicePlanName = 'insightVaultASP'

// Changed SKU from 'F1' (Free) to 'B1' (Basic) for nonprod environments
var appServicePlanSkuName = (environmentType == 'prod') ? 'P1v3' : 'B1'

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
    // Changed tier from 'Dynamic' to 'Basic' to match 'B1' SKU
    tier: (environmentType == 'prod') ? 'ElasticPremium' : 'Basic'
  }
}

resource typescriptFunctionAppService 'Microsoft.Web/sites@2024-04-01' = {
  name: typescriptFunctionAppName
  location: location
  kind: 'functionapp'
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
        {
        name: 'AZURE_OPENAI_ENDPOINT'
        value: openAIEndpoint
        }
        {
          name: 'AZURE_OPENAI_API_VERSION'
          value: '2024-06-01-preview'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource pythonFunctionAppService 'Microsoft.Web/sites@2024-04-01' = {
  name: pythonFunctionAppName
  location: location
  kind: 'functionapp'
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
        {
        name: 'AZURE_OPENAI_ENDPOINT'
        value: openAIEndpoint
        }
        {
          name: 'AZURE_OPENAI_API_VERSION'
          value: '2024-06-01-preview'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource staticWebApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: staticAppName
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  location: location
  properties: {
    repositoryUrl: 'https://github.com/fransheeshco/insight-vault'
    branch: 'main'
    buildProperties: {
      appLocation: '/'
      apiLocation: 'api'
      outputLocation: 'build'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// output for typescript function app service
output appServiceAppHostName string = typescriptFunctionAppService.properties.defaultHostName
output appServiceAppResourceId string = typescriptFunctionAppService.id
output appServicePlanResourceId string = appServicePlan.id
output appServicePrincipalID string = typescriptFunctionAppService.identity.principalId

// output for python function app service
output pythonFunctionAppServiceHostName string = pythonFunctionAppService.properties.defaultHostName
output pythonFunctionAppServiceResourceID string = pythonFunctionAppService.id
output pythonFunctionAppServicePlanResourceId string = appServicePlan.id
output pythonServicePrincipalID string = pythonFunctionAppService.identity.principalId

// output for static web app service
output staticWebAppHostName string = staticWebApp.properties.defaultHostname
output staticWebAppURL string = 'https://${staticWebApp.properties.defaultHostname}'
output staticWebAppResourceID string = staticWebApp.id


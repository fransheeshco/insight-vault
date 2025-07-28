@description('Name for the App Service plan (consumption plan)')
param planName string

@description('Name for the TypeScript Function App')
param tsFuncName string

@description('Name for the Python Function App')
param pyFuncName string

@description('Name of the storage account to use for the function apps')
param storageAccountName string

@description('Location for all resources')
param location string

// Reference existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Consumption Plan (shared by both functions)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: planName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'functionapp'
}

// TypeScript Function App
resource tsFunctionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: tsFuncName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageAccount.properties.primaryEndpoints.blob
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }
    httpsOnly: true
  }
}

// Python Function App
resource pyFunctionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: pyFuncName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageAccount.properties.primaryEndpoints.blob
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }
    httpsOnly: true
  }
}

// Outputs
output functionAppPlanName string = appServicePlan.name
output tsFunctionAppName string = tsFunctionApp.name
output pyFunctionAppName string = pyFunctionApp.name
output tsFunctionAppUrl string = 'https://${tsFunctionApp.properties.defaultHostName}/api'
output pyFunctionAppUrl string = 'https://${pyFunctionApp.properties.defaultHostName}/api'

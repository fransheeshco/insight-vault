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
      ]
    }
  }
}

output appServiceAppHostName string = appServiceApp.properties.defaultHostName
output appServiceAppResourceId string = appServiceApp.id
output appServicePlanResourceId string = appServicePlan.id

@description('App Insight Name')
param appInsightName string = 'insightVaultAI'

@description('App service plan location')
param location string

resource appInsightsComponents 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightName  
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

output appInsightsKey string = appInsightsComponents.properties.InstrumentationKey

@description('AI resource name.')
param aiModelName string

param location string

resource openAIModel 'Microsoft.CognitiveServices/accounts@2025-06-01' = { 
  name: aiModelName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true  
  }
}

output modelInstanceID string = openAIModel.id
output openAIEndpoint string = 'https://${aiModelName}.openai.azure.com/'

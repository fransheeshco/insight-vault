@minLength(3)
@maxLength(24)
@description('Provide a name for the storage account. Use only lowercase letters and numbers. The name must be unique across Azure.')
param storageAccountName string

@description('The location for the storage account.')
param location string

@description('The SKU of the storage account (e.g., Standard_LRS, Standard_GRS).')
param storageAccountSku string = 'Standard_LRS'

@description('Enable free tier resources')
param enableFreeTier bool = false

// Use Standard_LRS for free tier (5GB free), otherwise use provided SKU
var finalStorageSku = enableFreeTier ? 'Standard_LRS' : storageAccountSku

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: finalStorageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot' 
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name


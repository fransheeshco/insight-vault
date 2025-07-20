  using '../main.bicep'

  param location = 'westeurope'

  param cosmosAccountName = 'insightvaultcosmosdev'
  param primaryRegion = 'southeastasia'
  param secondaryRegion = 'centralus'
  param defaultConsistencyLevel = 'Session'
  param maxStalenessPrefix = 100000
  param maxIntervalInSeconds = 300
  param systemManagedFailover = true
  param enableAnalyticalStorage = true
  param databaseName = 'insightVaultDB'
  param userContainerName = 'userContainer'
  param fileContainerName = 'fileContainer'
  param throughput = 400
  param vnetName = 'insightVaultVnetDev'
  param subnet1name = 'Subnet-1'
  param subnet2name = 'Subnet-2'
  param vnetAddressPrefix = '10.0.0.0/16'
  param subnet1AddressPrefix = '10.0.0.0/24'
  param subnet2AddressPrefix = '10.0.1.0/24'

  param storageAccountName = 'insightvaultstoragedev'
  param storageAccountSku = 'Standard_LRS'

  param appServiceName = 'insightVaultASN'
  param staticAppName = 'insightvault'

  param appInsightName = 'insightVaultAI'

  param aiModelName = 'openAIServices'
  

using '../main.bicep'

param baseName = 'ivdev'
param location = 'westeurope'
param primaryRegion = 'southeastasia'
param secondaryRegion = 'centralus'
param defaultConsistencyLevel = 'Session'
param maxStalenessPrefix = 100000
param maxIntervalInSeconds = 300
param systemManagedFailover = true
param enableAnalyticalStorage = true
param throughput = 400
param vnetAddressPrefix = '10.0.0.0/16'
param subnet1AddressPrefix = '10.0.0.0/24'
param subnet2AddressPrefix = '10.0.1.0/24'
param storageAccountSku = 'Standard_LRS'
param environmentType = 'nonprod'

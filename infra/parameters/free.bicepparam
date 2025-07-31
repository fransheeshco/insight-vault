using '../main.bicep'

param baseName = 'ivfree'
param location = 'westeurope'
param primaryRegion = 'westeurope'
param secondaryRegion = 'northeurope'
param defaultConsistencyLevel = 'Session'
param maxStalenessPrefix = 100000
param maxIntervalInSeconds = 300
param systemManagedFailover = false
param enableAnalyticalStorage = false
param throughput = 1000
param storageAccountSku = 'Standard_LRS'
param environmentType = 'nonprod'
param enableFreeTier = false 
param planName = 'ivfree-plan'
param tsFuncName = 'ivfree-tsfunc'
param pyFuncName = 'ivfree-pyfunc' 

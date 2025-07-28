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
param storageAccountSku = 'Standard_LRS'
param environmentType = 'nonprod'
param planName = 'ivdev-plan'
param tsFuncName = 'ivdev-tsfunc'
param pyFuncName = 'ivdev-pyfunc'

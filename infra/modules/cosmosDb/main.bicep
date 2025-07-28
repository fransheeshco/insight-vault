  @description('CosmosDB account name')
  param accountName string

  @description('Location for the Azure Cosmos DB account.')
  param location string

  @description('The primary region for the Azure Cosmos DB account.')
  param primaryRegion string

  param secondaryRegion string

  @allowed([
    'Eventual'
    'ConsistentPrefix'
    'Session'
    'BoundedStaleness'
    'Strong'
  ])
  @description('The default consistency level of the Cosmos DB account.')
  param defaultConsistencyLevel string = 'Session'

  @minValue(10)
  @maxValue(2147483647)
  @description('Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 2147483647. Multi Region: 100000 to 2147483647.')
  param maxStalenessPrefix int = 100000

  @minValue(5)
  @maxValue(86400)
  @description('Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400')
  param maxIntervalInSeconds int = 300

  @allowed([
    true
    false
  ])
  @description('Enable system managed failover for regions')
  param systemManagedFailover bool = true

  @description('Enable analytical storage for the Cosmos DB account.')
  param enableAnalyticalStorage bool = false // Corrected parameter for analytical storage

  @description('Name for the database.')
  param databaseName string = 'insightVaultDB'

  @description('Name for the user container.')
  param userContainerName string = 'userContainer'

  @description('Name for the file container.')
  param fileContainerName string = 'fileContainer'

  @minValue(400)
  @maxValue(1000000)
  @description('The throughput for the containers (RU/s).')
  param throughput int = 400

  @description('Enable free tier resources')
  param enableFreeTier bool = false

  var consistencyPolicy = {
    Eventual: {
      defaultConsistencyLevel: 'Eventual'
    }
    ConsistentPrefix: {
      defaultConsistencyLevel: 'ConsistentPrefix'
    }
    Session: {
      defaultConsistencyLevel: 'Session'
    }
    BoundedStaleness: {
      defaultConsistencyLevel: 'BoundedStaleness'
      maxStalenessPrefix: maxStalenessPrefix
      maxIntervalInSeconds: maxIntervalInSeconds
    }
    Strong: {
      defaultConsistencyLevel: 'Strong'
    }
  }

  // For free tier, use single region only
  var locations = enableFreeTier ? [
    {
      locationName: primaryRegion
      failoverPriority: 0
      isZoneRedundant: false
    }
  ] : [
    {
      locationName: primaryRegion
      failoverPriority: 0
      isZoneRedundant: false
    }
    {
      locationName: secondaryRegion
      failoverPriority: 1
      isZoneRedundant: false
    }
  ]

  // For free tier, disable analytical storage and use minimum throughput
  var finalAnalyticalStorage = enableFreeTier ? false : enableAnalyticalStorage
  var finalThroughput = enableFreeTier ? 1000 : throughput
  var finalSystemManagedFailover = enableFreeTier ? false : systemManagedFailover

  resource account 'Microsoft.DocumentDB/databaseAccounts@2025-04-15' = {
    name: toLower(accountName)
    location: location
    kind: 'GlobalDocumentDB'
    properties: {
      consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
      locations: locations
      databaseAccountOfferType: 'Standard'
      enableAnalyticalStorage: finalAnalyticalStorage // Corrected usage
      disableKeyBasedMetadataWriteAccess: true
      enableAutomaticFailover: finalSystemManagedFailover // Renamed for clarity
    }
  }

  resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2025-04-15' = {
    parent: account
    name: databaseName
    properties: {
      resource: {
        id: databaseName
      }
      options: {
        throughput: finalThroughput // Apply throughput at database level
      }
    }
  }

  resource userContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-04-15' = {
    parent: database
    name: userContainerName
    properties: {
      resource: {
        id: userContainerName
        partitionKey: {
          paths: [
            '/userid'
          ]
        }
        indexingPolicy: {
          indexingMode: 'consistent'
          includedPaths: [
            {
              path: '/*'
            }
          ]
          excludedPaths: [
            {
              path: '/myPathToNotIndex/*'
            }
            {
              path: '/_etag/?'
            }
          ]
          compositeIndexes: [
            [
              {
                path: '/name'
                order: 'ascending'
              }
              {
                path: '/email'
                order: 'descending'
              }
            ]
          ]
          spatialIndexes: [
            {
              path: '/location/*'
              types: [
                'Point'
                'Polygon'
                'MultiPolygon'
                'LineString'
              ]
            }
          ]
        }
        defaultTtl: 86400
        uniqueKeyPolicy: {
          uniqueKeys: [
            {
              paths: [
                '/userid'
              ]
            }
          ]
        }
      }
    }
  }

  resource fileContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-04-15' = {
    parent: database
    name: fileContainerName
    properties: {
      resource: {
        id: fileContainerName
        partitionKey: {
          paths: [
            '/fileid'
          ]
          kind: 'Hash'
        }
        indexingPolicy: {
          indexingMode: 'consistent'
          includedPaths: [
            {
              path: '/*'
            }
          ]
          excludedPaths: [
            {
              path: '/myPathToNotIndex/*'
            }
            {
              path: '/_etag/?'
            }
          ]
          compositeIndexes: [
            [
              {
                path: '/dateCreated'
                order: 'ascending'
              }
              {
                path: '/filename'
                order: 'descending'
              }
            ]
          ]
          spatialIndexes: [
            {
              path: '/location/*'
              types: [
                'Point'
                'Polygon'
                'MultiPolygon'
                'LineString'
              ]
            }
          ]
        } 
        defaultTtl: 86400
        uniqueKeyPolicy: {
          uniqueKeys: [
            {
              paths: [
                '/fileid'
              ]
            }
          ]
        }
      }
    }
  }

output cosmosDbAccountName string = account.name
output cosmosDbAccountId string = account.id
output cosmosDbDatabaseName string = database.name
output cosmosDbDatabaseId string = database.id
output cosmosDbEndpoint string = account.properties.documentEndpoint

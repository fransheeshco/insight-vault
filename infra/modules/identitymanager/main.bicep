  @description('The name of the App Service (used only for deterministic GUID generation).')
  param appServiceAppName string

  @description('App Service principal (object) ID')
  param appServicePrincipalID string

  @description('Resource ID of the Storage Account')
  param storageAccountId string

  @description('OpenAI resource ID')
  param openAIResourceId string

  // Convert storageAccountId into an existing typed resource
  resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
    name: last(split(storageAccountId, '/'))
    scope: resourceGroup()
  }

  resource openAI 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
    name: last(split(openAIResourceId, '/'))
    scope: resourceGroup()
  }

  // Reference Storage Table Data Contributor Role
  resource storageTableDataContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: subscription()
    name: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
  }

  // Assign Table permissions
  resource tableRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    name: guid(resourceGroup().id, appServiceAppName, storageTableDataContributorRoleDefinition.id)
    scope: storageAccount
    properties: {
      roleDefinitionId: storageTableDataContributorRoleDefinition.id
      principalId: appServicePrincipalID
    }
  }

  // Reference Storage Blob Data Contributor Role
  resource storageBlobDataContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: subscription()
    name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  }

  // Assign Blob permissions
  resource blobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    name: guid(resourceGroup().id, appServiceAppName, storageBlobDataContributorRoleDefinition.id)
    scope: storageAccount
    properties: {
      roleDefinitionId: storageBlobDataContributorRoleDefinition.id
      principalId: appServicePrincipalID
    }
  }

  resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
    name: guid(openAIResourceId, appServiceAppName, 'CognitiveServices.OpenAI.User')
    scope: openAI
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
      principalId: appServicePrincipalID
      principalType: 'ServicePrincipal'
    }
  }


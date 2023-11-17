@description('Specifies the name of the container app.')
param name string = '' //'app-${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the container app environment.')
param containerAppEnvName string = '' //'env-${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the container app environment.')
param containerRegistryName string = '' //'cr${uniqueString(resourceGroup().id)}'

@description('Specifies the location for all resources.')
param location string = resourceGroup().location

// @description('Specifies the docker container image to deploy.')
// param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Minimum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param minReplica int = 1

@description('Maximum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param maxReplica int = 3

param acrHostedImage string = ''
param keyVaultName string = ''
param managedIdentity bool = !empty(keyVaultName)


param applicationinsightsConnectionString string = '' //       APPLICATIONINSIGHTS_CONNECTION_STRING: useApplicationInsights ? monitoring.outputs.applicationInsightsConnectionString : ''
param azureStorageAccount string  = '' //       AZURE_STORAGE_ACCOUNT: storage.outputs.name
param azureStorageContainer string  = '' //       AZURE_STORAGE_CONTAINER: storageContainerName
param azureOpenaiService string  = '' //       AZURE_OPENAI_SERVICE: openAi.outputs.name
param azureSearchIndex string  = '' //       AZURE_SEARCH_INDEX: searchIndexName
param azureSearchService string = ''//       AZURE_SEARCH_SERVICE: searchService.outputs.name
param azureOpenaiGpt35TurboDeployment string  = ''//       AZURE_OPENAI_GPT_35_TURBO_DEPLOYMENT: openAiGpt35TurboDeploymentName
param azureOpenaiGpt35Turbo16kDeployment string  = ''//       AZURE_OPENAI_GPT_35_TURBO_16K_DEPLOYMENT: openAiGpt35Turbo16kDeploymentName
param azureOpenaiGpt4Deployment string  = ''//       AZURE_OPENAI_GPT_4_DEPLOYMENT: ''
param azureOpenaiGpt432kDeployment string = '' //       AZURE_OPENAI_GPT_4_32K_DEPLOYMENT: ''
param azureOpenaiApiVersion string = '' //       AZURE_OPENAI_API_VERSION: '2023-05-15'
param azureCosmosdbContainer string = '' //       AZURE_COSMOSDB_CONTAINER: cosmosDbContainerName
param azureCosmosdbDatabase string = '' //       AZURE_COSMOSDB_DATABASE: cosmosDbDatabaseName
param azureCosmosdbEndpoint string = '' //       AZURE_COSMOSDB_ENDPOINT: cosmosDb.outputs.endpoint






resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview'existing = {
  name: 'id-${name}'
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppEnvName
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  // identity: { type: managedIdentity ? 'SystemAssigned' : 'None' }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uai.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          identity: uai.id
          server: acr.properties.loginServer
        }
      ]
    }
    template: {
      revisionSuffix: 'firstrevision'
      containers: [
        {
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationinsightsConnectionString
            }
            {
              name: 'AZURE_STORAGE_ACCOUNT'
              value: azureStorageAccount
            }
            {
              name: 'AZURE_STORAGE_CONTAINER'
              value: azureStorageContainer
            }
            {
              name: 'AZURE_OPENAI_SERVICE'
              value: azureOpenaiService
            }
            {
              name: 'AZURE_SEARCH_INDEX'
              value: azureSearchIndex
            }
            {
              name: 'AZURE_SEARCH_SERVICE'
              value: azureSearchService
            }
            {
              name: 'AZURE_OPENAI_GPT_35_TURBO_DEPLOYMENT'
              value: azureOpenaiGpt35TurboDeployment
            }
            {
              name: 'AZURE_OPENAI_GPT_35_TURBO_16K_DEPLOYMENT'
              value: azureOpenaiGpt35Turbo16kDeployment
            }
            {
              name: 'AZURE_OPENAI_GPT_4_DEPLOYMENT'
              value: azureOpenaiGpt4Deployment
            }
            {
              name: 'AZURE_OPENAI_GPT_4_32K_DEPLOYMENT'
              value: azureOpenaiGpt432kDeployment
            }
            {
              name: 'AZURE_OPENAI_API_VERSION'
              value: azureOpenaiApiVersion
            }
            {
              name: 'AZURE_COSMOSDB_CONTAINER'
              value: azureCosmosdbContainer
            }
            {
              name: 'AZURE_COSMOSDB_DATABASE'
              value: azureCosmosdbDatabase
            }
            {
              name: 'AZURE_COSMOSDB_ENDPOINT'
              value: azureCosmosdbEndpoint
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: uai.properties.clientId
            }
          ]
          name: name
          image: acrHostedImage   //acrImportImage.outputs.importedImages[0].acrHostedImage
          resources: {
            cpu: json('.25')
            memory: '.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: minReplica
        maxReplicas: maxReplica
        rules: [
          {
            name: 'http-requests'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

output containerAppFQDN string = containerApp.properties.configuration.ingress.fqdn
output containerImage string = acrHostedImage //acrImportImage.outputs.importedImages[0].acrHostedImage



output identityPrincipalId string = managedIdentity ? uai.properties.principalId : ''
output name string = ''
output id string = ''
output uri string = ''

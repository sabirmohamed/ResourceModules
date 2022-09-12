@sys.description('Required. The name of the private endpoint connection.')
param name string

@sys.description('Required. The resource ID of the application gateway to which a private connection will be added.')
param resourceId string

@sys.description('Optional. A message indicating if changes on the service provider require any updates on the consumer.')
param actionsRequired string = ''

@sys.description('Optional. The reason for approval/rejection of the connection.')
param description string = ''

@sys.description('Optional. Indicates whether the connection has been Approved/Rejected/Removed by the owner of the service.')
param status string = ''

@sys.description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2021-08-01' existing = {
  name: last(split(resourceId, '/'))
}

resource appGwPrivateEndpointConnections 'Microsoft.Network/applicationGateways/privateEndpointConnections@2021-08-01' = {
  name: guid(applicationGateway.id, name)
  parent: applicationGateway
  properties: {
    privateLinkServiceConnectionState: {
      actionsRequired: !empty(actionsRequired) ? actionsRequired : null
      description: !empty(description) ? description : null
      status: !empty(status) ? status : null
    }
  }
}

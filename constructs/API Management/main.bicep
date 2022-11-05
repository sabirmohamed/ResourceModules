targetScope = 'resourceGroup'

param location string = resourceGroup().location

param virtualNetworkName string = 'dedicated-zone-vnet-01'

param virtualNetworkAddressPrefix string = '172.16.30.0/21'

param subnetName string = 'apim-subnet-01'

param subnetAddressPrefix string = '172.16.30.0/23'

param userAssignedIdentityResourceId string

param apiManagementName string = 'apim-01'

param apiManagementServicePublisherName string = 'Cloud Innovation Team'

param apiManagementServicePublisherEmail string = 'test@test.com'

module virtualNetwork '../../modules/Microsoft.Network/virtualNetworks/deploy.bicep' = {
  name: 'module-VirtualNetwork'
  params: {
    name: virtualNetworkName
    location: location
    addressPrefixes: [
      virtualNetworkAddressPrefix
    ]
  }
}

module subnet '../../modules/Microsoft.Network/virtualNetworks/subnets/deploy.bicep' = {
  name: 'module-Subnet'
  params: {
    name: subnetName
    virtualNetworkName: virtualNetwork.outputs.name
    addressPrefix: subnetAddressPrefix
    networkSecurityGroupId: networkSecurityGroup.outputs.resourceId
  }
}

module networkSecurityGroup '../../modules/Microsoft.Network/networkSecurityGroups/deploy.bicep' = {
  name: 'module-NetworkSecurityGroup'
  params: {
    name: '${subnetName}-nsg'
    location: location
    securityRules: [
      {
        name: 'Allow-APIM-Management'
        properties: {
          access: 'Allow'
          description: 'Management endpoint for Azure portal and PowerShell'
          destinationAddressPrefix: '*'
          destinationPortRange: '3443'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'ApiManagement'
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-APIM-Management-ALB'
        properties: {
          access: 'Allow'
          description: 'Azure Infrastructure Load Balancer (required for Premium service tier)'
          destinationAddressPrefix: '*'
          destinationPortRange: '6390'
          direction: 'Inbound'
          priority: 120
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

module privateDnsZone '../../modules/Microsoft.Network/privateDnsZones/deploy.bicep' = {
  name: 'module-PrivateDnsZone'
  params: {
    name: 'azure-api.net'
    location: location
    a: [
      {
        name: apiManagementName
        aRecords: [
          {
            ipv4Address: apiManagementService.outputs.apiManagementServicePrivateIPaddresses[0]
          }
        ]
      }
      {
        name: '${apiManagementName}.developer'
        aRecords: [
          {
            ipv4Address: apiManagementService.outputs.apiManagementServicePrivateIPaddresses[0]
          }
        ]
      }
      {
        name: '${apiManagementName}.management'
        aRecords: [
          {
            ipv4Address: apiManagementService.outputs.apiManagementServicePrivateIPaddresses[0]
          }
        ]
      }
      {
        name: '${apiManagementName}.portal'
        aRecords: [
          {
            ipv4Address: apiManagementService.outputs.apiManagementServicePrivateIPaddresses[0]
          }
        ]
      }
      {
        name: '${apiManagementName}.scm'
        aRecords: [
          {
            ipv4Address: apiManagementService.outputs.apiManagementServicePrivateIPaddresses[0]
          }
        ]
      }
    ]
  }
}

module apiManagementService '../../modules/Microsoft.ApiManagement/service/deploy.bicep' = {
  name: 'module-ApiManagementService'
  params: {
    name: apiManagementName
    location: location
    publisherEmail: apiManagementServicePublisherEmail
    publisherName: apiManagementServicePublisherName
    notificationSenderEmail: 'apimgmt-noreply@mail.windowsazure.com'
    sku: 'Developer'
    virtualNetworkType: 'Internal'
    subnetResourceId: subnet.outputs.resourceId
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: '${apiManagementName}.azure-api.net'
        negotiateClientCertificate: false
        defaultSslBinding: true
        certificateSource: 'BuiltIn'
      }
    ]
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168.Enabled': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10.Enabled': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11.Enabled': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': false
    }
    apis: [
      {
        name: 'echo-api'
        displayName: 'Echo API'
        apiRevision: '1'
        subscriptionRequired: true
        serviceUrl: 'http://echoapi.cloudapp.net/api'
        path: 'echo'
        protocols: [
          'https'
        ]
        authenticationSettings: {}
        subscriptionKeyParameterNames: {
          header: 'Ocp-Apim-Subscription-Key'
          query: 'subscription-key'
        }
        isCurrent: true
      }
    ]
  }
}

module apiManagementPortalSettingsSignUp '../../modules/Microsoft.ApiManagement/service/portalsettings/deploy.bicep' = {
  name: 'module-ApiManagementPortalSettingsSignUp'
  params: {
    name: 'signup'
    apiManagementServiceName: apiManagementService.outputs.name
    properties: {
      enabled: true
      termsOfService: {
        enabled: true
        consentRequired: false
        text: 'By clicking on "Sign up" you agree to the terms and conditions.'
      }
    }
  }
}

module apiManagementPortalSettingsSignIn '../../modules/Microsoft.ApiManagement/service/portalsettings/deploy.bicep' = {
  name: 'module-ApiManagementPortalSettingsSignIn'
  params: {
    name: 'signin'
    apiManagementServiceName: apiManagementService.outputs.name
    properties: {
      enabled: false
    }
  }
}

module apiManagementProductsStarter '../../modules/Microsoft.ApiManagement/service/products/deploy.bicep' = {
  name: 'module-ApiManagementProductsStarter'
  params: {
    name: 'starter'
    apiManagementServiceName: apiManagementService.outputs.name
    productDescription: 'Subscribers will be able to run 5 calls/minute up to a maximum of 100 calls/week.'
    subscriptionRequired: true
    approvalRequired: false
    subscriptionsLimit: 1
    state: 'published'
  }
}

module apiManagementProductsUnlimited '../../modules/Microsoft.ApiManagement/service/products/deploy.bicep' = {
  name: 'module-ApiManagementProductsUnlimited'
  params: {
    name: 'unlimited'
    apiManagementServiceName: apiManagementService.outputs.name
    productDescription: 'Subscribers have completely unlimited access to the API. Administrator approval is required.'
    subscriptionRequired: true
    approvalRequired: true
    subscriptionsLimit: 1
    state: 'published'
  }
}

module apiManagementSubscriptions '../../modules/Microsoft.ApiManagement/service/subscriptions/deploy.bicep' = {
  name: 'module-ApiManagementSubscriptions'
  params: {
    name: 'master'
    apiManagementServiceName: apiManagementService.outputs.name
    scope: '${apiManagementService.outputs.resourceId}/'
    state: 'active'
    allowTracing: true
  }
}

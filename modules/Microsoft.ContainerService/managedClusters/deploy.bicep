@description('Required. Specifies the name of the AKS cluster.')
param name string

@description('Optional. Specifies the location of AKS cluster. It picks up Resource Group\'s location by default.')
param location string = resourceGroup().location

@description('Optional. Specifies the DNS prefix specified when creating the managed cluster.')
param aksClusterDnsPrefix string = name

@description('Optional. Existing Private DNS Zone Resource ID. If not provided, default is none.')
param privateDNSZoneResourceId string = 'none'

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Optional. Specifies the network plugin used for building Kubernetes network. - azure or kubenet.')
@allowed([
  ''
  'azure'
  'kubenet'
])
param aksClusterNetworkPlugin string = ''

@description('Optional. Specifies the network policy used for building Kubernetes network. - calico or azure.')
@allowed([
  ''
  'azure'
  'calico'
])
param aksClusterNetworkPolicy string = ''

@description('Optional. Specifies the CIDR notation IP range from which to assign pod IPs when kubenet is used.')
param aksClusterPodCidr string = ''

@description('Optional. A CIDR notation IP range from which to assign service cluster IPs. It must not overlap with any Subnet IP ranges.')
param aksClusterServiceCidr string = ''

@description('Optional. Specifies the IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr.')
param aksClusterDnsServiceIP string = ''

@description('Optional. Specifies the CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.')
param aksClusterDockerBridgeCidr string = ''

@description('Optional. Specifies the sku of the load balancer used by the virtual machine scale sets used by nodepools.')
@allowed([
  'basic'
  'standard'
])
param aksClusterLoadBalancerSku string = 'standard'

@description('Optional. Outbound IP Count for the Load balancer.')
param managedOutboundIPCount int = 0

@description('Optional. Specifies outbound (egress) routing method. - loadBalancer or userDefinedRouting.')
@allowed([
  'loadBalancer'
  'userDefinedRouting'
])
param aksClusterOutboundType string = 'loadBalancer'

@description('Optional. Tier of a managed cluster SKU. - Free or Paid.')
@allowed([
  'Free'
  'Paid'
])
param aksClusterSkuTier string = 'Free'

@description('Optional. Version of Kubernetes specified when creating the managed cluster.')
param aksClusterKubernetesVersion string = ''

@description('Optional. Specifies the administrator username of Linux virtual machines.')
param aksClusterAdminUsername string = 'azureuser'

@description('Optional. Specifies the SSH RSA public key string for the Linux nodes.')
param aksClusterSshPublicKey string = ''

@description('Optional. Information about a service principal identity for the cluster to use for manipulating Azure APIs.')
param aksServicePrincipalProfile object = {}

@description('Optional. The client AAD application ID.')
param aadProfileClientAppID string = ''

@description('Optional. The server AAD application ID.')
param aadProfileServerAppID string = ''

@description('Optional. The server AAD application secret.')
#disable-next-line secure-secrets-in-params // Not a secret
param aadProfileServerAppSecret string = ''

@description('Optional. Specifies the tenant ID of the Azure Active Directory used by the AKS cluster for authentication.')
param aadProfileTenantId string = subscription().tenantId

@description('Optional. Specifies the AAD group object IDs that will have admin role of the cluster.')
param aadProfileAdminGroupObjectIDs array = []

@description('Optional. Specifies whether to enable managed AAD integration.')
param aadProfileManaged bool = true

@description('Optional. Whether to enable Kubernetes Role-Based Access Control.')
param enableRBAC bool = true

@description('Optional. Specifies whether to enable Azure RBAC for Kubernetes authorization.')
param aadProfileEnableAzureRBAC bool = enableRBAC

@description('Optional. If set to true, getting static credentials will be disabled for this cluster. This must only be used on Managed Clusters that are AAD enabled.')
param disableLocalAccounts bool = false

@description('Optional. Name of the resource group containing agent pool nodes.')
param nodeResourceGroup string = '${resourceGroup().name}_aks_${name}_nodes'

@description('Optional. IP ranges are specified in CIDR format, e.g. 137.117.106.88/29. This feature is not compatible with clusters that use Public IP Per Node, or clusters that are using a Basic Load Balancer.')
param authorizedIPRanges array = []

@description('Optional. Whether to disable run command for the cluster or not.')
param disableRunCommand bool = false

@description('Required. Properties of the primary agent pool.')
param primaryAgentPoolProfile array

@description('Optional. Define one or more secondary/additional agent pools.')
param agentPools array = []

@description('Optional. Specifies whether the httpApplicationRouting add-on is enabled or not.')
param httpApplicationRoutingEnabled bool = false

@description('Optional. Specifies whether the ingressApplicationGateway (AGIC) add-on is enabled or not.')
param ingressApplicationGatewayEnabled bool = false

@description('Conditional. Specifies the resource ID of connected application gateway. Required if `ingressApplicationGatewayEnabled` is set to `true`.')
param appGatewayResourceId string = ''

@description('Optional. Specifies whether the aciConnectorLinux add-on is enabled or not.')
param aciConnectorLinuxEnabled bool = false

@description('Optional. Specifies whether the azurepolicy add-on is enabled or not. For security reasons, this setting should be enabled.')
param azurePolicyEnabled bool = true

@description('Optional. Specifies the azure policy version to use.')
param azurePolicyVersion string = 'v2'

@description('Optional. Specifies whether the KeyvaultSecretsProvider add-on is enabled or not.')
#disable-next-line secure-secrets-in-params // Not a secret
param enableKeyvaultSecretsProvider bool = false

@allowed([
  'false'
  'true'
])
@description('Optional. Specifies whether the KeyvaultSecretsProvider add-on uses secret rotation.')
#disable-next-line secure-secrets-in-params // Not a secret
param enableSecretRotation string = 'false'

@description('Optional. Running in Kubenet is disabled by default due to the security related nature of AAD Pod Identity and the risks of IP spoofing.')
param podIdentityProfileAllowNetworkPluginKubenet bool = false

@description('Optional. Whether the pod identity addon is enabled.')
param podIdentityProfileEnable bool = false

@description('Optional. The pod identities to use in the cluster.')
param podIdentityProfileUserAssignedIdentities array = []

@description('Optional. The user assigned identity to use for the kubelet.')
param kubeletUserAssignedIdentityResourceId string = ''

@description('Optional. The pod identity exceptions to allow.')
param podIdentityProfileUserAssignedIdentityExceptions array = []

@description('Optional. Whether to enable Azure Defender.')
param enableAzureDefender bool = false

@description('Optional. Specifies whether the OMS agent is enabled.')
param omsAgentEnabled bool = true

@description('Optional. Resource ID of the monitoring log analytics workspace.')
param monitoringWorkspaceId string = ''

@description('Optional. Tags of the resource.')
param tags object = {}

var identityType = systemAssignedIdentity ? 'SystemAssigned' : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var identity = {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
}

var aksClusterLinuxProfile = {
  adminUsername: aksClusterAdminUsername
  ssh: {
    publicKeys: [
      {
        keyData: aksClusterSshPublicKey
      }
    ]
  }
}

var lbProfile = {
  managedOutboundIPs: {
    count: managedOutboundIPCount
  }
  effectiveOutboundIPs: []
}

resource managedCluster 'Microsoft.ContainerService/managedClusters@2022-07-01' = {
  name: name
  location: location
  tags: tags
  identity: identity
  sku: {
    name: 'Basic'
    tier: aksClusterSkuTier
  }
  properties: {
    identityProfile: {
      kubeletidentity: {
        resourceId: kubeletUserAssignedIdentityResourceId
      }
    }
    kubernetesVersion: (empty(aksClusterKubernetesVersion) ? null : aksClusterKubernetesVersion)
    dnsPrefix: aksClusterDnsPrefix
    agentPoolProfiles: primaryAgentPoolProfile
    linuxProfile: (empty(aksClusterSshPublicKey) ? null : aksClusterLinuxProfile)
    servicePrincipalProfile: (empty(aksServicePrincipalProfile) ? null : aksServicePrincipalProfile)
    addonProfiles: {
      httpApplicationRouting: {
        enabled: httpApplicationRoutingEnabled
      }
      ingressApplicationGateway: {
        enabled: ingressApplicationGatewayEnabled && !empty(appGatewayResourceId)
        config: {
          applicationGatewayId: !empty(appGatewayResourceId) ? any(appGatewayResourceId) : null
          effectiveApplicationGatewayId: !empty(appGatewayResourceId) ? any(appGatewayResourceId) : null
        }
      }
      omsagent: {
        enabled: omsAgentEnabled && !empty(monitoringWorkspaceId)
        config: {
          logAnalyticsWorkspaceResourceID: !empty(monitoringWorkspaceId) ? any(monitoringWorkspaceId) : null
        }
      }
      aciConnectorLinux: {
        enabled: aciConnectorLinuxEnabled
      }
      azurepolicy: {
        enabled: azurePolicyEnabled
        config: {
          version: azurePolicyVersion
        }
      }
      azureKeyvaultSecretsProvider: {
        enabled: enableKeyvaultSecretsProvider
        config: {
          enableSecretRotation: enableSecretRotation
        }
      }
    }
    enableRBAC: enableRBAC
    disableLocalAccounts: disableLocalAccounts
    nodeResourceGroup: nodeResourceGroup
    networkProfile: {
      networkPlugin: !empty(aksClusterNetworkPlugin) ? any(aksClusterNetworkPlugin) : null
      networkPolicy: !empty(aksClusterNetworkPolicy) ? any(aksClusterNetworkPolicy) : null
      podCidr: !empty(aksClusterPodCidr) ? aksClusterPodCidr : null
      serviceCidr: !empty(aksClusterServiceCidr) ? aksClusterServiceCidr : null
      dnsServiceIP: !empty(aksClusterDnsServiceIP) ? aksClusterDnsServiceIP : null
      dockerBridgeCidr: !empty(aksClusterDockerBridgeCidr) ? aksClusterDockerBridgeCidr : null
      outboundType: aksClusterOutboundType
      loadBalancerSku: aksClusterLoadBalancerSku
      loadBalancerProfile: managedOutboundIPCount != 0 ? lbProfile : null
    }
    aadProfile: {
      clientAppID: aadProfileClientAppID
      serverAppID: aadProfileServerAppID
      serverAppSecret: aadProfileServerAppSecret
      managed: aadProfileManaged
      enableAzureRBAC: aadProfileEnableAzureRBAC
      adminGroupObjectIDs: aadProfileAdminGroupObjectIDs
      tenantID: aadProfileTenantId
    }
    apiServerAccessProfile: {
      authorizedIPRanges: authorizedIPRanges
      disableRunCommand: disableRunCommand
      enablePrivateCluster: true
      enablePrivateClusterPublicFQDN: true
      privateDNSZone: privateDNSZoneResourceId
    }
    podIdentityProfile: {
      allowNetworkPluginKubenet: podIdentityProfileAllowNetworkPluginKubenet
      enabled: podIdentityProfileEnable
      userAssignedIdentities: podIdentityProfileUserAssignedIdentities
      userAssignedIdentityExceptions: podIdentityProfileUserAssignedIdentityExceptions
    }
    securityProfile: enableAzureDefender ? {
      azureDefender: {
        enabled: enableAzureDefender
        logAnalyticsWorkspaceResourceId: !empty(monitoringWorkspaceId) ? monitoringWorkspaceId : null
      }
    } : null
  }
}

module managedCluster_agentPools 'agentPools/deploy.bicep' = [for (agentPool, index) in agentPools: {
  name: '${uniqueString(deployment().name, location)}-ManagedCluster-AgentPool-${index}'
  params: {
    managedClusterName: managedCluster.name
    name: agentPool.name
    availabilityZones: contains(agentPool, 'availabilityZones') ? agentPool.availabilityZones : []
    count: contains(agentPool, 'count') ? agentPool.count : 1
    sourceResourceId: contains(agentPool, 'sourceResourceId') ? agentPool.sourceResourceId : ''
    enableAutoScaling: contains(agentPool, 'enableAutoScaling') ? agentPool.enableAutoScaling : false
    enableEncryptionAtHost: contains(agentPool, 'enableEncryptionAtHost') ? agentPool.enableEncryptionAtHost : false
    enableFIPS: contains(agentPool, 'enableFIPS') ? agentPool.enableFIPS : false
    enableNodePublicIP: contains(agentPool, 'enableNodePublicIP') ? agentPool.enableNodePublicIP : false
    enableUltraSSD: contains(agentPool, 'enableUltraSSD') ? agentPool.enableUltraSSD : false
    gpuInstanceProfile: contains(agentPool, 'gpuInstanceProfile') ? agentPool.gpuInstanceProfile : ''
    kubeletDiskType: contains(agentPool, 'kubeletDiskType') ? agentPool.kubeletDiskType : ''
    maxCount: contains(agentPool, 'maxCount') ? agentPool.maxCount : -1
    maxPods: contains(agentPool, 'maxPods') ? agentPool.maxPods : -1
    minCount: contains(agentPool, 'minCount') ? agentPool.minCount : -1
    mode: contains(agentPool, 'mode') ? agentPool.mode : ''
    nodeLabels: contains(agentPool, 'nodeLabels') ? agentPool.nodeLabels : {}
    nodePublicIpPrefixId: contains(agentPool, 'nodePublicIpPrefixId') ? agentPool.nodePublicIpPrefixId : ''
    nodeTaints: contains(agentPool, 'nodeTaints') ? agentPool.nodeTaints : []
    orchestratorVersion: contains(agentPool, 'orchestratorVersion') ? agentPool.orchestratorVersion : ''
    osDiskSizeGB: contains(agentPool, 'osDiskSizeGB') ? agentPool.osDiskSizeGB : -1
    osDiskType: contains(agentPool, 'osDiskType') ? agentPool.osDiskType : ''
    osSku: contains(agentPool, 'osSku') ? agentPool.osSku : ''
    osType: contains(agentPool, 'osType') ? agentPool.osType : 'Linux'
    podSubnetId: contains(agentPool, 'podSubnetId') ? agentPool.podSubnetId : ''
    proximityPlacementGroupId: contains(agentPool, 'proximityPlacementGroupId') ? agentPool.proximityPlacementGroupId : ''
    scaleDownMode: contains(agentPool, 'scaleDownMode') ? agentPool.scaleDownMode : 'Delete'
    scaleSetEvictionPolicy: contains(agentPool, 'scaleSetEvictionPolicy') ? agentPool.scaleSetEvictionPolicy : 'Delete'
    scaleSetPriority: contains(agentPool, 'scaleSetPriority') ? agentPool.scaleSetPriority : ''
    spotMaxPrice: contains(agentPool, 'spotMaxPrice') ? agentPool.spotMaxPrice : -1
    tags: contains(agentPool, 'tags') ? agentPool.tags : {}
    type: contains(agentPool, 'type') ? agentPool.type : ''
    maxSurge: contains(agentPool, 'maxSurge') ? agentPool.maxSurge : ''
    vmSize: contains(agentPool, 'vmSize') ? agentPool.vmSize : 'Standard_D2s_v3'
    vnetSubnetId: contains(agentPool, 'vnetSubnetId') ? agentPool.vnetSubnetId : ''
    workloadRuntime: contains(agentPool, 'workloadRuntime') ? agentPool.workloadRuntime : ''
  }
}]

@description('The resource ID of the managed cluster.')
output resourceId string = managedCluster.id

@description('The resource group the managed cluster was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The name of the managed cluster.')
output name string = managedCluster.name

@description('The control plane FQDN of the managed cluster.')
output controlPlaneFQDN string = managedCluster.properties.privateFQDN

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = systemAssignedIdentity && contains(managedCluster.identity, 'principalId') ? managedCluster.identity.principalId : ''

@description('The Object ID of the AKS identity.')
output kubeletidentityObjectId string = contains(managedCluster.properties, 'identityProfile') ? contains(managedCluster.properties.identityProfile, 'kubeletidentity') ? managedCluster.properties.identityProfile.kubeletidentity.objectId : '' : ''

@description('The Object ID of the OMS agent identity.')
output omsagentIdentityObjectId string = contains(managedCluster.properties, 'addonProfiles') ? contains(managedCluster.properties.addonProfiles, 'omsagent') ? contains(managedCluster.properties.addonProfiles.omsagent, 'identity') ? managedCluster.properties.addonProfiles.omsagent.identity.objectId : '' : '' : ''

@description('The location the resource was deployed into.')
output location string = managedCluster.location

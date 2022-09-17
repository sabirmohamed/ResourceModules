param diskEncryptionSetIdentity string
param keyvaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyvaultName
}

// Assign RBAC role Key Vault Crypto User
resource diskEncr_cmk_rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(split(keyVault.id, '/')[2], split(keyVault.id, '/')[4], '12338af0-0e69-4776-bea7-57ae8d297424', diskEncryptionSetIdentity)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '12338af0-0e69-4776-bea7-57ae8d297424')
    principalId: diskEncryptionSetIdentity
    principalType: 'ServicePrincipal'
  }
  scope: keyVault
}

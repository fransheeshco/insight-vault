@description('Location for Virtual Network.')
param location string

@description('Name for Virtual Network.')
param vnetName string = 'insightVaultVnet'

@description('Name for subnet-1')
param subnet1name string = 'Subnet-1'

@description('Name for subnet-2')
param subnet2name string = 'Subnet-2'

@description('Address prefix for the virtual network.')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Address prefix for Subnet 1.')
param subnet1AddressPrefix string = '10.0.0.0/24'

@description('Address prefix for Subnet 2.')
param subnet2AddressPrefix string = '10.0.1.0/24'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1name
        properties: {
          addressPrefix: subnet1AddressPrefix
        }
      }
      {
        name: subnet2name
        properties: {
          addressPrefix: subnet2AddressPrefix
        }
      }
    ]
  }
}

output vnetId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
output subnet1Id string = virtualNetwork.properties.subnets[0].id
output subnet2Id string = virtualNetwork.properties.subnets[1].id

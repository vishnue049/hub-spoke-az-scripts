#cloud-config
package_upgrade: true
packages:
  - nginx
  - stress
  - unzip
  - jq
  - net-tools
  - curl

runcmd:
  - service nginx restart
  - systemtl enable nginx
  - echo "<h1>$(cat /etc/hostname)</h1>"  >> /var/www/html/index.nginx-debian.html
  
#HUG RG
#Creating Respurce Group for HUB
RG='VISHNU-HUB-RG'
az group create --location eastus -n ${RG}

#Creating Vnet for HUB
az network vnet create -g ${RG} -n ${RG}-vNET1 --address-prefix 10.34.0.0/16 \
    --subnet-name jump-svr-subnet-1 --subnet-prefix 10.34.1.0/24 -l eastus
az network vnet subnet create -g ${RG} --vnet-name ${RG}-vNET1 -n GatewaySubnet \
    --address-prefixes 10.34.20.0/24
az network vnet subnet create -g ${RG} --vnet-name ${RG}-vNET1 -n AzureFirewallSubnet \
    --address-prefixes 10.34.10.0/24
az network vnet subnet create -g ${RG} --vnet-name ${RG}-vNET1 -n AzureBastionSubnet \
    --address-prefixes 10.34.30.0/24


# Enable Azure Bastion for the virtual network
az network bastion create --name AzureBastion --resource-group ${RG} --vnet-name ${RG}-vNET1 --location eastus --public-ip-address VISHNU-HUB-RG-vNET1-ip

#Creating NSG rules for HUB
echo "Creating NSG and NSG Rule"
az network nsg create -g ${RG} -n ${RG}_NSG1
az network nsg rule create -g ${RG} --nsg-name ${RG}_NSG1 -n ${RG}_NSG1_RULE1 --priority 100 \
    --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' \
    --destination-port-ranges '*' --access Allow --protocol Tcp --description "Allowing All Traffic For Now"
az network nsg rule create -g ${RG} --nsg-name ${RG}_NSG1 -n ${RG}_NSG1_RULE2 --priority 101 \
    --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' \
    --destination-port-ranges '*' --access Allow --protocol Icmp --description "Allowing ICMP Traffic For Now"

#Creating VM for HUB-Linux
IMAGE='Canonical:0001-com-ubuntu-server-focal-daily:20_04-daily-lts-gen2:latest'

echo "Creating Virtual Machines"
az vm create --resource-group ${RG} --name JUMPLINUXVM1 --image $IMAGE --vnet-name ${RG}-vNET1 \
    --subnet jump-svr-subnet-1 --admin-username vishnu --admin-password "Random@123456" --size Standard_B1s \
    --nsg ${RG}_NSG1 --storage-sku StandardSSD_LRS --private-ip-address 10.34.1.10 \
    --zone 1 --custom-data ./clouddrive/cloud-init3.txt

#SPOKE1-RG
#Creating Resource Group for Spoke1
RG='VISHNU-SP1-RG'
az group create --location eastus -n ${RG}

#Creating VNet for Spoke1
az network vnet create -g ${RG} -n ${RG}-vNET1 --address-prefix 172.16.0.0/16 \
    --subnet-name ${RG}-Subnet-1 --subnet-prefix 172.16.1.0/24 -l eastus

#Creating NSG rules for Spoke1
echo "Creating NSG and NSG Rule"
az network nsg create -g ${RG} -n ${RG}_NSG1
az network nsg rule create -g ${RG} --nsg-name ${RG}_NSG1 -n ${RG}_NSG1_RULE1 --priority 100 \
    --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' \
    --destination-port-ranges '*' --access Allow --protocol Tcp --description "Allowing All Traffic For Now"
az network nsg rule create -g ${RG} --nsg-name ${RG}_NSG1 -n ${RG}_NSG1_RULE2 --priority 101 \
    --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' \
    --destination-port-ranges '*' --access Allow --protocol Icmp --description "Allowing ICMP Traffic For Now"

#Creating VM for Spoke1-Linux
IMAGE='Canonical:0001-com-ubuntu-server-focal-daily:20_04-daily-lts-gen2:latest'

echo "Creating Virtual Machines"
az vm create --resource-group ${RG} --name SP1LINUXVM1 --image $IMAGE --vnet-name ${RG}-vNET1 \
    --subnet ${RG}-Subnet-1 --admin-username vishnu --admin-password "Random@123456" --size Standard_B1s \
    --nsg ${RG}_NSG1 --storage-sku StandardSSD_LRS --private-ip-address 172.16.1.10 \
    --zone 1 --custom-data ./clouddrive/cloud-init3.txt

#SPOKE2-RG
#Creating Resource Group for Spoke2
RG='VISHNU-SP2-RG'
az group create --location westus -n ${RG}

#Creating VNet for Spoke2
az network vnet create -g ${RG} -n ${RG}-vNET1 --address-prefix 172.17.0.0/16 \
    --subnet-name ${RG}-Subnet-1 --subnet-prefix 172.17.1.0/24 -l westus

#Creating NSG rules for Spoke2
echo "Creating NSG and NSG Rule"
az network nsg create -g ${RG} -n ${RG}_NSG1 -l westus
az network nsg rule create -g ${RG} --nsg-name ${RG}_NSG1 -n ${RG}_NSG1_RULE1 --priority 100 \
    --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' \
    --destination-port-ranges '*' --access Allow --protocol Tcp --description "Allowing All Traffic For Now"
az network nsg rule create -g ${RG} --nsg-name ${RG}_NSG1 -n ${RG}_NSG1_RULE2 --priority 101 \
    --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' \
    --destination-port-ranges '*' --access Allow --protocol Icmp --description "Allowing ICMP Traffic For Now"

#Creating VM for Spoke2 - Linux
IMAGE='Canonical:0001-com-ubuntu-server-focal-daily:20_04-daily-lts-gen2:latest'

echo "Creating Virtual Machines"
az vm create --resource-group ${RG} --name SP2LINUXVM1 --location westus --image $IMAGE --vnet-name ${RG}-vNET1 \
    --subnet ${RG}-Subnet-1 --admin-username vishnu --admin-password "Random@123456" --size Standard_B1s \
    --nsg ${RG}_NSG1 --storage-sku StandardSSD_LRS --private-ip-address 172.17.1.10 \
    --custom-data ./clouddrive/cloud-init3.txt



#VNET-PEERINGS
VNet1Id=$(az network vnet show --resource-group VISHNU-HUB-RG --name VISHNU-HUB-RG-vNET1 --query id --out tsv)
VNet2Id=$(az network vnet show --resource-group VISHNU-SP1-RG --name VISHNU-SP1-RG-vNET1 --query id --out tsv)
VNet3Id=$(az network vnet show --resource-group VISHNU-SP2-RG --name VISHNU-SP2-RG-vNET1 --query id --out tsv)
#HUBRG-to-SPOKE1
az network vnet peering create -g VISHNU-HUB-RG -n HUB-to-SPOKE1 --vnet-name VISHNU-HUB-RG-vNET1 --remote-vnet $VNet2Id --allow-vnet-access
az network vnet peering create -g VISHNU-SP1-RG -n SPOKE1-to-HUB --vnet-name VISHNU-SP1-RG-vNET1 --remote-vnet $VNet1Id --allow-vnet-access
#SPOKE1-to-SPOKE2
az network vnet peering create -g VISHNU-SP1-RG -n SPOKE1-to-SPOKE2 --vnet-name VISHNU-SP1-RG-vNET1 --remote-vnet $VNet3Id --allow-vnet-access
az network vnet peering create -g VISHNU-SP2-RG -n SPOKE2-to-SPOKE1 --vnet-name VISHNU-SP2-RG-vNET1 --remote-vnet $VNet1Id --allow-vnet-access
#HUBRG-to-SPOKE2
az network vnet peering create -g VISHNU-HUB-RG -n HUB-to-SPOKE2 --vnet-name VISHNU-HUB-RG-vNET1 --remote-vnet $VNet3Id --allow-vnet-access
az network vnet peering create -g VISHNU-SP2-RG -n SPOKE2-to-HUB --vnet-name VISHNU-SP2-RG-vNET1 --remote-vnet $VNet1Id --allow-vnet-access
#HUBRG-to-SPOKE3
#az network vnet peering create -g HUB-RG -n HUB-to-SPOKE2 --vnet-name HUB-RG-vNET1 --remote-vnet $VNet4Id --allow-vnet-access
#az network vnet peering create -g SPOKE2-RG -n SPOKE2-to-HUB --vnet-name SPOKE2-RG-vNET1 --remote-vnet $VNet1Id --allow-vnet-access
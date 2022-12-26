#!/bin/bash

set -xe
set -o pipefail

RG=lxdtest
REGION=southeastasia
NSGNAME=mynsg
VNETNAME=myvnet
SUBNETNAME=mysubnet
SUBNET_PREFIX=10.0.1.0/24
VMSIZE=Standard_D2s_v4

# target specific settings
TGTNAME=lxd
TGT_MAX_CONTAINERS=4

# client specific settings
CLIENTNAME=client

az group create -n $RG -l $REGION
az network nsg create -g $RG -n $NSGNAME
az network vnet create -g $RG -n $VNETNAME \
    --subnet-name $SUBNETNAME \
    --subnet-prefixes $SUBNET_PREFIX \
    --nsg $NSGNAME

# for MS corpnet access https://github.com/Azure/azure-cli/issues/13320#issuecomment-649867249
az network nsg rule create \
    -g $RG --nsg-name $NSGNAME -n "corpnet" --priority 100 \
    --source-address-prefixes CorpNetPublic \
    --destination-port-ranges 22 \
    --direction Inbound --access Allow --protocol Tcp \
    --description "Allow SSH from CorpNet"

provision_vm() {
    VMNAME=$1
    az network public-ip create -g $RG -n $VMNAME --sku Standard
    az network nic create -g $RG -n $VMNAME \
        --vnet-name $VNETNAME --subnet $SUBNETNAME \
        --public-ip-address $VMNAME \
        --ip-forwarding true
    az vm create -n $VMNAME -g $RG \
        --size $VMSIZE \
        --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest \
        --nics $VMNAME \
        --custom-data cloud-init.txt \
        --ssh-key-values ~/.ssh/id_rsa.pub
}

# create a lxd vm where we install the main things
provision_vm $TGTNAME
for i in `seq $TGT_MAX_CONTAINERS`; do
    az network nic ip-config create -g $RG --nic-name $TGTNAME -n "c$i" 
done

TGTPIP=`az vm show -g $RG -n $TGTNAME -d --query publicIps -otsv`
echo "public IP for target: $TGTPIP"

# Install CNI
# ssh ubuntu@$TGTPIP 'wget https://raw.githubusercontent.com/Azure/azure-container-networking/master/scripts/install-cni-plugin.sh && sudo bash install-cni-plugin.sh v1.4.39 v1.0.1'
rsync -av lxd-*.sh ubuntu@$TGTPIP:/home/ubuntu/

# # create a testing vm where we access containers
# provision_vm $CLIENTNAME
# CLIENTIP=`az vm show -g $RG -n $CLIENTNAME -d --query publicIps -otsv`
# echo "public IP for client: $CLIENTIP"

# reboot tgt
az vm restart -g $RG -n $TGTNAME

# all done, show vms again
az vm list -g $RG -otable -d

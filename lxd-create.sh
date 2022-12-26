#!/bin/bash
set -ex
set -o pipefail
# we need a profile that doesn't have network configured at all, and we can only
# provision container, not VM
# make sure to run this script with root
profile=$1
image=$2
cname=$3

lxc launch --profile $profile $image $cname
pid=`lxc query /1.0/instances/$cname/state | jq .pid`
netns_name=`echo $cname | md5sum | cut -d ' ' -f 1`
ip netns attach $netns_name $pid
netns=/proc/$pid/ns/net

# copying things from https://github.com/Azure/azure-container-networking/blob/master/scripts/docker-run.sh
export CNI_CONTAINERID=$netns_name
export CNI_PATH='/opt/cni/bin'
export CNI_COMMAND='ADD'
export PATH=$CNI_PATH:$PATH
export CNI_NETNS=$netns
args=$(printf "K8S_POD_NAMESPACE=%s;K8S_POD_NAME=%s" lxc $cname)
export CNI_ARGS=$args
export CNI_IFNAME='eth0'

config=$(jq '.plugins[0]' /etc/cni/net.d/10-azure.conflist)
name=$(jq -r '.name' /etc/cni/net.d/10-azure.conflist)
config=$(echo $config | jq --arg name $name '. + {name: $name}')
cniVersion=$(jq -r '.cniVersion' /etc/cni/net.d/10-azure.conflist)
config=$(echo $config | jq --arg cniVersion $cniVersion '. + {cniVersion: $cniVersion}')

res=$(echo $config | azure-vnet)

if [ $? -ne 0 ]; then
	errmsg=$(echo $res | jq -r '.msg')
	if [ -z "$errmsg" ]; then
		errmsg=$res
	fi
	echo "${name} : error executing $CNI_COMMAND: $errmsg"
	exit 1
elif [[ ${DEBUG} -gt 0 ]]; then
	echo ${res} | jq -r .
fi

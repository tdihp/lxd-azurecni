#!/bin/bash
if [ $# -ne 1 ]; then
	echo "usage: lxd-delete.sh <name>"
	exit 1
fi

set -ex
set -o pipefail
cname=$1
pid=`lxc query /1.0/instances/$cname/state | jq .pid`
netns_name=`echo $cname | md5sum | cut -d ' ' -f 1`
netns=/proc/$pid/ns/net
export CNI_CONTAINERID=$netns_name
export CNI_PATH='/opt/cni/bin'
export CNI_COMMAND='DEL'
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

lxc stop $cname
lxc delete $cname
ip netns delete $netns_name

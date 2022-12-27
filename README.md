This is an example for lxd users to use azure-CNI for provisioning IP for
container.

For lxd integration, follows [calico-for-lxc-and-lxd][1]; For azure-CNI
invoking, follows [Azure Container Networking scripts][2].

[1]: https://github.com/quater/calico-for-lxc-and-lxd/tree/master/scripts/lxd
[2]: https://github.com/Azure/azure-container-networking/tree/master/scripts

The code is currently not complete, and the current repository serve as a test
environment for azure-cni Docker.

# Instructions

1. Read and apply `provision.sh` for provisioning sample resources.
2. initialize lxd

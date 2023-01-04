This is an example for lxd users to use azure-CNI for provisioning IP for
container.

For lxd integration, follows [calico-for-lxc-and-lxd][1]; For azure-CNI
invoking, follows [Azure Container Networking scripts][2].

[1]: https://github.com/quater/calico-for-lxc-and-lxd/tree/master/scripts/lxd
[2]: https://github.com/Azure/azure-container-networking/tree/master/scripts

# Instructions

1. Read and apply `provision.sh` for provisioning sample resources.
2. ssh to the provisioned nodes
3. To start a lxd container: `./lxd-create.sh default ubuntu:20.04 foobar`. 
4. Start a service inside the container: `lxc exec foobar -- bash`, then `python3 -m http.server`.
5. observe the assigned IP by `lxc list`
6. try `curl -vm5 http://<container-ip>:8000`.

# Limitation

For now only 20.04 has been tested.

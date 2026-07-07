# Day 2: Provisioning Jumpbox Container (Jumpainer, hehe)

Because I lack one physical machine (or a VM that could be easily shared between workstations I use), a Dev Container was made.

Dev Containers allow developers to have the same development environment - this can also be used in terms of jumpbox, but some additional ssh key exchange will have to be done once we try to use a different workstation in order to access the cluster.

The `.devcontainer/devcontainer.json` contains definition of the container. When se click "Reopen in Container", for the first time, everything in the spec will be executed. When the container is recreated, the commands will execute again (steps defined via a script in `postCreateCommand`). Of course, if the container already exists on the workstation and is simply being restarted, downloading of binaries won't happen as defined in `.devcontainer/setup.sh` (they're already installed in the container, duuh).

That's basically it.
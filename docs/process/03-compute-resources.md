# Day 3: Compute Resources

In this lab, we're generating SSH key pair on the Jumptainer and sending them over to the K8s server and nodes. This lab may have to be executed every time we're (re)creating the container, because of containers' ephemeral nature.

The instructions also require enabling the root access to the machines, but we've already covered this in [Day 1 lab](../process/01-initial-provisioning.md).

## Step 1: Create a Machine Database

It's basically just a text file that helps us with copying over the files in a timely manner. We've created and committed one in the `machines.txt`.

## Step 2: Generate a SSH key and Distribute it

All of the below commands are executed on the Jumptainer.

Create a keypair:

```bash
ssh-keygen
```

Distribute the public key to machines defined in the [machines database](../../machines.txt). The ``ssh-copy-id` command is a simple preinstalled script that in a nutshell:

1. Reads your local public key
2. Connects to the remote server
3. Creates the ~/.ssh directory on the remote host if it doesn't exist
4. Creates or updates the `~/.ssh/authorized_keys` file
5. Appends the public key to `authorized_keys` if it's not already there
6. Sets appropriate permissions

Distribution of the keys:

```bash
while read IP FQDN HOST SUBNET; do
  ssh-copy-id root@${IP}
done < machines.txt
```

Verify connections are working:

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n root@${IP} hostname
done < machines.txt
```

## Step 3: Assign hostnames

Hostnames are basically defined to some extent, but not trully. Setting the hostname during the OS installation only sets the `/etc/hostname` but does not mean that the machine will be capable of resolving its own hostname to the IP. The hostname set during the OS install only tells the kernel "my name is `somethingsomething`".

The bellow command will add a following entry to the `/etc/hosts` file on each machine: `127.0.1.1 <fqdn> <hostname>`.

On Debian systems, 127.0.1.1 is conventionally used as the machine's own hostname when the machine doesn't have a stable local IP address. This avoids situations where programs expect localhost to resolve only to localhost. Typical Ubuntu install should already do this (supposedly).

```bash
while read IP FQDN HOST SUBNET; do
    CMD="sed -i 's/^127.0.1.1.*/127.0.1.1\t${FQDN} ${HOST}/' /etc/hosts"
    ssh -n root@${IP} "$CMD"
    ssh -n root@${IP} hostnamectl set-hostname ${HOST}
    ssh -n root@${IP} systemctl restart systemd-hostnamed
done < machines.txt
```

The machines can resolve themselves at this point (as they would via localhost already). The issue now is that the machines still don't know hostnames of each other. Doing a `ping k8s-002` from `k8s-001` would fail, because name or service is not known. I think this could be solved via mDNS, though (**TODO: check mDNS**), but the tutorial proposes addding entries of all machines to all machines, you get the point.

This command simply creates a hosts file from `machines.txt` data that will be distributed to all machines:

```bash
touch hosts
echo "# Kubernetes The Hard Way" >> hosts

while read IP FQDN HOST SUBNET; do
    ENTRY="${IP} ${FQDN} ${HOST}"
    echo $ENTRY >> hosts
done < machines.txt
```

Now add hosts info to Jumptainer and others:
```bash
# Add to self :)
cat hosts >> /etc/hosts

# Others:
while read IP FQDN HOST SUBNET; do
  ssh root@${HOST} hostname # Check whether connection can be really establisted via hostnames now
  scp hosts root@${HOST}:~/
  ssh -n \
    root@${HOST} "cat hosts >> /etc/hosts"
done < machines.txt
```

Pings from each other now gives pongs!
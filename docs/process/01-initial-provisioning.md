# Day 1: Provisioning Resources

I installed Debian 13 (Trixie) on the Mini PCs that I got. Note that the tutorial proposes usage of Debian 12.

## List of Machines

| IP           | Hostname |   |   |   |
|--------------|----------|---|---|---|
| 192.168.1.10 | k8s-001  |   |   |   |
| 192.168.1.11 | k8s-002  |   |   |   |
|              |          |   |   |   |

No jump server was setup at this point. The goal is to make jump server reproducible and environment easily configurarable on multiple workstations.

## Step 1: Install the OS

Os was installed with a USB stick and without access to the internet due to some bad luck with wired access to the router.

Just a clean install, next, next, I give you my kidney, next, finish.

## Step 2: Configure Static IP

This one is logical and could either be done on the router via DHCP reservation or via machine config. I chose the latter.

First find the ethernet interface name:
```bash
ip addr link
```

Then create an entry in `/etc/network/interfaces`:
```
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

#  enp1s0
auto enp1s0
        iface enp1s0 inet static
        address 192.168.1.10
        netmask 255.255.255.0
        gateway 192.168.1.1
        dns-nameservers 1.1.1.1 1.1.1.0
```

Then restart the network:
```
systemctl restart networking
```

**TODO:** [**INTERFACES(5) MANUAL**](https://manpages.debian.org/trixie/ifupdown/interfaces.5.en.html)
[NetworkConfiguration](https://wiki.debian.org/NetworkConfiguration)

## Step 3: Add the APT sources and upgrade packages

in `/etc/apt/sources.list.d/debian.sources`, add:

```
cat: /etc/apt/sources.list.d/debian.resources: No such file or directory
root@k8s-001:~# cat /etc/apt/sources.list.d/debian.sources
Types: deb deb-src
URIs: https://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb deb-src
URIs: https://deb.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```
**TODO:** [SourcesList](https://wiki.debian.org/SourcesList)

Then update the local registry (?) and upgrade installed packages:

```
apt update && apt upgrade -y
```

In case there are issues that the nameserver is not resolved during `apt update`, run:
```
eccho "nameserver 1.1.1.1" | tee /etc/resolv.conf
```

There are supposedly issues when the packages resolving the `dns-nameservers` from the sources list are not yet installed and this has to be done manually or something.

**TODO:** dig in

## Step 4: install SSH server and some basic packages

Now that the basic packages are installed and upgraded, run `tasksel` to install Open SSH server. and later run `tasksel install standard` to install some basic packages.

**TODO:** Debian tasks? Is this the appropriate way of doing it in 13?

Then because sudo and curl were not on the machine by default and to add some other important stuff. 

```
sudo apt install curl sudo git
```


## Step 5: Enable Open SSH server sudo access

Open SSH does not permit root login by default, we're enabling it due to this cluster being only in local premises as proposed by the tutorial itself.

Uncomment line `PermitRootLogin` and change value to `yes`. Of course, keys will have to be defined to at least secure it to some degree.

```
systemctl restart sshd
```

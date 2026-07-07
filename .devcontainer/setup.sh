#!/usr/bin/env bash
# Runs once on container creation (postCreateCommand).
# Automates all setup steps from docs/tutorial/02-jumpbox.md.
set -euo pipefail

WORKDIR="/workspaces/kubernetes-the-hard-way"
cd "$WORKDIR"

echo "==> Installing prerequisites..."
apt-get update -q
apt-get install -y wget curl vim openssl git

echo "==> Detecting architecture..."
ARCH=$(dpkg --print-architecture)
echo "    Architecture: $ARCH"

# Skip binary download if already done (container stop/start reuse case)
if [ -f "downloads/client/kubectl" ]; then
  echo "==> Binaries already downloaded, skipping."
else
  echo "==> Downloading Kubernetes binaries (this may take a while)..."
  wget -q --show-progress \
    --https-only \
    --timestamping \
    -P downloads \
    -i "downloads-${ARCH}.txt"

  echo "==> Extracting binaries..."
  mkdir -p downloads/{client,cni-plugins,controller,worker}

  tar -xf "downloads/crictl-v1.32.0-linux-${ARCH}.tar.gz" \
    -C downloads/worker/

  tar -xf "downloads/containerd-2.1.0-beta.0-linux-${ARCH}.tar.gz" \
    --strip-components 1 \
    -C downloads/worker/

  tar -xf "downloads/cni-plugins-linux-${ARCH}-v1.6.2.tgz" \
    -C downloads/cni-plugins/

  tar -xf "downloads/etcd-v3.6.0-rc.3-linux-${ARCH}.tar.gz" \
    -C downloads/ \
    --strip-components 1 \
    "etcd-v3.6.0-rc.3-linux-${ARCH}/etcdctl" \
    "etcd-v3.6.0-rc.3-linux-${ARCH}/etcd"

  mv downloads/{etcdctl,kubectl} downloads/client/
  mv downloads/{etcd,kube-apiserver,kube-controller-manager,kube-scheduler} \
    downloads/controller/
  mv downloads/{kubelet,kube-proxy} downloads/worker/
  mv "downloads/runc.${ARCH}" downloads/worker/runc

  rm -f downloads/*.gz downloads/*.tgz

  chmod +x downloads/{client,cni-plugins,controller,worker}/*
  echo "==> Binaries extracted and made executable."
fi

echo "==> Installing kubectl to /usr/local/bin/..."
cp downloads/client/kubectl /usr/local/bin/

echo "==> Verifying kubectl..."
kubectl version --client

echo ""

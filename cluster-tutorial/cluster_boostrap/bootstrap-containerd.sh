#!/usr/bin/env bash

{
  sudo apt-get update
  sudo apt-get -y install socat conntrack ipset
  sudo swapoff -a
}

# Download and Install Worker Binaries
# wget -q --show-progress --https-only --timestamping \
#   https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.20.0/crictl-v1.20.0-linux-amd64.tar.gz \
#   https://github.com/opencontainers/runc/releases/download/v1.0.0-rc91/runc.amd64 \
#   https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz \
#   https://github.com/containerd/containerd/releases/download/v1.3.6/containerd-1.3.6-linux-amd64.tar.gz \
#   https://storage.googleapis.com/kubernetes-release/release/v1.20.6/bin/linux/amd64/kubectl \
#   https://storage.googleapis.com/kubernetes-release/release/v1.20.6/bin/linux/amd64/kube-proxy \
#   https://storage.googleapis.com/kubernetes-release/release/v1.20.6/bin/linux/amd64/kubelet

# PRE_SETUP FOR CONTAINERD
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# REF: https://github.com/containerd/containerd/blob/master/docs/cri/installation.md

# Install required library for seccomp.

{
    sudo apt-get update
    sudo apt-get install libseccomp2
}

# Download release tarball for the containerd version you want to install from the GCS bucket.
# Validate checksum of the release tarball:
{
VERSION="1.4.3"

wget -q --show-progress --https-only --timestamping \
https://github.com/containerd/containerd/releases/download/v${VERSION}/cri-containerd-cni-${VERSION}-linux-amd64.tar.gz \
https://github.com/containerd/containerd/releases/download/v${VERSION}/cri-containerd-cni-${VERSION}-linux-amd64.tar.gz.sha256sum \
https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl \
https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kube-proxy \
https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubelet

sha256sum --check cri-containerd-cni-${VERSION}-linux-amd64.tar.gz.sha256sum

}

# Install Containerd
# If you are using systemd, just simply unpack the tarball to the root directory:

{
  sudo tar --no-overwrite-dir -C / -xzf cri-containerd-cni-${VERSION}-linux-amd64.tar.gz
  sudo systemctl daemon-reload
  sudo systemctl start containerd
}

# Configure containerd:

{
  sudo mkdir -p /etc/containerd
  containerd config default | sudo tee /etc/containerd/config.toml
}

# Restart containerd:
sudo systemctl restart containerd

# Using the systemd cgroup driver
# To use the systemd cgroup driver in /etc/containerd/config.toml with runc, set

sudo vim /etc/containerd/config.toml

# Add SystemdCgroup=true under the appropriate section as shown below
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  ...
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true

#
sudo mkdir -p /etc/systemd/system/kubelet.service.d/
cd /etc/systemd/system/kubelet.service.d/

sudo vim 0-containerd.conf


# past the following there

# If you apply this change make sure to restart containerd again:

sudo systemctl restart containerd

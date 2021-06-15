#!/bin/bash

# To avoid having the file not present or found, enabling the bridge-netfilter
# Ref: http://zeeshanali.com/sysadmin/fixed-sysctl-cannot-stat-procsysnetbridgebridge-nf-call-iptables/
# https://ebtables.netfilter.org/documentation/bridge-nf.html

# set it to enabled for IPv4 addresses
echo "[TASK 1] Disable and turn off SWAP"
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

echo "[TASK 2] Stop and Disable firewall"
sudo systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 3] Enable and Load Kernel modules"

sudo cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "[TASK 4] Add Kernel settings"
sudo cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system >/dev/null 2>&1

sudo apt update -qq >/dev/null 2>&1

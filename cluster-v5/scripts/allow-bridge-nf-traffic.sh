#!/bin/bash

# To avoid having the file not present or found, enabling the bridge-netfilter
# Ref: http://zeeshanali.com/sysadmin/fixed-sysctl-cannot-stat-procsysnetbridgebridge-nf-call-iptables/
# https://ebtables.netfilter.org/documentation/bridge-nf.html

# Ensure that the module is loaded
lsmod | grep br_netfilter

# set it to enabled for IPv4 addresses
echo "[TASK 1] Disable and turn off SWAP"
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a
#### Ensure that the br_netfilter module is loaded on the controlplane and worker nodes

# echo "[TASK 2] Stop and Disable firewall"
# sudo systemctl disable --now ufw >/dev/null 2>&1

# echo "[TASK 3] Enable and Load Kernel modules"

# # Ensure that the module is loaded
# lsmod | grep br_netfilter

# # If the module is not loaded yet, follow the below steps
# cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
# br_netfilter
# EOF

# cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
# net.bridge.bridge-nf-call-ip6tables = 1
# net.bridge.bridge-nf-call-iptables = 1
# EOF

# sudo sysctl --system

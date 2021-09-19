#!/usr/bin/env bash

# {
#     wget -q --show-progress --https-only --timestamping \
#     "https://github.com/etcd-io/etcd/releases/download/v3.4.10/etcd-v3.4.10-linux-amd64.tar.gz"

#     tar -xvf etcd-v3.4.10-linux-amd64.tar.gz
#     sudo mv etcd-v3.4.10-linux-amd64/etcd* /usr/local/bin/

#     sudo mkdir -p /etc/etcd /var/lib/etcd
#     sudo chmod 700 /var/lib/etcd
#     sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/

#     INTERNAL_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)

#     # Set the etcd name to match the hostname of the current compute instance:
#     ETCD_NAME=$(hostname -s)

# cat <<EOF | sudo tee /etc/systemd/system/etcd.service
# [Unit]
# Description=etcd
# Documentation=https://github.com/coreos

# [Service]
# Type=notify
# ExecStart=/usr/local/bin/etcd \\
#   --name ${ETCD_NAME} \\
#   --cert-file=/etc/etcd/kubernetes.pem \\
#   --key-file=/etc/etcd/kubernetes-key.pem \\
#   --peer-cert-file=/etc/etcd/kubernetes.pem \\
#   --peer-key-file=/etc/etcd/kubernetes-key.pem \\
#   --trusted-ca-file=/etc/etcd/ca.pem \\
#   --peer-trusted-ca-file=/etc/etcd/ca.pem \\
#   --peer-client-cert-auth \\
#   --client-cert-auth \\
#   --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
#   --listen-peer-urls https://${INTERNAL_IP}:2380 \\
#   --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
#   --advertise-client-urls https://${INTERNAL_IP}:2379 \\
#   --initial-cluster-token etcd-cluster-0 \\
#   --initial-cluster controller-1=https://192.168.5.11:2380,controller-2=https://192.168.5.12:2380,controller-3=https://192.168.5.13:2380 \\
#   --initial-cluster-state new \\
#   --data-dir=/var/lib/etcd
# Restart=on-failure
# RestartSec=5

# [Install]
# WantedBy=multi-user.target
# EOF

#     sudo systemctl daemon-reload
#     sudo systemctl enable etcd
#     sudo systemctl start etcd
# }

# sudo ETCDCTL_API=3 etcdctl member list \
#   --endpoints=https://127.0.0.1:2379 \
#   --cacert=/etc/etcd/ca.pem \
#   --cert=/etc/etcd/kubernetes.pem \
#   --key=/etc/etcd/kubernetes-key.pem

# Download the official etcd release binaries from the etcd GitHub project:
# NOTE: TODO: Run in Controller Nodes
wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v3.4.10/etcd-v3.4.10-linux-amd64.tar.gz"

{
  tar -xvf etcd-v3.4.10-linux-amd64.tar.gz
  sudo mv etcd-v3.4.10-linux-amd64/etcd* /usr/local/bin/
}

  # Configure the etcd Server
{
  sudo mkdir -p /etc/etcd /var/lib/etcd
  sudo chmod 700 /var/lib/etcd
  sudo cp ca.crt etcd-server.key etcd-server.crt /etc/etcd/
}

# Retrieve the internal IP address of the master(etcd) nodes:

INTERNAL_IP=$(ip addr show eth1 | grep "inet " | awk '{print $2}' | cut -d / -f 1) && echo $INTERNAL_IP

# Set the etcd name to match the hostname of the current compute instance:
ETCD_NAME=$(hostname -s) && echo $ETCD_NAME

# Create the etcd.service systemd unit file:
{
  cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos
[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-server.crt \\
  --peer-key-file=/etc/etcd/etcd-server.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-1=https://192.168.5.11:2380,controller-2=https://192.168.5.12:2380,controller-3=https://192.168.5.13:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
}

# Start the etcd Server
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}

# List the etcd cluster members:

sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/etcd-server.crt \
  --key=/etc/etcd/etcd-server.key

# journalctl -t kube-controller-manager --since today

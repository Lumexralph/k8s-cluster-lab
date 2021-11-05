#!/usr/bin/env bash

# Update /etc/hosts about other hosts
sudo cat <<EOF | sudo tee -a /etc/hosts
192.168.5.11  controller-1
192.168.5.12  controller-2
192.168.5.13  controller-3

192.168.5.21  worker-1
192.168.5.22  worker-2
192.168.5.23  worker-3
EOF

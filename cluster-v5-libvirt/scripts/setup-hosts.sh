#!/usr/bin/env bash

# Update /etc/hosts about other hosts
sudo cat <<EOF | sudo tee -a /etc/hosts
192.168.5.11  controller-1
192.168.5.12  controller-2

192.168.5.21  worker-1
192.168.5.22  worker-2
EOF

# # check that port 6443 is open 
# sudo nc 127.0.0.1 6443

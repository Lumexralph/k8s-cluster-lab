#!/bin/bash

# To avoid having the file not present or found, enabling the bridge-netfilter
# Ref: http://zeeshanali.com/sysadmin/fixed-sysctl-cannot-stat-procsysnetbridgebridge-nf-call-iptables/
# https://ebtables.netfilter.org/documentation/bridge-nf.html
sudo modprobe br_netfilter

# set it to enabled for IPv4 addresses
sudo sysctl net.bridge.bridge-nf-call-iptables=1

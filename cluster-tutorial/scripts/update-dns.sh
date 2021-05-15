#!/usr/bin/env bash

# Tov avoid Temporary failure in name resolution
# Ref: https://stackoverflow.com/questions/53687051/ping-google-com-temporary-failure-in-name-resolution

# first disable systemd-resolved service.
# sudo systemctl disable systemd-resolved.service

# # Stop the service
# sudo systemctl stop systemd-resolved.service

# # Remove the link to /run/systemd/resolve/stub-resolv.conf in /etc/resolv.conf
# sudo rm /etc/resolv.conf

# # Add a manually created resolv.conf in /etc/
# sudo cat <<EOF | sudo tee /etc/resolv.conf
# nameserver 8.8.8.8
# EOF


# # allow the Node/VM to connect to the network
# sudo sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf

# sudo service systemd-resolved restart
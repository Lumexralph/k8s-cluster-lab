## Install container runtime (containerd) on the controlplane and worker nodes
# -------------------------- prerequisites -------------------------------

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# -------------------------- Install and configure containerd -------------------------------

# download the containerd binary archive:
wget -q --show-progress --https-only --timestamping \
  https://github.com/containerd/containerd/releases/download/v1.6.2/containerd-1.6.2-linux-amd64.tar.gz

# verify its sha256sum, and extract it under /usr/local:
sudo tar Cxzvf /usr/local containerd-1.6.2-linux-amd64.tar.gz

sudo mkdir -p /usr/local/lib/systemd/system

# Create the containerd.service systemd unit file:
cat <<EOF | sudo tee /usr/local/lib/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
#uncomment to enable the experimental sbservice (sandboxed) version of containerd/cri integration
#Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

# run containerd: 
{
  sudo systemctl daemon-reload
  sudo systemctl enable --now containerd
}

# Installing runc
##  Download runc binary archive
wget -q --show-progress --https-only --timestamping \
  https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.amd64

#  install it as /usr/local/sbin/runc, The binary is built statically and should work on any Linux distribution.:
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

# Installing CNI plugins ---------------------------
## Download CNI plugins archive:
wget -q --show-progress --https-only --timestamping \
  https://github.com/containernetworking/plugins/releases/download/v1.1.0/cni-plugins-linux-amd64-v1.1.0.tgz

# extract it under /opt/cni/bin:
{
  sudo mkdir -p /opt/cni/bin
  sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.0.tgz
}

# update the containerd config to use systemd cgroup for the runtime,
# same as the kubelet which uses systemd by default from v.1.22
sudo mkdir -p /etc/containerd/

sudo containerd config default | sudo tee /etc/containerd/config.toml

cat << EOF | sudo tee /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true
EOF

# restart containerd to apply the change
sudo systemctl restart containerd

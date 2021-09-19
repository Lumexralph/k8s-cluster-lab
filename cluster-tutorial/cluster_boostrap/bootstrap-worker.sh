#!/usr/bin/env bash

# {
#     sudo apt-get update
#     sudo apt-get -y install socat conntrack ipset

#     sudo swapoff -a

#     wget -q --show-progress --https-only --timestamping \
#     https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.18.0/crictl-v1.18.0-linux-amd64.tar.gz \
#     https://github.com/opencontainers/runc/releases/download/v1.0.0-rc91/runc.amd64 \
#     https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz \
#     https://github.com/containerd/containerd/releases/download/v1.3.6/containerd-1.3.6-linux-amd64.tar.gz \
#     https://storage.googleapis.com/kubernetes-release/release/v1.19.10/bin/linux/amd64/kubectl \
#     https://storage.googleapis.com/kubernetes-release/release/v1.19.10/bin/linux/amd64/kube-proxy \
#     https://storage.googleapis.com/kubernetes-release/release/v1.19.10/bin/linux/amd64/kubelet

#     sudo mkdir -p \
#     /etc/cni/net.d \
#     /opt/cni/bin \
#     /var/lib/kubelet \
#     /var/lib/kube-proxy \
#     /var/lib/kubernetes \
#     /var/run/kubernetes


#     mkdir containerd
#     tar -xvf crictl-v1.18.0-linux-amd64.tar.gz
#     tar -xvf containerd-1.3.6-linux-amd64.tar.gz -C containerd
#     sudo tar -xvf cni-plugins-linux-amd64-v0.8.6.tgz -C /opt/cni/bin/
#     sudo mv runc.amd64 runc
#     chmod +x crictl kubectl kube-proxy kubelet runc 
#     sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
#     sudo mv containerd/bin/* /bin/
# }

# {
#     POD_CIDR=192.168.5.0/24
#     cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
# {
#     "cniVersion": "0.3.1",
#     "name": "bridge",
#     "type": "bridge",
#     "bridge": "cnio0",
#     "isGateway": true,
#     "ipMasq": true,
#     "ipam": {
#         "type": "host-local",
#         "ranges": [
#           [{"subnet": "${POD_CIDR}"}]
#         ],
#         "routes": [{"dst": "0.0.0.0/0"}]
#     }
# }
# EOF

# cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
# {
#     "cniVersion": "0.3.1",
#     "name": "lo",
#     "type": "loopback"
# }
# EOF

# # containerd 
# sudo mkdir -p /etc/containerd/
# cat << EOF | sudo tee /etc/containerd/config.toml
# [plugins]
#   [plugins.cri.containerd]
#     snapshotter = "overlayfs"
#     [plugins.cri.containerd.default_runtime]
#       runtime_type = "io.containerd.runtime.v1.linux"
#       runtime_engine = "/usr/local/bin/runc"
#       runtime_root = ""
# EOF

# cat <<EOF | sudo tee /etc/systemd/system/containerd.service
# [Unit]
# Description=containerd container runtime
# Documentation=https://containerd.io
# After=network.target

# [Service]
# ExecStartPre=/sbin/modprobe overlay
# ExecStart=/bin/containerd
# Restart=always
# RestartSec=5
# Delegate=yes
# KillMode=process
# OOMScoreAdjust=-999
# LimitNOFILE=1048576
# LimitNPROC=infinity
# LimitCORE=infinity

# [Install]
# WantedBy=multi-user.target
# EOF

#     sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
#     sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
#     sudo mv ca.pem /var/lib/kubernetes/

# cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
# kind: KubeletConfiguration
# apiVersion: kubelet.config.k8s.io/v1beta1
# authentication:
#   anonymous:
#     enabled: false
#   webhook:
#     enabled: true
#   x509:
#     clientCAFile: "/var/lib/kubernetes/ca.pem"
# authorization:
#   mode: Webhook
# clusterDomain: "cluster.local"
# clusterDNS:
#   - "10.32.0.10"
# podCIDR: "${POD_CIDR}"
# resolvConf: "/run/systemd/resolve/resolv.conf"
# runtimeRequestTimeout: "15m"
# tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
# tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
# EOF


# cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
# [Unit]
# Description=Kubernetes Kubelet
# Documentation=https://github.com/kubernetes/kubernetes
# After=containerd.service
# Requires=containerd.service

# [Service]
# ExecStart=/usr/local/bin/kubelet \\
#   --config=/var/lib/kubelet/kubelet-config.yaml \\
#   --container-runtime=remote \\
#   --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
#   --image-pull-progress-deadline=2m \\
#   --kubeconfig=/var/lib/kubelet/kubeconfig \\
#   --network-plugin=cni \\
#   --register-node=true \\
#   --v=2
# Restart=on-failure
# RestartSec=5

# [Install]
# WantedBy=multi-user.target
# EOF

# sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
# cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
# kind: KubeProxyConfiguration
# apiVersion: kubeproxy.config.k8s.io/v1alpha1
# clientConnection:
#   kubeconfig: "/var/lib/kube-proxy/kubeconfig"
# mode: "iptables"
# clusterCIDR: "192.168.5.0/24"
# EOF

# cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
# [Unit]
# Description=Kubernetes Kube Proxy
# Documentation=https://github.com/kubernetes/kubernetes

# [Service]
# ExecStart=/usr/local/bin/kube-proxy \\
#   --config=/var/lib/kube-proxy/kube-proxy-config.yaml
# Restart=on-failure
# RestartSec=5

# [Install]
# WantedBy=multi-user.target
# EOF

#   sudo systemctl daemon-reload
#   sudo systemctl enable containerd kubelet kube-proxy
#   sudo systemctl start containerd kubelet kube-proxy
# }

sudo mkdir -p \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes

{
  chmod +x kubectl kube-proxy kubelet
  sudo mv kubectl kube-proxy kubelet /usr/local/bin/
}

# Configure the Kubelet
{
  sudo mv ${HOSTNAME}.key ${HOSTNAME}.crt /var/lib/kubelet/
  sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
  sudo mv ca.crt /var/lib/kubernetes/
}

cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.crt"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.96.0.10"
resolvConf: "/run/systemd/resolve/resolv.conf"
cgroupDriver: systemd
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.crt"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}.key"
EOF

# You might need to run this command if Kubelet is not up
sudo swapoff -a

# Create the kubelet.service systemd unit file:

sudo cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --authorization-mode=Webhook \\
  --client-ca-file=/var/lib/kubernetes/ca.crt \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Configure the Kubernetes Proxy
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

# Create the kube-proxy-config.yaml configuration file:

sudo cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "192.168.5.0/24"
EOF

# Create the kube-proxy.service systemd unit file:

sudo cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

{
  sudo swapoff -a
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}

{
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl restart  containerd kubelet kube-proxy
}

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=10.96.0.0/24"

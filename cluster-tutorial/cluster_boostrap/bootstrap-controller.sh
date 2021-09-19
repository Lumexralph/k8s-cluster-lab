#!/usr/bin/env bash

# {
#     sudo mkdir -p /etc/kubernetes/config

#     wget -q --show-progress --https-only --timestamping \
#     "https://storage.googleapis.com/kubernetes-release/release/v1.19.10/bin/linux/amd64/kube-apiserver" \
#     "https://storage.googleapis.com/kubernetes-release/release/v1.19.10/bin/linux/amd64/kube-controller-manager" \
#     "https://storage.googleapis.com/kubernetes-release/release/v1.19.10/bin/linux/amd64/kube-scheduler" \
#     "https://storage.googleapis.com/kubernetes-release/release/v1.19.10/bin/linux/amd64/kubectl"

#     chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
#     sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/

#     sudo mkdir -p /var/lib/kubernetes/

#     sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
#         service-account-key.pem service-account.pem \
#         encryption-config.yaml /var/lib/kubernetes/

#     INTERNAL_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)

#     cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
# [Unit]
# Description=Kubernetes API Server
# Documentation=https://github.com/kubernetes/kubernetes

# [Service]
# ExecStart=/usr/local/bin/kube-apiserver \\
#   --advertise-address=${INTERNAL_IP} \\
#   --allow-privileged=true \\
#   --apiserver-count=3 \\
#   --audit-log-maxage=30 \\
#   --audit-log-maxbackup=3 \\
#   --audit-log-maxsize=100 \\
#   --audit-log-path=/var/log/audit.log \\
#   --authorization-mode=Node,RBAC \\
#   --bind-address=0.0.0.0 \\
#   --client-ca-file=/var/lib/kubernetes/ca.pem \\
#   --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
#   --etcd-cafile=/var/lib/kubernetes/ca.pem \\
#   --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
#   --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
#   --etcd-servers=https://192.168.5.11:2379,https://192.168.5.12:2379,https://192.168.5.13:2379 \\
#   --event-ttl=1h \\
#   --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
#   --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
#   --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
#   --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
#   --kubelet-https=true \\
#   --runtime-config='api/all=true' \\
#   --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
#   --service-cluster-ip-range=10.32.0.0/24 \\
#   --service-node-port-range=30000-32767 \\
#   --service-account-signing-key-file=/var/lib/kubernetes/service-account-key.pem \\
#   --service-account-issuer=api \\
#   --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
#   --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
#   --v=2
# Restart=on-failure
# RestartSec=5

# [Install]
# WantedBy=multi-user.target
# EOF


#     sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/

#     cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
# [Unit]
# Description=Kubernetes Controller Manager
# Documentation=https://github.com/kubernetes/kubernetes

# [Service]
# ExecStart=/usr/local/bin/kube-controller-manager \\
#   --bind-address=0.0.0.0 \\
#   --cluster-cidr=192.168.5.0/24 \\
#   --cluster-name=kubernetes \\
#   --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
#   --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
#   --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
#   --leader-elect=true \\
#   --root-ca-file=/var/lib/kubernetes/ca.pem \\
#   --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
#   --service-cluster-ip-range=10.32.0.0/24 \\
#   --use-service-account-credentials=true \\
#   --v=2
# Restart=on-failure
# RestartSec=5

# [Install]
# WantedBy=multi-user.target
# EOF

#     sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/

#     cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
# apiVersion: kubescheduler.config.k8s.io/v1beta1
# kind: KubeSchedulerConfiguration
# clientConnection:
#   kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
# leaderElection:
#   leaderElect: true
# EOF

# cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
# [Unit]
# Description=Kubernetes Scheduler
# Documentation=https://github.com/kubernetes/kubernetes

# [Service]
# ExecStart=/usr/local/bin/kube-scheduler \\
#   --config=/etc/kubernetes/config/kube-scheduler.yaml \\
#   --v=2
# Restart=on-failure
# RestartSec=5

# [Install]
# WantedBy=multi-user.target
# EOF

#     sudo systemctl daemon-reload
#     sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
#     sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
# }

# {


#     cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRole
# metadata:
#   annotations:
#     rbac.authorization.kubernetes.io/autoupdate: "true"
#   labels:
#     kubernetes.io/bootstrapping: rbac-defaults
#   name: system:kube-apiserver-to-kubelet
# rules:
#   - apiGroups:
#       - ""
#     resources:
#       - nodes/proxy
#       - nodes/stats
#       - nodes/log
#       - nodes/spec
#       - nodes/metrics
#     verbs:
#       - "*"
# EOF

# cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
#   name: system:kube-apiserver
#   namespace: ""
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: system:kube-apiserver-to-kubelet
# subjects:
#   - apiGroup: rbac.authorization.k8s.io
#     kind: User
#     name: kubernetes
# EOF
# }

# sudo vim /home/vagrant/.ssh/known_hosts

# Create the Kubernetes configuration directory:
sudo mkdir -p /etc/kubernetes/config

# Download the official Kubernetes release binaries:

wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl"


# Install the Kubernetes binaries:

{
  chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
  sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
}

# Configure the Kubernetes API Server
{
  sudo mkdir -p /var/lib/kubernetes/

  sudo cp ca.crt ca.key kube-apiserver.crt kube-apiserver.key \
    service-account.key service-account.crt \
    etcd-server.key etcd-server.crt \
    encryption-config.yaml /var/lib/kubernetes/
}

# Create the kube-apiserver.service systemd unit file:

cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --runtime-config="api/all=true" \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.crt \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --enable-bootstrap-token-auth=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.crt \\
  --etcd-certfile=/var/lib/kubernetes/etcd-server.crt \\
  --etcd-keyfile=/var/lib/kubernetes/etcd-server.key \\
  --etcd-servers=https://192.168.5.11:2379,https://192.168.5.12:2379,https://192.168.5.13:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.crt \\
  --kubelet-client-certificate=/var/lib/kubernetes/kube-apiserver.crt \\
  --kubelet-client-key=/var/lib/kubernetes/kube-apiserver.key \\
  --kubelet-https=true \\
  --service-account-key-file=/var/lib/kubernetes/service-account.crt \\
  --service-account-signing-key-file=/var/lib/kubernetes/service-account.key \\
  --service-account-issuer=api \\
  --service-cluster-ip-range=10.96.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kube-apiserver.crt \\
  --tls-private-key-file=/var/lib/kubernetes/kube-apiserver.key \\
  --v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF



# Copy the kube-controller-manager kubeconfig into place:

sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/

# Create the kube-controller-manager.service systemd unit file:

cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=192.168.5.0/24 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.crt \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca.key \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.crt \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account.key \\
  --service-cluster-ip-range=10.96.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

# Move the kube-scheduler kubeconfig into place:

sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/

# Create the kube-scheduler.yaml configuration file:

cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1beta1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

# Create the kube-scheduler.service systemd unit file:
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --address=127.0.0.1 \\
  --v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

# Start the Controller Services

{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  sudo systemctl restart kube-apiserver kube-controller-manager kube-scheduler
}

cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF

# Bind the system:kube-apiserver-to-kubelet ClusterRole to the kubernetes user:

cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF

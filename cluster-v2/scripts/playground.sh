# Generate RSA Key Pair
ssh-keygen

# output the public key
cat ~/.ssh/id_rsa.pub

# Move public key to all other VMs
sudo cat >> ~/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCYIs/FxMFdludVhA0NiePYtHu6OUME4I5m4fn1ZoVAdd8RlAYa1DljAGsSJXDcacFVOxKN2QPH8JcRYaznexVy/ePNP/4YXEvYNATsfPj2cVIa8GyOToT0GB/tAL21aGLCeXLchYah6xiePHEZGm+VrY6dfbURn7pJBSN7URQwJdWcBltwbl9iFx/4eA6nGX074HSHmGY8OQZU+F9RGXIhRPyrNVhIz/8Qe8m47QHF6Z9W86O560Jrl62kRyUGUNokamGl1/TR5QYVsZ9BqFgX6Qq55VMh4UqK9GZzN9Z3l8SgfZaPcTzQ6b/1elE7DdyvRKbMfCD+2kGKHv/wsllltwwK7a3htSWHG+aVTwbnblgVWGVVxHNH0j0RNQsH3duPlUD8EPz2d9hB+NZMhdkoSp9TGbn+GYuiGviHD4HDBxyryLbINY2LSFsw2wP5HT04zMDkoxFiEHFV9edZE/q7CWe5ganAU4pgHJzzkoG7JaYWCFXqZ2KhEN0OhLbkxTs= vagrant@admin
EOF

# install kubectl
{
    sudo wget https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl
    sudo chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
}

# Certicate Authority
{
    # Create private key for CA
openssl genrsa -out ca.key 2048

# Comment line starting with RANDFILE in /etc/ssl/openssl.cnf definition to avoid permission issues
sudo sed -i '0,/RANDFILE/{s/RANDFILE/\#&/}' /etc/ssl/openssl.cnf

# Create CSR using the private key
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr

# Self sign the csr using its own private key
openssl x509 -req -in ca.csr -signkey ca.key -CAcreateserial  -out ca.crt -days 1000
}

# Generate Admin certificate
# Generate the admin client certificate and private key:

{
    # Generate private key for admin user
    openssl genrsa -out admin.key 2048

    # Generate CSR for admin user. Note the OU.
    openssl req -new -key admin.key -subj "/CN=admin/O=system:masters" -out admin.csr

    # Sign certificate for admin user using CA servers private key
    openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out admin.crt -days 1000

}

# Controller Manager Client Certificate
{
    openssl genrsa -out kube-controller-manager.key 2048
    openssl req -new -key kube-controller-manager.key -subj "/CN=system:kube-controller-manager" -out kube-controller-manager.csr
    openssl x509 -req -in kube-controller-manager.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-controller-manager.crt -days 1000
}

# Kube Proxy Client Certificate
{
    openssl genrsa -out kube-proxy.key 2048
    openssl req -new -key kube-proxy.key -subj "/CN=system:kube-proxy" -out kube-proxy.csr
    openssl x509 -req -in kube-proxy.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out kube-proxy.crt -days 1000
}

# Kube scheduler client certificates
{
    openssl genrsa -out kube-scheduler.key 2048
    openssl req -new -key kube-scheduler.key -subj "/CN=system:kube-scheduler" -out kube-scheduler.csr
    openssl x509 -req -in kube-scheduler.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out kube-scheduler.crt -days 1000
}


# The Kubernetes API Server Certificate

# Create openssl conf file
sudo cat > openssl.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.svc.cluster.local
DNS.6 = kubernetes.default.svc.cluster.local
IP.1 = 10.96.0.1
IP.2 = 192.168.5.11
IP.3 = 192.168.5.12
IP.4 = 192.168.5.13
IP.5 = 192.168.5.30
IP.6 = 192.168.5.40
IP.7 = 127.0.0.1
EOF

# Generates the certificates for the Kube API server using the conf file
{
    openssl genrsa -out kube-apiserver.key 2048
    openssl req -new -key kube-apiserver.key -subj "/CN=kube-apiserver" -out kube-apiserver.csr -config openssl.cnf
    openssl x509 -req -in kube-apiserver.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out kube-apiserver.crt -extensions v3_req -extfile openssl.cnf -days 1000
}

# The ETCD Server Certificate
sudo cat > openssl-etcd.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = 192.168.5.11
IP.2 = 192.168.5.12
IP.3 = 192.168.5.13
IP.4 = 127.0.0.1
EOF


# Generate certificates for ETCD client
{
    openssl genrsa -out etcd-server.key 2048
    openssl req -new -key etcd-server.key -subj "/CN=etcd-server" -out etcd-server.csr -config openssl-etcd.cnf
    openssl x509 -req -in etcd-server.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out etcd-server.crt -extensions v3_req -extfile openssl-etcd.cnf -days 1000
}

# The Service Account Key Pair
{
    openssl genrsa -out service-account.key 2048
    openssl req -new -key service-account.key -subj "/CN=service-accounts" -out service-account.csr
    openssl x509 -req -in service-account.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out service-account.crt -days 1000
}

# distribute the certificates
{
    for instance in controller-1 controller-2 controller-3; do
       scp ca.crt ca.key kube-apiserver.key kube-apiserver.crt \
        service-account.key service-account.crt \
        etcd-server.key etcd-server.crt \
        ${instance}:~/
    done
}

# Generate Kubernetes Configuration
LOADBALANCER_ADDRESS=192.168.5.30
KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local,kubernetes.default.svc.cluster.local

# Generate a kubeconfig file for the kube-proxy service:
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${LOADBALANCER_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.crt \
    --client-key=kube-proxy.key \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}

# Generate a kubeconfig file for the kube-controller-manager service:

{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.crt \
    --client-key=kube-controller-manager.key \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}

# Genetate kubeconfig file for Kube Scheduler
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.crt \
    --client-key=kube-scheduler.key \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}

# Generate kubeconfig for admin client
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${LOADBALANCER_ADDRESS}:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
}

# Copy the appropriate kube-proxy kubeconfig files to each worker instance:
for instance in worker-1 worker-2 worker-3; do
  scp kube-proxy.kubeconfig ${instance}:~/
done

# Copy the appropriate admin.kubeconfig, kube-controller-manager and kube-scheduler kubeconfig files to each controller instance:
{
    for instance in controller-1 controller-2 controller-3; do
       scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
    done
}

# Generate an encryption key:

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# Create the encryption-config.yaml encryption config file:

sudo cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

# Copy the encryption-config.yaml encryption config file to each controller instance:
{
    for instance in controller-1 controller-2 controller-3; do
       scp encryption-config.yaml ${instance}:~/
    done
}

# Download the official etcd release binaries from the etcd GitHub project:

wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v3.4.10/etcd-v3.4.10-linux-amd64.tar.gz"

# Extract and install the etcd server and the etcdctl command line utility:

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

INTERNAL_IP=$(ip addr show eth1 | grep "inet " | awk '{print $2}' | cut -d / -f 1)

# Set the etcd name to match the hostname of the current compute instance:
ETCD_NAME=$(hostname -s)

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

# Create the Kubernetes configuration directory:
sudo mkdir -p /etc/kubernetes/config

# Download the official Kubernetes release binaries:

wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl"


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
  --runtime-config='api/all=true' \\
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

sudo cp kube-controller-manager.kubeconfig /var/lib/kubernetes/

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

# Copy the kube-scheduler kubeconfig into place:

sudo cp kube-scheduler.kubeconfig /var/lib/kubernetes/

# Create the kube-scheduler.yaml configuration file:

cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1
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

# verify control plane
kubectl get componentstatuses --kubeconfig admin.kubeconfig


# download and install the loabbalancer
sudo apt-get update && sudo apt-get install -y haproxy

# create configuration file
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
frontend kubernetes
    bind 192.168.5.30:6443
    option tcplog
    mode tcp
    default_backend kubernetes-controller-nodes

backend kubernetes-controller-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server controller-1 192.168.5.11:6443 check fall 3 rise 2
    server controller-2 192.168.5.12:6443 check fall 3 rise 2
    server controller-3 192.168.5.13:6443 check fall 3 rise 2
EOF

# restart the loadbalancer service
sudo service haproxy restart

# Verification
# Make a HTTP request for the Kubernetes version info:

curl  https://192.168.5.30:6443/version -k

# verify control plane
kubectl get componentstatuses --kubeconfig admin.kubeconfig

# Generate a certificate and private key for one worker node:

cat > openssl-worker-1.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = worker-1
IP.1 = 192.168.5.21
EOF

{
  openssl genrsa -out worker-1.key 2048
openssl req -new -key worker-1.key -subj "/CN=system:node:worker-1/O=system:nodes" -out worker-1.csr -config openssl-worker-1.cnf
openssl x509 -req -in worker-1.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out worker-1.crt -extensions v3_req -extfile openssl-worker-1.cnf -days 1000
}

# set load balancer
LOADBALANCER_ADDRESS=192.168.5.30

# Generate a kubeconfig file for the first worker node.

{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${LOADBALANCER_ADDRESS}:6443 \
    --kubeconfig=worker-1.kubeconfig

  kubectl config set-credentials system:node:worker-1 \
    --client-certificate=worker-1.crt \
    --client-key=worker-1.key \
    --embed-certs=true \
    --kubeconfig=worker-1.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:worker-1 \
    --kubeconfig=worker-1.kubeconfig

  kubectl config use-context default --kubeconfig=worker-1.kubeconfig
}

# Download and Install Worker Binaries

wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubelet

# Create the installation directories:
sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes


# Install the worker binaries:

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

# Create the kubelet-config.yaml configuration file:
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
# resolvConf: "/run/systemd/resolve/resolv.conf"
# runtimeRequestTimeout: "15m"
# tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
# tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
# EOF

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
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.crt"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}.key"
EOF

# You might need to run this command if Kubelet is not up
sudo swapoff -a

sudo systemctl restart kubelet.service

sudo systemctl status kubelet

# Create the kubelet.service systemd unit file:

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --tls-cert-file=/var/lib/kubelet/${HOSTNAME}.crt \\
  --tls-private-key-file=/var/lib/kubelet/${HOSTNAME}.key \\
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

cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "192.168.5.0/24"
EOF

# Create the kube-proxy.service systemd unit file:

cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
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

# Start the Worker Services
{
  sudo systemctl daemon-reload
  sudo systemctl enable kubelet kube-proxy
  sudo systemctl start kubelet kube-proxy
}

# copy the CA certs to worker 2 and 3
for instance in worker-2 worker-3; do
  scp ca.crt ${instance}:~/
done

# Move the ca certificate
sudo mv ca.crt /var/lib/kubernetes/

# Create bootstrap token on admin
{
cat > bootstrap-token-07401b.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  # Name MUST be of form "bootstrap-token-<token id>"
  name: bootstrap-token-07401b
  namespace: kube-system

# Type MUST be 'bootstrap.kubernetes.io/token'
type: bootstrap.kubernetes.io/token
stringData:
  # Human readable description. Optional.
  description: "The default bootstrap token generated by 'kubeadm init'."

  # Token ID and secret. Required.
  token-id: 07401b
  token-secret: f395accd246ae52d

  # Expiration. Optional.
  expiration: 2024-03-10T03:22:11Z

  # Allowed usages.
  usage-bootstrap-authentication: "true"
  usage-bootstrap-signing: "true"

  # Extra groups to authenticate the token as. Must start with "system:bootstrappers:"
  auth-extra-groups: system:bootstrappers:worker
EOF


kubectl create -f bootstrap-token-07401b.yaml --kubeconfig admin.kubeconfig
}

# Create 
{
  cat > csrs-for-bootstrapping.yaml <<EOF
# enable bootstrapping nodes to create CSR
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: create-csrs-for-bootstrapping
subjects:
- kind: Group
  name: system:bootstrappers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:node-bootstrapper
  apiGroup: rbac.authorization.k8s.io
EOF


kubectl create -f csrs-for-bootstrapping.yaml --kubeconfig admin.kubeconfig
}

# Authorize workers(kubelets) to approve CSR
{
  cat > auto-approve-csrs-for-group.yaml <<EOF
# Approve all CSRs for the group "system:bootstrappers"
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: auto-approve-csrs-for-group
subjects:
- kind: Group
  name: system:bootstrappers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
  apiGroup: rbac.authorization.k8s.io
EOF


kubectl create -f auto-approve-csrs-for-group.yaml --kubeconfig admin.kubeconfig
}

# Authorize workers(kubelets) to Auto Renew Certificates on expiration
{
  cat > auto-approve-renewals-for-nodes.yaml <<EOF
# Approve renewal CSRs for the group "system:nodes"
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: auto-approve-renewals-for-nodes
subjects:
- kind: Group
  name: system:nodes
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
  apiGroup: rbac.authorization.k8s.io
EOF


kubectl create -f auto-approve-renewals-for-nodes.yaml --kubeconfig admin.kubeconfig
}

# create a kubeconfig file on worker
cat <<EOF | sudo tee /var/lib/kubelet/bootstrap-kubeconfig
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/ca.crt
    server: https://192.168.5.30:6443
  name: bootstrap
contexts:
- context:
    cluster: bootstrap
    user: kubelet-bootstrap
  name: bootstrap
current-context: bootstrap
kind: Config
preferences: {}
users:
- name: kubelet-bootstrap
  user:
    token: 07401b.f395accd246ae52d
EOF

# Create the kubelet-config.yaml configuration file:

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
runtimeRequestTimeout: "15m"
EOF

# Create the kubelet.service systemd unit file:

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --bootstrap-kubeconfig="/var/lib/kubelet/bootstrap-kubeconfig" \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --cert-dir=/var/lib/kubelet/pki/ \\
  --rotate-certificates=true \\
  --rotate-server-certificates=true \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# For Containerd worker 2 and 3
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --bootstrap-kubeconfig="/var/lib/kubelet/bootstrap-kubeconfig" \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --cert-dir=/var/lib/kubelet/pki/ \\
  --rotate-certificates=true \\
  --rotate-server-certificates=true \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# move kube proxy kubeconfig
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

# Create the kube-proxy-config.yaml configuration file:

cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "192.168.5.0/24"
EOF

# Create the kube-proxy.service systemd unit file:

cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
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


# With Containerd
{
  sudo swapoff -a
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}


# Start the Worker Services
{
  sudo swapoff -a
  sudo systemctl daemon-reload
  sudo systemctl enable kubelet kube-proxy
  sudo systemctl start kubelet kube-proxy
}

# approve CSR
kubectl get csr --kubeconfig admin.kubeconfig

# Approve

kubectl certificate approve <csr-> --kubeconfig admin.kubeconfig

# Generate a kubeconfig file suitable for authenticating as the admin user:
{
  KUBERNETES_LB_ADDRESS=192.168.5.30

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${KUBERNETES_LB_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}

# Download the CNI Plugins required for weave on each of the worker nodes - worker-1 and worker-2

wget https://github.com/containernetworking/plugins/releases/download/v0.7.5/cni-plugins-amd64-v0.7.5.tgz

# Extract it to /opt/cni/bin directory

sudo tar -xzvf cni-plugins-amd64-v0.7.5.tgz --directory /opt/cni/bin/

# Deploy weave network. Run only once on the admin node.

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

kubectl delete pod weave-net-ddb8v --grace-period=0 --force --namespace kube-system

# Reading the logs

kubectl logs -n kube-system weave-net-1jkl6 weave


##################### Worker Nodes with  Containerd ###########################################

# Install the OS dependencies:

{
  sudo apt-get update
  sudo apt-get -y install socat conntrack ipset
}

# Verify if swap is enabled:

sudo swapon --show

# disable swap:

sudo swapoff -a

# Download and Install Worker Binaries
wget -q --show-progress --https-only --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.18.0/crictl-v1.18.0-linux-amd64.tar.gz \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc91/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz \
  https://github.com/containerd/containerd/releases/download/v1.3.6/containerd-1.3.6-linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubelet

# Create the installation directories:

sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes

# Install the worker binaries:

{
  mkdir containerd
  tar -xvf crictl-v1.18.0-linux-amd64.tar.gz
  tar -xvf containerd-1.3.6-linux-amd64.tar.gz -C containerd
  sudo tar -xvf cni-plugins-linux-amd64-v0.8.6.tgz -C /opt/cni/bin/
  sudo mv runc.amd64 runc
  chmod +x crictl kubectl kube-proxy kubelet runc
  sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
  sudo mv containerd/bin/* /bin/
}

POD_CIDR=192.168.5.0/24

# Create the bridge network configuration file:
cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF

# Create the loopback network configuration file:

cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "name": "lo",
    "type": "loopback"
}
EOF

# Create the containerd configuration file:

{
  sudo mkdir -p /etc/containerd/

cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF
}

# Create the containerd.service systemd unit file:

cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

# configure kubelet
cat > openssl-worker-1.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = worker-1
IP.1 = 192.168.5.21
EOF

# generate certiificates

{
  openssl genrsa -out worker-1.key 2048
openssl req -new -key worker-1.key -subj "/CN=system:node:worker-1/O=system:nodes" -out worker-1.csr -config openssl-worker-1.cnf
openssl x509 -req -in worker-1.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out worker-1.crt -extensions v3_req -extfile openssl-worker-1.cnf -days 1000
}

# Generate a kubeconfig file for the first worker node.

{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${LOADBALANCER_ADDRESS}:6443 \
    --kubeconfig=worker-1.kubeconfig

  kubectl config set-credentials system:node:worker-1 \
    --client-certificate=worker-1.crt \
    --client-key=worker-1.key \
    --embed-certs=true \
    --kubeconfig=worker-1.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:worker-1 \
    --kubeconfig=worker-1.kubeconfig

  kubectl config use-context default --kubeconfig=worker-1.kubeconfig
}

# Copy certificates, private keys and kubeconfig files to the worker node:

scp ca.crt worker-1.crt worker-1.key worker-1.kubeconfig worker-1:~/

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
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.crt"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}.key"
EOF

# Create the kubelet.service systemd unit file:

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

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=4m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --tls-cert-file=/var/lib/kubelet/${HOSTNAME}.crt \\
  --tls-private-key-file=/var/lib/kubelet/${HOSTNAME}.key \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


# move kube proxy kubeconfig
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig


# Create the kube-proxy-config.yaml configuration file:

cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "192.168.5.0/24"
EOF

# Create the kube-proxy.service systemd unit file:

cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
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

# Start the Worker Services
{
  sudo swapoff -a
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}


# Configure for remote access
{
  KUBERNETES_LB_ADDRESS=192.168.5.30

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${KUBERNETES_LB_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}

# Kube API Server with Kubelet API



# Resolving when you restart your cluster

# 1. To allow domain resolution
{
  sudo service systemd-resolved restart 

# 2. switch off disk swap on the worker node to allow Kubelet to run
sudo swapoff -a

# 3. stop and start kubelet
sudo service kubelet stop && sudo service kubelet start

}
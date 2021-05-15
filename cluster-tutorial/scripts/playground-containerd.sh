# Generate RSA Key Pair
ssh-keygen

# TODO: Use Ansible / Terraform create the public.private ssh keys
# TODO: Copy them over as done manually below

# output the public key
cat ~/.ssh/id_rsa.pub

# Move public key to all other VMs
sudo cat >> ~/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxaUcIzYNhmo1eZrd2FHqaqoYh71WG1Y9LCZvl98qRcdgVXO3QQMIFdE0ztHzg3O0oq2apBHvnFiybWV2BFmxHC/sYF38N2DsDyXEPzp7VABw95c1pgd9TM91LtTbfWte/id53yj6M0SN1AUgh2tcIGpYNivhJ6T8fCfT6bMQznt2Ljw7q2QUTZ+YtAXWANT52WiB1ggMM50SSix6pwRv+NpaQjaJsnb8gsjVyrHqDCoNHrpuN5eWdSsO6C7vtNZiRCl9LFc3t3vn8NXmE1bVIBEZ0NnP3uRnjZ4DRxl+LPN8r7mTnobTQzVKfH8dqizfTWFl6j6+aTGHJ/Z6QbMkuawoWSMBj5MOBrs92H5JsnB1D0+LVSu8uI5iLHwRwjHfChpeE4r+NoAd5hbhfGV05CjPfE8cHaMhWb1xb6F06T3m93E1OSuKF9BH9G0+RXM1+NHXFzc/uWmWUkW9URWE0AntuAwyhWLAfWWLok+g7VU5GntyZxKGawl/sfHuJCCs= vagrant@admin
EOF

# install kubectl
{
    sudo wget https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl
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

{
    for instance in controller-1; do
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

{
  for instance in controller-1 controller-2 controller-3; do
    ssh ${instance} sudo mv encryption-config.yaml /var/lib/kubernetes/
  done
}


# Download the official etcd release binaries from the etcd GitHub project:
# NOTE: TODO: Run in Controller Nodes
wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v3.4.10/etcd-v3.4.10-linux-amd64.tar.gz"

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


# LOADBALANACER
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

# verify control plane
kubectl get componentstatuses --kubeconfig admin.kubeconfig

# Verification
# Make a HTTP request for the Kubernetes version info:

curl  https://192.168.5.30:6443/version -k
curl -k https://192.168.5.30:6443/livez?verbose

# --service-account-signing-key-file and --service-account-issuer=https://192.168.5.30 \\


###### DEBUGGING ######
kubectl cluster-info --kubeconfig admin.kubeconfig
Kubernetes control plane is running at https://192.168.5.30:6443

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

######## WORKER ################
# Create their certificates
# Worker 1
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

# Worker-2
cat > openssl-worker-2.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = worker-2
IP.1 = 192.168.5.22
EOF

{
  openssl genrsa -out worker-2.key 2048
openssl req -new -key worker-2.key -subj "/CN=system:node:worker-2/O=system:nodes" -out worker-2.csr -config openssl-worker-2.cnf
openssl x509 -req -in worker-2.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out worker-2.crt -extensions v3_req -extfile openssl-worker-2.cnf -days 1000
}

# Worker 3
cat > openssl-worker-3.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = worker-3
IP.1 = 192.168.5.23
EOF

{
  openssl genrsa -out worker-3.key 2048
openssl req -new -key worker-3.key -subj "/CN=system:node:worker-3/O=system:nodes" -out worker-3.csr -config openssl-worker-3.cnf
openssl x509 -req -in worker-3.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out worker-3.crt -extensions v3_req -extfile openssl-worker-3.cnf -days 1000
}

# Distibute the Keys and Certificates

{
    for instance in worker-1 worker-2 worker-3; do
    scp ca.crt ca.key ${instance}.key ${instance}.crt ${instance}:~/
    done

}

# Generate a kubeconfig file for each worker node:

{
    for instance in worker-1 worker-2 worker-3; do
        kubectl config set-cluster kubernetes-the-hard-way \
            --certificate-authority=ca.crt \
            --embed-certs=true \
            --server=https://${LOADBALANCER_ADDRESS}:6443 \
            --kubeconfig=${instance}.kubeconfig

        kubectl config set-credentials system:node:${instance} \
            --client-certificate=${instance}.crt \
            --client-key=${instance}.key \
            --embed-certs=true \
            --kubeconfig=${instance}.kubeconfig

        kubectl config set-context default \
            --cluster=kubernetes-the-hard-way \
            --user=system:node:${instance} \
            --kubeconfig=${instance}.kubeconfig

        kubectl config use-context default --kubeconfig=${instance}.kubeconfig
    done
}

# Distibute the Kube Config files
{
    for instance in worker-1 worker-2 worker-3; do
        scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
    done
}

# RBAC for Kubelet Authorization
# In this section you will configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node. Access to the Kubelet API is required for retrieving metrics, logs, and executing commands in pods.
# Create the system:kube-apiserver-to-kubelet ClusterRole with permissions to access the Kubelet API and perform most common tasks associated with managing pods:

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

# Bootstrapping the Kubernetes Worker Nodes
# In this lab you will bootstrap three Kubernetes worker nodes. The following components will be installed on each node: runc, container networking plugins, containerd, kubelet, and kube-proxy.

# NOTE: TODO: commands in this lab must be run on each worker instance: worker-0, worker-1, and worker-2. Login to each worker instance

# TODO: To ensure swap remains off after reboot consult your Linux distro documentation.
{
  sudo apt-get update
  sudo apt-get -y install socat conntrack ipset
  sudo swapoff -a
}

# Download and Install Worker Binaries
# wget -q --show-progress --https-only --timestamping \
#   https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.20.0/crictl-v1.20.0-linux-amd64.tar.gz \
#   https://github.com/opencontainers/runc/releases/download/v1.0.0-rc91/runc.amd64 \
#   https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz \
#   https://github.com/containerd/containerd/releases/download/v1.3.6/containerd-1.3.6-linux-amd64.tar.gz \
#   https://storage.googleapis.com/kubernetes-release/release/v1.20.6/bin/linux/amd64/kubectl \
#   https://storage.googleapis.com/kubernetes-release/release/v1.20.6/bin/linux/amd64/kube-proxy \
#   https://storage.googleapis.com/kubernetes-release/release/v1.20.6/bin/linux/amd64/kubelet

# PRE_SETUP FOR CONTAINERD
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# REF: https://github.com/containerd/containerd/blob/master/docs/cri/installation.md

# Install required library for seccomp.

{
    sudo apt-get update
    sudo apt-get install libseccomp2
}

# Download release tarball for the containerd version you want to install from the GCS bucket.
# Validate checksum of the release tarball:
{
VERSION="1.4.3"

wget -q --show-progress --https-only --timestamping \
https://github.com/containerd/containerd/releases/download/v${VERSION}/cri-containerd-cni-${VERSION}-linux-amd64.tar.gz \
https://github.com/containerd/containerd/releases/download/v${VERSION}/cri-containerd-cni-${VERSION}-linux-amd64.tar.gz.sha256sum \
https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl \
https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kube-proxy \
https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubelet

sha256sum --check cri-containerd-cni-${VERSION}-linux-amd64.tar.gz.sha256sum

}

# Install Containerd
# If you are using systemd, just simply unpack the tarball to the root directory:

{
  sudo tar --no-overwrite-dir -C / -xzf cri-containerd-cni-${VERSION}-linux-amd64.tar.gz
  sudo systemctl daemon-reload
  sudo systemctl start containerd
}

# Configure containerd:

{
  sudo mkdir -p /etc/containerd
  containerd config default | sudo tee /etc/containerd/config.toml
}

# Restart containerd:
sudo systemctl restart containerd

# Using the systemd cgroup driver
# To use the systemd cgroup driver in /etc/containerd/config.toml with runc, set

sudo vim /etc/containerd/config.toml

# Add SystemdCgroup=true under the appropriate section as shown below
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  ...
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true

#
sudo mkdir -p /etc/systemd/system/kubelet.service.d/
cd /etc/systemd/system/kubelet.service.d/

sudo vim 0-containerd.conf


# past the following there

# If you apply this change make sure to restart containerd again:

sudo systemctl restart containerd



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

# DEBUGGING
sudo /usr/local/bin/kubelet \
  --config=/var/lib/kubelet/kubelet-config.yaml \
  --container-runtime=remote  \
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \
  --image-pull-progress-deadline=4m  \
  --kubeconfig=/var/lib/kubelet/kubeconfig \
  --network-plugin=cni \
  --register-node=true  \
  --v=2


sudo /usr/local/bin/kube-proxy \
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml



# Configuring kubectl for Remote Access
# Run in the admin machine

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

# Deploy weave network. Run only once on the master node.

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# Weave uses POD CIDR of 10.32.0.0/12 by default.

# RBAC for Kubelet Authorization
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
- apiGroups: [""]
  resources:
  - nodes/proxy
  - nodes/stats
  - nodes/log
  - nodes/spec
  - nodes/metrics
  - pods
  verbs: ["*"]
EOF

# Bind the system:kube-apiserver-to-kubelet ClusterRole to the system:kube-apiserver user:

cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
- kind: User
  name: kubernetes
  apiGroup: rbac.authorization.k8s.io
EOF

# You need to add this ClusterRole
kubectl create clusterrolebinding apiserver-kubelet-admin --user=kube-apiserver --clusterrole=system:kubelet-api-admin

# Deploy the coredns cluster add-on:

kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.7.0.yaml

kubectl run busybox --image=busybox:1.28 --command -- sleep 3600

# List the pod created by the busybox deployment:

kubectl get pods -l run=busybox

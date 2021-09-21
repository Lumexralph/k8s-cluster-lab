# The Admin VM will be used to set up the cluster
# perform administrative tasks, such as creating certificates,
# kubeconfig files and distributing them to the different VMs.

# Generate RSA Key Pair
ssh-keygen

# View the generated public key ID
cat ~/.ssh/id_rsa.pub

# Move public key of admin to all other VMs,
# to have an authentication and identity for admin communication
# you'd have to login to the vms, you can use tmux
# then copy the public key to their environment.
sudo cat >> ~/.ssh/authorized_keys <<EOF
<<YOUR ADMIN RSA KEY>>
EOF

# install kubectl
{
    sudo wget https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl
    
    sudo chmod +x kubectl
    
    sudo mv kubectl /usr/local/bin/

    kubectl version --client
}

# Install CFSSL
# The cfssl and cfssljson command line utilities will be used to provision a PKI Infrastructure and generate TLS certificates.

# Download and install cfssl and cfssljson:
{
    wget -q --show-progress --https-only --timestamping \
        https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl \
        https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson

    # make it an executable file to be able to run as binary
    chmod +x cfssl cfssljson

    # move to the local bin directory
    sudo mv cfssl cfssljson /usr/local/bin/

    # Verify cfssl and cfssljson version 1.4.1 or higher is installed
    cfssl version

    cfssljson --version
}




# Certificate Authority
# Provision a PKI Infrastructure using CloudFlare's PKI toolkit, cfssl, 
# then use it to bootstrap a Certificate Authority, and generate TLS certificates for the following components: 
# etcd, kube-apiserver, kube-controller-manager, kube-scheduler, kubelet, and kube-proxy.
# Generate the CA configuration file, certificate, and private key:
{

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

}

# you get ca-key.pem  ca.pem

###### Client and Server Certificates
## generate client and server certificates for each Kubernetes component,
# and a client certificate for the Kubernetes admin user.

# Generate the admin client certificate and private key:
{

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin

}
# output: admin-key.pem admin.pem

# Kubelet Client Certificates
# In order to be authorized by the Node Authorizer, 
# Kubelets must use a credential that identifies them as being in the system:nodes group,
# with a username of system:node:<nodeName>

# Generate a certificate and private key for each Kubernetes worker node:

# worker-1
{

instance=worker-1

cat > ${instance}-csr.json <<EOF
    {
    "CN": "system:node:${instance}",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
        "C": "US",
        "L": "Portland",
        "O": "system:nodes",
        "OU": "Kubernetes The Hard Way",
        "ST": "Oregon"
        }
    ]
    }
EOF

# worker-1's IP from the VM
INTERNAL_IP=192.168.5.21

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}
}

# worker-2
{

instance=worker-2

cat > ${instance}-csr.json <<EOF
    {
    "CN": "system:node:${instance}",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
        "C": "US",
        "L": "Portland",
        "O": "system:nodes",
        "OU": "Kubernetes The Hard Way",
        "ST": "Oregon"
        }
    ]
    }
EOF

# worker-2's IP from the VM
INTERNAL_IP=192.168.5.22

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}
}

# worker-3
{

instance=worker-3

cat > ${instance}-csr.json <<EOF
    {
    "CN": "system:node:${instance}",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
        "C": "US",
        "L": "Portland",
        "O": "system:nodes",
        "OU": "Kubernetes The Hard Way",
        "ST": "Oregon"
        }
    ]
    }
EOF

# worker-3's IP from the VM
INTERNAL_IP=192.168.5.23

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}
}

### The Controller Manager Client Certificate
# Generate the kube-controller-manager client certificate and private key:
{

cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

}

### The Kube Proxy Client Certificate
# Generate the kube-proxy client certificate and private key:
{

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

}

#### The Scheduler Client Certificate
# Generate the kube-scheduler client certificate and private key:
{

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

}

# The Kubernetes API Server Certificate
{

# the loadbalancer, it has to be static
KUBERNETES_PUBLIC_ADDRESS=192.168.5.30

KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local,kubernetes.default.svc.cluster.local

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,192.168.5.11,192.168.5.12,192.168.5.13,${KUBERNETES_PUBLIC_ADDRESS},192.168.5.40,127.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

}

### The Service Account Key Pair
## The Kubernetes Controller Manager leverages a key pair to generate and sign service account tokens 

# Generate the service-account certificate and private key:
{

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

}

## Distribute the Client and Server Certificates
# Copy the appropriate certificates and private keys to each worker instances:
{
    for instance in worker-1 worker-2 worker-3; do
        scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
    done

}

# Copy the appropriate certificates and private keys to each controller instance:
{
    for instance in controller-1 controller-2 controller-3; do
        scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
            service-account-key.pem service-account.pem ${instance}:~/
    done
}

#### Generating Kubernetes Configuration Files for Authentication
## generate Kubernetes configuration files, also known as kubeconfigs,
# which enable Kubernetes clients to locate and authenticate to the Kubernetes API Servers.

# Client Authentication Configs
# generate kubeconfig files for the controller manager, kubelet, kube-proxy, and scheduler clients and the admin user.

# Each kubeconfig requires a Kubernetes API Server to connect to. 
# To support high availability the IP address assigned to the external load balancer fronting the Kubernetes API Servers will be used.

KUBERNETES_PUBLIC_ADDRESS=192.168.5.30

# The kubelet Kubernetes Configuration File
# When generating kubeconfig files for Kubelets the client certificate matching the Kubelet's node name must be used. 
# This will ensure Kubelets are properly authorized by the Kubernetes Node Authorizer.

# Generate a kubeconfig file for each worker node:
{
    for instance in worker-1 worker-2 worker-3; do
        kubectl config set-cluster kubernetes-the-hard-way \
            --certificate-authority=ca.pem \
            --embed-certs=true \
            --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
            --kubeconfig=${instance}.kubeconfig

        kubectl config set-credentials system:node:${instance} \
            --client-certificate=${instance}.pem \
            --client-key=${instance}-key.pem \
            --embed-certs=true \
            --kubeconfig=${instance}.kubeconfig

        kubectl config set-context default \
            --cluster=kubernetes-the-hard-way \
            --user=system:node:${instance} \
            --kubeconfig=${instance}.kubeconfig

        kubectl config use-context default --kubeconfig=${instance}.kubeconfig
    done

}

## The kube-proxy Kubernetes Configuration File
# Generate a kubeconfig file for the kube-proxy service:
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}

### The kube-controller-manager Kubernetes Configuration File
# Generate a kubeconfig file for the kube-controller-manager service:
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}

## The kube-scheduler Kubernetes Configuration File
# Generate a kubeconfig file for the kube-scheduler service:
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}

## The admin Kubernetes Configuration File:
# Generate a kubeconfig file for the admin user:
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
}

## Distribute the Kubernetes Configuration Files
# Copy the appropriate kubelet and kube-proxy kubeconfig files to each worker instance:
{
    for instance in worker-1 worker-2 worker-3; do
      scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
    done
}

# Copy the appropriate kube-controller-manager and kube-scheduler kubeconfig files to each controller instance:
{
    for instance in controller-1 controller-2 controller-3; do
        scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
    done
}


#### Generating the Data Encryption Config and Key
### Kubernetes stores a variety of data including cluster state, application configurations, and secrets. Kubernetes supports the ability to encrypt cluster data at rest.

## generate an encryption key and an encryption config suitable for encrypting Kubernetes Secrets.
# The Encryption Key
# Generate an encryption key:
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# The Encryption Config File
# Create the encryption-config.yaml encryption config file:
cat > encryption-config.yaml <<EOF
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

####### Bootstrapping the etcd Cluster
### Kubernetes components are stateless and store cluster state in etcd.
# bootstrap a three node etcd cluster and configure it for high availability and secure remote access.

# Download and Install the etcd Binaries:
wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v3.4.15/etcd-v3.4.15-linux-amd64.tar.gz"

# Extract and install the etcd server and the etcdctl command line utility:
{
  tar -xvf etcd-v3.4.15-linux-amd64.tar.gz
  sudo mv etcd-v3.4.15-linux-amd64/etcd* /usr/local/bin/
}

# Configure the etcd Server
{
  sudo mkdir -p /etc/etcd /var/lib/etcd
  sudo chmod 700 /var/lib/etcd
  sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
}

#### The instance internal IP address will be used to serve client requests and communicate with etcd cluster peers. Retrieve the internal IP address for the controller compute instance:
INTERNAL_IP=$(ip addr show eth1 | grep "inet " | awk '{print $2}' | cut -d / -f 1) && echo $INTERNAL_IP

# Each etcd member must have a unique name within an etcd cluster.
# Set the etcd name to match the hostname of the current controller instance:
ETCD_NAME=$(hostname -s) && echo $ETCD_NAME

# Create the etcd.service systemd unit file:
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
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

# Start the etcd Server
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}

# Verification
# List the etcd cluster members:
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem


#### Bootstrapping the Kubernetes Control Plane
## bootstrap the Kubernetes control plane across three controller instances and configure it for high availability. 
# create a load balancer that exposes the Kubernetes API Servers to remote clients. 
# The following components will be installed on each node: Kubernetes API Server, Scheduler, and Controller Manager.

# Create the Kubernetes configuration directory:
sudo mkdir -p /etc/kubernetes/config

# Download the official Kubernetes release binaries:
wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl"

# Install the Kubernetes binaries:
{
  chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
  sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
}

# Configure the Kubernetes API Server
{
  sudo mkdir -p /var/lib/kubernetes/

  sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    encryption-config.yaml /var/lib/kubernetes/
}

# The instance internal IP address will be used to advertise the API Server to members of the cluster. Retrieve the internal IP address for the current controller instance:
INTERNAL_IP=$(ip addr show eth1 | grep "inet " | awk '{print $2}' | cut -d / -f 1) && echo $INTERNAL_IP
KUBERNETES_PUBLIC_ADDRESS=192.168.5.30

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
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://192.168.5.11:2379,https://192.168.5.12:2379,https://192.168.5.13:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --runtime-config='api/all=true' \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-account-signing-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-account-issuer=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Configure the Kubernetes Controller Manager
# Move the kube-controller-manager kubeconfig into place:
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/

# Create the kube-controller-manager.service systemd unit file:
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Configure the Kubernetes Scheduler
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
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# setup the loadbalancer
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

# Start the Controller Services
{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
}

# Health Check
sudo apt-get update && sudo apt-get install -y nginx

cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

{
  sudo mv kubernetes.default.svc.cluster.local \
    /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

  sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/
}

sudo systemctl restart nginx
sudo systemctl enable nginx

kubectl cluster-info --kubeconfig admin.kubeconfig
curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz

curl  https://192.168.5.30:6443/version -k
curl -k https://192.168.5.30:6443/livez?verbose


#### RBAC for Kubelet Authorization
# configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node. 
# Access to the Kubelet API is required for retrieving metrics, logs, and executing commands in pods.

# Create the system:kube-apiserver-to-kubelet ClusterRole with permissions to access the Kubelet API and perform most common tasks associated with managing pods:

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

# The Kubernetes API Server authenticates to the Kubelet as the kubernetes user using the client certificate as defined by the --kubelet-client-certificate flag.
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

# FRONTEND LOAD BALANCER VERRIFICATION
curl --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version


######## Bootstrapping the Kubernetes Worker Nodes
### bootstrap three Kubernetes worker nodes. 
# The following components will be installed on each node: runc, container networking plugins, containerd, kubelet, and kube-proxy.

# Provisioning a Kubernetes Worker Node
# Install the OS dependencies:
{
  sudo apt-get update
  sudo apt-get -y install socat conntrack ipset
}
# socat binary enables support for the kubectl port-forward command.

# Verify if swap is enabled:
sudo swapon --show

sudo swapoff -a # if output is empty

### Download and Install Worker Binaries
wget -q --show-progress --https-only --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.21.0/crictl-v1.21.0-linux-amd64.tar.gz \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc93/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz \
  https://github.com/containerd/containerd/releases/download/v1.4.4/containerd-1.4.4-linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubelet

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
  tar -xvf crictl-v1.21.0-linux-amd64.tar.gz
  tar -xvf containerd-1.4.4-linux-amd64.tar.gz -C containerd
  sudo tar -xvf cni-plugins-linux-amd64-v0.9.1.tgz -C /opt/cni/bin/
  sudo mv runc.amd64 runc
  chmod +x crictl kubectl kube-proxy kubelet runc 
  sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
  sudo mv containerd/bin/* /bin/
}

# Configure CNI Networking
# Create the bridge network configuration file:
POD_CIDR=10.200.0.0/24

# the first config file in the cni/net.d firectory will be used.
cat <<EOF | sudo tee /etc/cni/net.d/11-bridge.conf
{
    "cniVersion": "0.4.0",
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
    "cniVersion": "0.4.0",
    "name": "lo",
    "type": "loopback"
}
EOF

## Configure containerd
# Create the containerd configuration file:
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

# Configure the Kubelet
{
  sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
  sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
  sudo mv ca.pem /var/lib/kubernetes/
}

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
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF

# Create the kubelet.service systemd unit file:
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
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
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
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}

{
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl restart containerd kubelet kube-proxy
}

# Configuring kubectl for Remote Access
# generate a kubeconfig file for the kubectl command line utility based on the admin user credentials.
# Each kubeconfig requires a Kubernetes API Server to connect to. 
# To support high availability the IP address assigned to the external load balancer fronting the Kubernetes API Servers will be used.

# Generate a kubeconfig file suitable for authenticating as the admin user:
{
  KUBERNETES_PUBLIC_ADDRESS=192.168.5.30

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}

# Check the version of the remote Kubernetes cluster:
kubectl version


# Deploy an overlay network to help with Pod networking, use the CLUSTER_CIDR range
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=10.200.0.0/16"

# https://www.weave.works/docs/net/latest/kubernetes/kube-addon/

### Deploying the DNS Cluster Add-on
## deploy the DNS add-on which provides DNS based service discovery, backed by CoreDNS, to applications running inside the Kubernetes cluster.
# Deploy the coredns cluster add-on:
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml

# Verification
# Create a busybox deployment:
kubectl run busybox --image=busybox:1.28 --command -- sleep 3600

# List the pod created by the busybox deployment:
kubectl get pods -l run=busybox

# Retrieve the full name of the busybox pod:
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")

# Execute a DNS lookup for the kubernetes service inside the busybox pod:
kubectl exec -ti $POD_NAME -- nslookup kubernetes




# cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRole
# metadata:
#   annotations:
#     rbac.authorization.kubernetes.io/autoupdate: "true"
#   labels:
#     kubernetes.io/bootstrapping: rbac-defaults
#   name: system:kube-apiserver-to-kubelet
# rules:
# - apiGroups: [""]
#   resources:
#   - nodes/proxy
#   - nodes/stats
#   - nodes/log
#   - nodes/spec
#   - nodes/metrics
#   - pods
#   verbs: ["*"]
# EOF

# # Bind the system:kube-apiserver-to-kubelet ClusterRole to the system:kube-apiserver user:

# cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
#   name: system:kube-apiserver
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: system:kube-apiserver-to-kubelet
# subjects:
# - kind: User
#   name: kubernetes
#   apiGroup: rbac.authorization.k8s.io
# EOF

# # You need to add this ClusterRole
# kubectl create clusterrolebinding apiserver-kubelet-admin --user=kube-apiserver --clusterrole=system:kubelet-api-admin
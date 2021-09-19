# #!/usr/bin/env bash

# # keygen admin machine
# {
#   ssh-keygen
#   cat ~/.ssh/id_rsa.pub

#   sudo cat >> ~/.ssh/authorized_keys <<EOF
# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJHO0I6yp+iOiEHyX7S1tNm+6jgznuvP05KUSqdCZRTEX2to0VcA18zTax7qTVHkmPfDrfPqen99ls7wzIUYie9jnDhFpFSCGoULen9eeJnkdQfy2HXMjrd6tFUar0kKoRFrAAW4lbrQ1uyYhasu4rzxeYPtMn24yM5tU1+us/2igtf5sbRprMw9FTTCoTk7AZwFpSD8DYrhVHWkLmuVM15pOeR3VWHOdPnyhlSs9ePsCM7TfNFS8mgPwBoEp1TDhoY7zk29og7Cyv/gGT8Hp3uQPg96wevT/tWbzeX9/TxfZ+h+pfnF1EM7EPhB8TdeAJLl1a1N9fGyG7kwoTOE++dtX4FCYgWLDup2xE2u7OrFqy8MGm+tWlOxMGEj5aeDFxDyosjLqxtAUIaMGtNsxWildBmEJBQv3OR74+4eh4gNgGwO5ElV0NqUs/neQuKtPX7cXltqe01fiub5Uzr+ZbkGnUEA/a5svornvBMibhMpIdTT8l1Mspc4C3LYCw3BE= vagrant@admin
# EOF
# }

# # Setup certificate tools
# {
#     wget -q --show-progress --https-only --timestamping \
#   https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl \
#   https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson

#   chmod +x cfssl cfssljson
#   sudo mv cfssl cfssljson /usr/local/bin/

#     wget https://storage.googleapis.com/kubernetes-release/release/v1.19.10/bin/linux/amd64/kubectl
#   chmod +x kubectl
#   sudo mv kubectl /usr/local/bin/
# }

# # Setup certificates
# {
# # Certificate authority
# cat > ca-config.json <<EOF
# {
#   "signing": {
#     "default": {
#       "expiry": "8760h"
#     },
#     "profiles": {
#       "kubernetes": {
#         "usages": ["signing", "key encipherment", "server auth", "client auth"],
#         "expiry": "8760h"
#       }
#     }
#   }
# }
# EOF

# cat > ca-csr.json <<EOF
# {
#   "CN": "Kubernetes",
#   "key": {
#     "algo": "rsa",
#     "size": 2048
#   },
#   "names": [
#     {
#       "C": "US",
#       "L": "Portland",
#       "O": "Kubernetes",
#       "OU": "CA",
#       "ST": "Oregon"
#     }
#   ]
# }
# EOF

# cfssl gencert -initca ca-csr.json | cfssljson -bare ca

# # client-server certificate
# cat > admin-csr.json <<EOF
# {
#   "CN": "admin",
#   "key": {
#     "algo": "rsa",
#     "size": 2048
#   },
#   "names": [
#     {
#       "C": "US",
#       "L": "Portland",
#       "O": "system:masters",
#       "OU": "Kubernetes The Hard Way",
#       "ST": "Oregon"
#     }
#   ]
# }
# EOF

# cfssl gencert \
#   -ca=ca.pem \
#   -ca-key=ca-key.pem \
#   -config=ca-config.json \
#   -profile=kubernetes \
#   admin-csr.json | cfssljson -bare admin

# # kubelet certificate
# for instance in worker-1 worker-2 worker-3; do
# cat > ${instance}-csr.json <<EOF
# {
#   "CN": "system:node:${instance}",
#   "key": {
#     "algo": "rsa",
#     "size": 2048
#   },
#   "names": [
#     {
#       "C": "US",
#       "L": "Portland",
#       "O": "system:nodes",
#       "OU": "Kubernetes The Hard Way",
#       "ST": "Oregon"
#     }
#   ]
# }
# EOF

# EXTERNAL_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)

# cfssl gencert \
#   -ca=ca.pem \
#   -ca-key=ca-key.pem \
#   -config=ca-config.json \
#   -hostname=${instance},${EXTERNAL_IP} \
#   -profile=kubernetes \
#   ${instance}-csr.json | cfssljson -bare ${instance}
# done

# # Controller manager certificate
# cat > kube-controller-manager-csr.json <<EOF
# {
#   "CN": "system:kube-controller-manager",
#   "key": {
#     "algo": "rsa",
#     "size": 2048
#   },
#   "names": [
#     {
#       "C": "US",
#       "L": "Portland",
#       "O": "system:kube-controller-manager",
#       "OU": "Kubernetes The Hard Way",
#       "ST": "Oregon"
#     }
#   ]
# }
# EOF

# cfssl gencert \
#   -ca=ca.pem \
#   -ca-key=ca-key.pem \
#   -config=ca-config.json \
#   -profile=kubernetes \
#   kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

# # Kube-proxy client certificate
# cat > kube-proxy-csr.json <<EOF
# {
#   "CN": "system:kube-proxy",
#   "key": {
#     "algo": "rsa",
#     "size": 2048
#   },
#   "names": [
#     {
#       "C": "US",
#       "L": "Portland",
#       "O": "system:node-proxier",
#       "OU": "Kubernetes The Hard Way",
#       "ST": "Oregon"
#     }
#   ]
# }
# EOF

# cfssl gencert \
#   -ca=ca.pem \
#   -ca-key=ca-key.pem \
#   -config=ca-config.json \
#   -profile=kubernetes \
#   kube-proxy-csr.json | cfssljson -bare kube-proxy

# # Scheduler certificate

# cat > kube-scheduler-csr.json <<EOF
# {
#   "CN": "system:kube-scheduler",
#   "key": {
#     "algo": "rsa",
#     "size": 2048
#   },
#   "names": [
#     {
#       "C": "US",
#       "L": "Portland",
#       "O": "system:kube-scheduler",
#       "OU": "Kubernetes The Hard Way",
#       "ST": "Oregon"
#     }
#   ]
# }
# EOF

# cfssl gencert \
#   -ca=ca.pem \
#   -ca-key=ca-key.pem \
#   -config=ca-config.json \
#   -profile=kubernetes \
#   kube-scheduler-csr.json | cfssljson -bare kube-scheduler

# # Api-server certificate
# KUBERNETES_PUBLIC_ADDRESS=192.168.5.30

# KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

# cat > kubernetes-csr.json <<EOF
# {
#   "CN": "kubernetes",
#   "key": {
#     "algo": "rsa",
#     "size": 2048
#   },
#   "names": [
#     {
#       "C": "US",
#       "L": "Portland",
#       "O": "Kubernetes",
#       "OU": "Kubernetes The Hard Way",
#       "ST": "Oregon"
#     }
#   ]
# }
# EOF

# cfssl gencert \
#   -ca=ca.pem \
#   -ca-key=ca-key.pem \
#   -config=ca-config.json \
#   -hostname=10.32.0.1,192.168.5.11,192.168.5.12,192.168.5.13,192.168.5.30,192.168.5.40,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
#   -profile=kubernetes \
#   kubernetes-csr.json | cfssljson -bare kubernetes

# # Service account certificates
# cat > service-account-csr.json <<EOF
# {
#   "CN": "service-accounts",
#   "key": {
#     "algo": "rsa",
#     "size": 2048
#   },
#   "names": [
#     {
#       "C": "US",
#       "L": "Portland",
#       "O": "Kubernetes",
#       "OU": "Kubernetes The Hard Way",
#       "ST": "Oregon"
#     }
#   ]
# }
# EOF

# cfssl gencert \
#   -ca=ca.pem \
#   -ca-key=ca-key.pem \
#   -config=ca-config.json \
#   -profile=kubernetes \
#   service-account-csr.json | cfssljson -bare service-account
# }

# # Kubernetes configuration files for authentication
# {
#     KUBERNETES_PUBLIC_ADDRESS=192.168.5.30

#     for instance in worker-1 worker-2 worker-3; do
#         kubectl config set-cluster kubernetes-the-hard-way \
#             --certificate-authority=ca.pem \
#             --embed-certs=true \
#             --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
#             --kubeconfig=${instance}.kubeconfig

#         kubectl config set-credentials system:node:${instance} \
#             --client-certificate=${instance}.pem \
#             --client-key=${instance}-key.pem \
#             --embed-certs=true \
#             --kubeconfig=${instance}.kubeconfig

#         kubectl config set-context default \
#             --cluster=kubernetes-the-hard-way \
#             --user=system:node:${instance} \
#             --kubeconfig=${instance}.kubeconfig

#         kubectl config use-context default --kubeconfig=${instance}.kubeconfig
#     done

#     kubectl config set-cluster kubernetes-the-hard-way \
#         --certificate-authority=ca.pem \
#         --embed-certs=true \
#         --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
#         --kubeconfig=kube-proxy.kubeconfig

#     kubectl config set-credentials system:kube-proxy \
#         --client-certificate=kube-proxy.pem \
#         --client-key=kube-proxy-key.pem \
#         --embed-certs=true \
#         --kubeconfig=kube-proxy.kubeconfig

#     kubectl config set-context default \
#         --cluster=kubernetes-the-hard-way \
#         --user=system:kube-proxy \
#         --kubeconfig=kube-proxy.kubeconfig

#     kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig


#     kubectl config set-cluster kubernetes-the-hard-way \
#         --certificate-authority=ca.pem \
#         --embed-certs=true \
#         --server=https://127.0.0.1:6443 \
#         --kubeconfig=kube-controller-manager.kubeconfig

#     kubectl config set-credentials system:kube-controller-manager \
#         --client-certificate=kube-controller-manager.pem \
#         --client-key=kube-controller-manager-key.pem \
#         --embed-certs=true \
#         --kubeconfig=kube-controller-manager.kubeconfig

#     kubectl config set-context default \
#         --cluster=kubernetes-the-hard-way \
#         --user=system:kube-controller-manager \
#         --kubeconfig=kube-controller-manager.kubeconfig

#     kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

#         kubectl config set-cluster kubernetes-the-hard-way \
#         --certificate-authority=ca.pem \
#         --embed-certs=true \
#         --server=https://127.0.0.1:6443 \
#         --kubeconfig=kube-scheduler.kubeconfig

#     kubectl config set-credentials system:kube-scheduler \
#         --client-certificate=kube-scheduler.pem \
#         --client-key=kube-scheduler-key.pem \
#         --embed-certs=true \
#         --kubeconfig=kube-scheduler.kubeconfig

#     kubectl config set-context default \
#         --cluster=kubernetes-the-hard-way \
#         --user=system:kube-scheduler \
#         --kubeconfig=kube-scheduler.kubeconfig

#     kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

#         kubectl config set-cluster kubernetes-the-hard-way \
#         --certificate-authority=ca.pem \
#         --embed-certs=true \
#         --server=https://127.0.0.1:6443 \
#         --kubeconfig=admin.kubeconfig

#     kubectl config set-credentials admin \
#         --client-certificate=admin.pem \
#         --client-key=admin-key.pem \
#         --embed-certs=true \
#         --kubeconfig=admin.kubeconfig

#     kubectl config set-context default \
#         --cluster=kubernetes-the-hard-way \
#         --user=admin \
#         --kubeconfig=admin.kubeconfig

#     kubectl config use-context default --kubeconfig=admin.kubeconfig
# }

# {
#   for instance in worker-1 worker-2 worker-3; do
#    scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
# done

# for instance in controller-1 controller-2 controller-3; do
#    scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
#     service-account-key.pem service-account.pem ${instance}:~/
# done

# }

# {
#   # distribute kubeconfig

#     for instance in worker-1 worker-2 worker-3; do
#         scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
#     done

#     for instance in controller-1 controller-2 controller-3; do
#         scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
#     done
# }

# # Data encryption keys
# {
#     ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
#     cat > encryption-config.yaml <<EOF
# kind: EncryptionConfig
# apiVersion: v1
# resources:
#   - resources:
#       - secrets
#     providers:
#       - aescbc:
#           keys:
#             - name: key1
#               secret: ${ENCRYPTION_KEY}
#       - identity: {}
# EOF

# for instance in controller-1 controller-2 controller-3; do
#   scp encryption-config.yaml ${instance}:~/
# done
# }

#!/usr/bin/env bash

# keygen admin machine
{
  ssh-keygen
  cat ~/.ssh/id_rsa.pub

  sudo cat >> ~/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxjNnMm1X+y7CiAona+yt32AikSeHNMxsuVAEelQXrdJx+i8HqKhM4UOPKFl139Kw5wagXLoM6Nv4bqHxORtU5ju3p0AavVnHA0qrIOas8qms0T9pvxZ3cNZb6Fa7w1hO2Wx1u+NqiDzMbzMbfo9qGcOi5nQjj7f2uMDfESANkzXSLgygeI9VnGjSuZ3bBQD/8e0olu8h/tSbvOHrZj+CoLb+kIL5ef7yr4uqg2d6V7aqQZwZ/uk00zDABaL4moc/k7fI4yL6Dn2aMrXhTfaMBID+/9KPSvEz2T3kpHv9GCAj21VwC1HKDDOxJ8uvNOySjiHaND/Jyb+LVBunVjpTxlmYyNmbNCJ6o3kzycvai8MZw+S4CTRpCXALubdfmBJuH7V2+iR9Yae+/Orz+fsnGpi1VQqMelRqCPZYSUnqHx6y/mEy12Uei2YPrmGzhvJ9aiRWoOOV5eyAuZnyuGS/Ao+fq3hTHymJ9dN0vMhbZE6Y9KwsLMRBZ/MKF4pMvHnM= vagrant@admin
EOF
}

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

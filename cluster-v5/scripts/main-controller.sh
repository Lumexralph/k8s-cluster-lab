# Install controlplane components on the MAIN controlplane-1 node using kubeadm

LOAD_BALANCER_DNS=192.168.5.30
LOAD_BALANCER_PORT=6443

# check the connection 
nc -v $LOAD_BALANCER_DNS $LOAD_BALANCER_PORT

sudo kubeadm init --apiserver-advertise-address 192.168.5.11 \
 --pod-network-cidr 192.168.0.0/16 --control-plane-endpoint "${LOAD_BALANCER_DNS}:${LOAD_BALANCER_PORT}" --upload-certs


# After installation has finished, setup kubeconfig file
{
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

# IMPORTANT (copy the generated kubeadm join command for controlplane and worker nodes)
#You can now join any number of the control-plane node running the following command on each as root:

# Join the other controlplane nodes to the cluster with the output above
sudo kubeadm join 192.168.5.30:6443 --apiserver-advertise-address 192.168.5.13 --token mt6bwo.izvrlfyl5cskv5rj \
	--discovery-token-ca-cert-hash \
	sha256:7e9e2cb2cbca85f7fad5c8313b2c42860dc0c2145584ef25367ff1d49490c854 \
	--control-plane --certificate-key b407386d5a33ad8ed41f7b32b78bc03f7bc2a4a2405fc05b1ce653e256268eee --v=5

# Join the worker nodes to the cluster with above command
kubeadm join 192.168.5.30:6443 --token d5gpya.rdaogyxj7k2smj98 \
	--discovery-token-ca-cert-hash sha256:967e5d98234f5bd8c36e7b9e92cec8c8e2190611990f74fa8db1ae671fe2ea49

# Enable pod networking by installing CNI plugin (calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# controller-1 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.0.2.15 192.168.5.30]
# You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
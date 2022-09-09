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

# Enable pod networking by installing CNI plugin (calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# IMPORTANT (copy the generated kubeadm join command for controlplane and worker nodes)
#You can now join any number of the control-plane node running the following command on each as root:

# Join the other controlplane nodes to the cluster with the output above
sudo kubeadm join 192.168.5.30:6443 --token bglzls.uanvy6q8mho1rxhf \
	--discovery-token-ca-cert-hash sha256:dc0701fb328a0dff4666abbab96490791925b9547e5b7ef701c111026cd6cd3d \
	--control-plane --certificate-key 410a6c0f7c89fdd52d9b48b2a2468c3be1a392c84386d2aabb5b5b151939d777 --v=5

# Join the worker nodes to the cluster with above command
sudo kubeadm join 192.168.5.30:6443 --token bglzls.uanvy6q8mho1rxhf \
 --discovery-token-ca-cert-hash sha256:dc0701fb328a0dff4666abbab96490791925b9547e5b7ef701c111026cd6cd3d --v=5


# controller-1 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.0.2.15 192.168.5.30]
# You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
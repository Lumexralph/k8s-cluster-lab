# Install controlplane components on the MAIN controlplane-1 node using kubeadm

LOAD_BALANCER_DNS=192.168.5.30
LOAD_BALANCER_PORT=6443

# check the connection 
nc -v $LOAD_BALANCER_DNS $LOAD_BALANCER_PORT

sudo kubeadm init --apiserver-advertise-address 192.168.5.11 \
 --pod-network-cidr 10.200.0.0/16 --control-plane-endpoint "${LOAD_BALANCER_DNS}:${LOAD_BALANCER_PORT}" --upload-certs


# After installation has finished, setup kubeconfig file
{
	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

# IMPORTANT (copy the generated kubeadm join command for controlplane and worker nodes)
#You can now join any number of the control-plane node running the following command on each as root:

# Join the other controlplane nodes to the cluster with the output above
sudo kubeadm join 192.168.5.30:6443 --apiserver-advertise-address 192.168.5.12 --token 0e0bgq.lah5jv93qnc4nvik \
	--discovery-token-ca-cert-hash <sha> \
	--control-plane --certificate-key <key> --v=5

# Join the worker nodes to the cluster with above command
sudo kubeadm join 192.168.5.30:6443 --token 0e0bgq.lah5jv93qnc4nvik \
	--discovery-token-ca-cert-hash <hash> --v=5


# controller-1 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.0.2.15 192.168.5.30]
# You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

# Enable pod networking by installing CNI plugin (calico)
# download calico network-plugin manifests
# Install the Tigera Calico operator and custom resource definitions.
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/tigera-operator.yaml

# Install Calico by creating the necessary custom resource and update the pod cidr as used 
# during the kubeadm init
curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/custom-resources.yaml -O

# Check and customize the manifest as necessary.
# apply the manifest
kubectl apply -f custom-resources.yaml


#### Removing a node from a cluster
kubectl drain controller-2 --delete-emptydir-data --force --ignore-daemonsets

### Test that everything is working in the cluster
kubectl run --generator=run-pod/v1  busybox --image=busybox:1.28 --command -- sleep 3600
kubectl get pods -l run=busybox

# Execute a DNS lookup for the kubernetes service inside the busybox pod:
kubectl exec -ti busybox -- nslookup kubernetes

## Smoke Tests
# Deployment
kubectl create deployment nginx --image=nginx
kubectl get pods -l app=nginx

# Services
kubectl expose deploy nginx --type=NodePort --port 80
PORT_NUMBER=$(kubectl get svc -l app=nginx -o jsonpath="{.items[0].spec.ports[0].nodePort}")

curl http://192.168.5.21:$PORT_NUMBER # worker 1
curl http://192.168.5.22:$PORT_NUMBER # worker 2

# Logs
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
kubectl logs $POD_NAME

# Execs
kubectl exec -ti $POD_NAME -- nginx -v

# view routing tables of node
 ip route

# configuring the network interface 
# Add "--node-ip" to '/var/lib/kubelet/kubeadm-flags.env':
cat /var/lib/kubelet/kubeadm-flags.env

KUBELET_KUBEADM_ARGS=--cgroup-driver=systemd --network-plugin=cni --pod-infra-container-image=k8s.gcr.io/pause:3.1 --node-ip=10.10.10.1

# Restart Kubelet:
sudo systemctl daemon-reload && sudo systemctl restart kubelet

kubectl delete -f https://docs.projectcalico.org/v3.20/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
kubectl delete -f https://docs.projectcalico.org/v3.20/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml

kubectl delete -f https://docs.projectcalico.org/v3.20/manifests/calico.yaml


kubectl delete -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"


# Safely removing a Node
kubectl drain <node-name>

kubectl drain <node-name> --ignore-daemonsets --delete-local-data

kubectl delete node <node-name>
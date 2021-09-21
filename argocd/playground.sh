# create a new namespace, argocd, where Argo CD services 
# and application resources will live.
kubectl create namespace argocd

# Install argocd into the cluster
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# install argocd on your machine (Mac)
brew install argocd

# Access The Argo CD API Server

# 1. Expose it using an External IP

# 2. Service Type Load Balancer, Change the argocd-server service type to LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# 3. Ingress

# 4. Port-forwarding, The API server can then be accessed using the localhost:8080
kubectl port-forward svc/argocd-server -n argocd 8080:443


# a secret named argocd-initial-admin-secret in your Argo CD installation namespace. You can simply retrieve this password using kubectl:
kubectl -n argocd get secret argocd-initial-admin-secret -o

# get the password and encode as base64
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# use the password to login to the argoCD UI: 
# username: admin, password: <>

# using the CLI:
# Using the username admin and the password from above, login to Argo CD's IP or hostname:

argocd login <ARGOCD_SERVER>

# change the user's admin password:
argocd account update-password

# list all clusters contexts in your current kubeconfig:
kubectl config get-contexts -o name

# Choose a context name from the list and supply it to argocd cluster add CONTEXTNAME
argocd cluster add <context>
# create a new namespace, argocd, where Argo CD services 
# and application resources will live.
kubectl create namespace argocd

# Install argocd into the cluster
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# install argocd on your machine (Mac)
brew install argocd

# Access The Argo CD API Server

# 1. Expose it using NodePort service type
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# 2. Service Type Load Balancer, Change the argocd-server service type to LoadBalancer, use MetalLB for bare metal
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

# crete namespace
kubectl create namespace lumex-lab

# Create an App
argocd app create guestbook --repo https://github.com/Lumexralph/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace lumex-lab

# Once the guestbook application is created, you can now view its status:
argocd app get guestbook

# To sync (deploy) the application, run:
argocd app sync guestbook

# view the sample guestbook application using and open localhost:8090 in your browser:
kubectl port-forward svc/guestbook-ui 8090:80

##### Installation of MetalLb to create a bare metal lodbalancer for 
### the ambassador ingress
# manisfest
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/namespace.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/metallb.yaml

helm repo add metallb https://metallb.github.io/metallb

# attach our configuration
helm install metallb metallb/metallb -f metallb/values.yaml --namespace metallb

##### Install Edge Stack and deploy a Mapping via ArgoCD
## start by installing Ambassador Edge Stack into your cluster.
# using helm
# Add the Repo:
helm repo add datawire https://www.getambassador.io
 
# Create Namespace and Install:
kubectl create namespace ambassador

helm install ambassador --namespace ambassador datawire/ambassador 

kubectl -n ambassador wait --for condition=available --timeout=90s deploy -lproduct=aes

# Check your version:
kubectl get deploy --namespace ambassador ambassador -o jsonpath='{.spec.template.spec.containers[0].image}'


# Store the Ambassador Edge Stack load balancer IP address to a local environment variable. 
# You will use this variable to test accessing your service.
export AMBASSADOR_LB_ENDPOINT=$(kubectl -n ambassador get svc ambassador \
  -o "go-template={{range .status.loadBalancer.ingress}}{{or .ip .hostname}}{{end}}")

# Test the configuration by accessing the service through the Ambassador Edge Stack load balancer:
#
curl -Lk https://$AMBASSADOR_LB_ENDPOINT/guestbook/

kubectl -n <namespace> get endpoints <service>

kubectl -n ambassador get endpoints ambassador

# To add your cluster to ambassador cloud
# Assuming your installation is in the ambassador namespace, run:
kubectl create configmap --namespace ambassador ambassador-agent-cloud-token --from-literal=CLOUD_CONNECT_TOKEN=<TOKEN>

####### Integrating Argo Rollouts ########
#####
# Argo Rollouts
kubectl create namespace argo-rollouts

kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Fork the rollouts-demo repo:
# Fork the rollouts demo repository and clone your fork into your 
# local environment. This repo contains a series of Kubernetes 
# services that you will add to the service catalog and use to perform a rollout.
git clone https://github.com/Lumexralph/rollouts-demo.git && cd rollouts-demo

# https://www.getambassador.io/docs/argo/latest/howtos/configure-argo-rollouts/

# Update the service manifests with the proper git repo and branch
# Commit and push your changes to your fork:
git add manifests/service.yaml && git commit -m "Update service repo url" && git push

# From your root of your locally forked rollouts-demo repository,
# apply the Kubernetes manifests to your cluster:
kubectl apply -f ./manifests

cat <<EOF | kubectl apply -f - 
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  creationTimestamp: null
  name: ac-rollout-demo-default
  namespace: argocd
spec:
  destination:
    namespace: default
    server: https://kubernetes.default.svc
  project: default
  source:
    path: manifests
    repoURL: git@github.com:Lumexralph/rollouts-demo.git
    targetRevision: main
  syncPolicy:
    automated: {}

EOF

# install argo plugin on kubectl
brew install argoproj/tap/kubectl-argo-rollouts

# create an Argo CD project using your forked demo repo as the
# target. You can do this either through the Argo CD UI or the CLI
argocd app create demoapp --repo https://github.com/Lumexralph/summer-of-k8s-app-manifests.git --path . --dest-server https://kubernetes.default.svc --dest-namespace lumex-lab

# view the ststus of the app
argocd app get demoapp

# Trigger a sync on this project in Argo CD so that 
# your sample app deploys into your cluster.
# To sync (deploy) the application, run:
argocd app sync demoapp

# watch the rollout status:
kubectl argo rollouts get rollout summer-k8s-rollout -n lumex-lab -w

# Manually promote
kubectl argo rollouts promote summer-k8s-rollout -n lumex-lab

##### NOT RELATED #######
# I needed to debug my github page DNS
dig lumexralph.github.io
dig lumexralph.github.io +nostats +nocomments +nocmd

tcpdump -n -i eth1 arp src host 192.168.10.0

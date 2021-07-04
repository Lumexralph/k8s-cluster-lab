# Let's look at our Node resources with kubectl get!
kubectl get nodes
kubectl get no
kubectl get node

# kubectl get can output JSON, YAML, or be directly formatted
# Give us more info about the nodes:
kubectl get nodes -o wide

# To output YAML
kubectl get no -o yaml

# We can use jq to stream out JSON objects
# NB: install jq if you don't have it installed
# ref: https://stedolan.github.io/jq/download/
kubectl get nodes -o json | jq ".items[] | {name:.metadata.name} + .status.capacity"

# We can list all available resource types by running:
kubectl api-resources

# We can view the definition for a resource type with:
# sc == StorageClass
kubectl explain sc
# We can view the definition of a field in a resource:
kubectl explain node.spec
# Or get the full definition of all fields and sub-fields:
kubectl explain node --recursive

# kubectl describe needs a resource type and (optionally) a resource name:
# kubectl describe will retrieve some extra information about the resource
# kubectl describe node <nodename>
kubectl describe node/worker-1

# List pods on our cluster:
kubectl get pods

# Namespaces allows us to segregate resources
# By default, kubectl uses the default namespace
kubectl get namespaces
kubectl get namespace
kubectl get ns

# We can get pods all namesapces in the custer:
# List pods in all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A
# List only the pods in the kube-system namespace:
kubectl get pods --namespace=kube-system
kubectl get pods -n kube-system

# The only interesting object in kube-public namespace is a ConfigMap called cluster-info
kubectl  -n kube-public get configmaps

# Service is a stable endpoint to connect to something:
# There is already one service in the cluter: Kubernetes API
kubectl get svc
kubectl get services

# Viewing container output:
kubectl logs <podname>
kubectl logs <type/name>
# View the latest logs:
kubectl logs <podname> --tail 1 --follow

# Jobs
kubectl create job flipcoin --image=alpine -- sh -c 'exit $(($RANDOM%2))'
# Check the status of the Pod(s) created by the Job:
kubectl get pods --selector=job-name=flipcoin

# CronJobs: Requires a schedule, represented by five space-separated fields:
# Minute [0, 59]
# Hours [0, 23]
# Day of the month [1, 31]
# Month of the year [1, 12]
# Day of the week [0, 6, 0 = Sunday]
# Create CronJob:
kubectl create cronjob every3mins --schedule="*/3 * * * *" \
    --image=alpine -- sleep 10
# Check the resource that was created:
kubectl get cronjobs
# You can set a limit using the spec.activeDeadlineSeconds field

# # LABELS
# Selectors: is an expression matching labels
# List all the pods with at least app=clock:
kubectl get pods --selector=app=clock
# List all the pods with a label app, regardless of its value
kubectl get pods --selector=app
# Set a label on the clock Deployment:
kubectl label deployment clock color=blue
# List all the labels that we have on pods:
kubectl get pods --show-labels
# List the value of label app on these pods:
kubectl get pods -L app
# Show labels for a bunch of objects:
kubectl get --show-labels po,rs,deploy,svc,no
# View the last line of log from all pods with the app=pingpong
kubectl logs -l app=pingpong --tail 1

# For streaming multiple logs: use Stern
# The following commands will install Stern on a Linux Intel 64 bit machine:

sudo curl -L -o /usr/local/bin/stern \
   https://github.com/wercker/stern/releases/download/1.11.0/stern_linux_amd64

sudo chmod +x /usr/local/bin/stern

stern nginx

# View what's up with the weave system containers:
stern --tail 1 --timestamps --all-namespaces weave
# View the logs for all the things started with kubectl create deployment:
stern -l app

# An easy way to create a service is to use kubectl expose
# If we have a deployment named my-little-deploy, we can run:
# This will create a service with the same name (my-little-deploy):
kubectl expose deployment my-little-deploy --port=80
# we can now connect to http://my-little-deploy/

# In another window, watch the pods (to see when they are created):
kubectl get pods -w
# Create a deployment for this very lightweight HTTP server:
kubectl create deployment httpenv --image=jpetazzo/httpenv
# Scale it to 10 replicas:
kubectl scale deployment httpenv --replicas=10
# We'll create a default ClusterIP service:
# Expose the HTTP port of the server:
kubectl expose deployment httpenv --port 8888
# Look up which IP address was allocated:
kubectl get service
# Let's obtain the IP address that was allocated for our service, programmatically:
IP=$(kubectl get svc httpenv -o go-template --template '{{ .spec.clusterIP }}')
# send a request to that IP
curl http://$IP:8888
curl -s http://$IP:8888/ | jq .HOSTNAME

# We can add an External IP to a service, e.g.:
# 192.168.5.23 should be the address of one of our nodes
kubectl expose deploy httpenv --port=80 --external-ip=192.168.5.23
# Check the endpoints that Kubernetes has associated with our httpenv service:
kubectl describe service httpenv
kubectl describe endpoints httpenv
kubectl get endpoints httpenv -o yaml

# Services
# Get the IP address of the internal DNS server:
IP=$(kubectl -n kube-system get svc kube-dns -o jsonpath={.spec.clusterIP})
# The default domain name for the kube-dns service == default.svc.cluster.local
# Resolve the cluster IP for the httpenv service:
host httpenv.default.svc.cluster.local $IP

# Deploying a self-hosted registry
# We will deploy a registry container, and expose it with a NodePort
# Create the registry service:
kubectl create deployment registry --image=registry
# Expose it on a NodePort:
kubectl expose deploy/registry --port=5000 --type=NodePort
# We need to find out which port has been allocated
# View the service details:
kubectl describe svc/registry
# Get the port number programmatically:
NODEPORT=$(kubectl get svc/registry -o json | jq .spec.ports[0].nodePort)
REGISTRY=127.0.0.1:$NODEPORT
# View the repositories currently held in our registry: (RUN FROM A NODE IN THE CLUSTER)
# PS: We are in different subnets, you'll need to get the IP address of the node the
# registry service is provisioned. kubectl get pods registry
curl $REGISTRY/v2/_catalog

# Dump an existing resource with:
kubectl get -o yaml <resorucetype/resource>
# Generate the YAML for a Deployment without creating it:
kubectl create deployment web --image nginx --dry-run
kubectl apply -f web.yaml --dry-run=server --validate=false -o yaml
# kubectl diff does a server-side dry run, and shows differences
# Try kubectl diff on the YAML that we tweaked earlier:
kubectl diff -f web.yaml

# git clone https://github.com/IBM/guestbook.git
# Get a shell to the container:
kubectl exec -it shell-demo -- /bin/bash

# Watching Pods and Events in the Cluster:
kubectl get events -A -w
kubectl get pods -A -w

# This command creates a deployment and a pod. Then it drops you right into a shell where you can run commands
kubectl run -it --image=amouat/network-utils --attach network-utils -- /bin/bash

# You may list all these interfaces on your node using 
ifconfig 
ip a

# Kubectl context to be able to interact with different clusters
# In order to interact with a specific cluster, you only need to specify the cluster name as a context in kubectl:
# kind-kind is the clucter context in the ~/.kube/config file.
kubectl cluster-info --context kind-kind

# Using Kustomize:
# kustomize/deployment == <Kustomize directory>
kubectl kustomize kustomize/deployment | kubectl apply -f -


# VERY IMPORTANT TO FIND A FILE
# search for a file vips.pc starting from the root
sudo find / -name vips.pc
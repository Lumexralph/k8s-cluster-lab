# You can validate your setup by running:
kubectl version --short

# Install the CLI
## The CLI will allow you to interact with your Linkerd deployment.
# Be sure to put the binary on your PATH
curl -sL run.linkerd.io/install | sh

# OR on MacOS
brew install linkerd

# verify the CLI is running correctly with:
## It will output version for client and server (control plane) if installed in the cluster already:
linkerd version

# To check that your cluster is ready to install Linkerd, run:
linkerd check --pre

# linkerd install command generates a Kubernetes manifest
# with all the core control plane resources.
# install the control plane core, run:
linkerd install | kubectl apply -f -

# check the state of the cluster after install
linkerd check

# Install Emojivoto into the emojivoto namespace by running:
curl -fsL https://run.linkerd.io/emojivoto.yml | kubectl apply -f -

# Forward web-svc locally to port 8080 by running:
# Now visit http://localhost:8080
kubectl -n emojivoto port-forward svc/web-svc 8080:80

# With Emoji installed and running, 
# we’re ready to mesh it - that is, to add Linkerd’s data plane proxies to it.
# linkerd inject command simply adds annotations to the pod spec that instruct 
# Linkerd to inject the proxy into the pods when they are created.
# Mesh the Emojivoto application by running:
kubectl get -n emojivoto deploy -o yaml \
  | linkerd inject - \
  | kubectl apply -f -


# Check your data plane with:
linkerd -n emojivoto check --proxy

# Install some extensions to give us additional functionality
## To install the viz extension, run:
# install the on-cluster metrics stack
linkerd viz install | kubectl apply -f -

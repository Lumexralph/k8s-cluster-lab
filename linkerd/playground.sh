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

# Install some extensions to give us additional functionality
## To install the viz extension, run:
# install the on-cluster metrics stack
linkerd viz install | kubectl apply -f -

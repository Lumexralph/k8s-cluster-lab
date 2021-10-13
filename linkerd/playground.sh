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
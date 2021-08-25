https://github.com/kubernetes-sigs/kustomize/tree/master/examples/helloWorld

# Make a new directory with the parent directory and download
# the contents to that directory. (configMap,deployment,kustomization,service)
BASE=$DEMO_HOME/base
mkdir -p $BASE

curl -s -o "$BASE/#1.yaml" "https://raw.githubusercontent.com\
/kubernetes-sigs/kustomize\
/master/examples/helloWorld\
/{configMap,deployment,kustomization,service}.yaml"

# Look at the directory structure:
#
tree $DEMO_HOME

# One could immediately apply these resources to a cluster:
# -k means kustomize
#
kubectl apply -k $DEMO_HOME/base

# Optionally, run kustomize on the base to emit customized resources to stdout:
#
BASE=$DEMO_HOME/base
kustomize build $BASE

# Go to the file kustomization.yaml and change every occurrence to my-hello
# in the line app: occurs
# change the app label applied to all resources:
sed -i.bak 's/app: hello/app: my-hello/' \
    $BASE/kustomization.yaml

kustomize build $BASE | grep -C 3 app:

# Create a staging and production overlay:

# Staging enables a risky feature not enabled in production.
# Production has a higher replica count.
# Web server greetings from these cluster variants will differ from each other.
#
OVERLAYS=$DEMO_HOME/overlays
mkdir -p $OVERLAYS/staging
mkdir -p $OVERLAYS/production

# STAGING #
# In the staging directory, make a kustomization defining a new name prefix, and some different labels.
#
cat <<'EOF' >$OVERLAYS/staging/kustomization.yaml
namePrefix: staging-
commonLabels:
  variant: staging
  org: acmeCorporation
commonAnnotations:
  note: Hello, I am staging!
bases:
- ../../base
patchesStrategicMerge:
- map.yaml
EOF

# Add a configMap customization to change the server greeting from Good Morning! to Have a pineapple!
# Also, enable the risky flag.
#
cat <<EOF >$OVERLAYS/staging/map.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: the-map
data:
  altGreeting: "Have a staging build!"
  enableRisky: "true"
EOF

## PRODUCTION ##

# In the production directory, make a kustomization with a different name prefix and labels.
#
cat <<EOF >$OVERLAYS/production/kustomization.yaml
namePrefix: production-
commonLabels:
  variant: production
  org: acmeCorporation
commonAnnotations:
  note: Hello, I am production!
bases:
- ../../base
patchesStrategicMerge:
- deployment.yaml
EOF

# Make a production patch that increases the replica count (because production takes more traffic).
#
cat <<EOF >$OVERLAYS/production/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: the-deployment
spec:
  replicas: 10
EOF


##### Deploy to your cluster #######
# To deploy, pipe the above commands to kubectl apply:
# staging deployment
kustomize build $OVERLAYS/staging |\
    kubectl apply -f -

# production deployment
kustomize build $OVERLAYS/production |\
   kubectl apply -f -

# Compare the output directly to see how staging and production differ:
# Run the kustomize script for both staging and production and 
# pipe them into more
diff \
  <(kustomize build $OVERLAYS/staging) \
  <(kustomize build $OVERLAYS/production) |\
  more
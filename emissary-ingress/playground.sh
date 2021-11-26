# Add the Repo:
helm repo add datawire https://app.getambassador.io
helm repo update

# Create Namespace and Install:
kubectl create namespace emissary && \
helm install emissary-ingress --devel --namespace emissary datawire/emissary-ingress && \
kubectl -n emissary wait --for condition=available --timeout=90s deploy -lapp.kubernetes.io/instance=emissary-ingress

# create a Listener to tell what port emissary is listening from
kubectl apply -f - <<EOF
---
apiVersion: getambassador.io/v3alpha1
kind: Listener
metadata:
  name: emissary-ingress-listener
  namespace: emissary
spec:
  port: 8080
  protocol: HTTPS
  securityModel: XFP
  hostBinding:
    namespace:
      from: ALL
EOF

# Create Emissary Mapping for the voting app web service


# Install the quote app
kubectl apply -f https://app.getambassador.io/yaml/v2-docs/latest/quickstart/qotm.yaml

kubectl get services,deployments quote

kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
   name: emissary
   annotations:
     linkerd.io/inject: enabled
EOF

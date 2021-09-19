#!/usr/bin/env bash

kubectl apply -f cluster_boostrap/ingress-nginx.yaml

kubectl scale deployment/ingress-nginx-controller -n ingress-nginx --replicas=3

# worker around - ingress admission validation
# https://stackoverflow.com/questions/61365202/nginx-ingress-service-ingress-nginx-controller-admission-not-found
{
    kubectl get validatingwebhookconfigurations
    kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
}

# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update

# helm show values ingress-nginx/ingress-nginx > /tmp/ingress-nginx.yaml

# helm install auth-ingress ingress-nginx/ingress-nginx -n ingress-nginx --values /tmp/ingress-nginx.yaml --set RELEASE-NAME=auth

# helm install auth ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --values /tmp/ingress-nginx.yaml \
#     --set annotations."meta\.helm\.sh/release-name"="auth"

# Nginx controller removal
{
    kubectl delete clusterrolebinding ingress-nginx
    kubectl delete clusterrole ingress-nginx
    kubectl delete ns ingress-nginx
}

kubectl logs -n ingress-nginx ingress-nginx-controller-5wwjd

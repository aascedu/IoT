#! /bin/bash

CLUSTER_NAME=p3-cluster

k3d cluster create $CLUSTER_NAME --api-port 6550 -p "8888:80@loadbalancer" --servers 1 --agents 1
export KUBECONFIG="$(k3d kubeconfig write k3s-default)"
kubectl apply -f confs/namespaces.yml
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
kubectl apply -f confs/disable_tls.yml
kubectl rollout restart deployment argocd-server -n argocd
kubectl apply -f confs/argocd_ingress.yml
kubectl apply -f confs/wil_app.yml

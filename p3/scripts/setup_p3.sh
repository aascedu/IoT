#! /bin/bash

CLUSTER_NAME=p3-cluster

k3d cluster create "$CLUSTER_NAME" --api-port 6550 -p "8888:80@loadbalancer" --servers 1 --agents 1
kubectl apply -f confs/namespaces.yml
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
sleep 15
kubectl apply -f confs/disable_tls.yml
kubectl -n argocd patch cm argocd-cmd-params-cm \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd
kubectl apply -f confs/argocd_ingress.yml
kubectl apply -f confs/wil_app.yml
#! /bin/bash

CLUSTER_NAME=p3_cluster

k3d cluster create $CLUSTER_NAME --api-port 6550 -p "8888:80@loadbalancer" --server 1 --agents 1
export KUBECONFIG="$(k3d kubeconfig write k3s-default)"
kubectl apply -f wil_app.yml
#! /bin/bash

CLUSTER_NAME=bonus-cluster

k3d cluster create $CLUSTER_NAME --api-port 6550 -p "8888:80@loadbalancer" --servers 1 --agents 1 \
  --volume /home/aascedu/mount_dir/:/var/lib/rancher/k3s/storage@server:0 \
  --k3s-arg '--kubelet-arg=eviction-hard=imagefs.available<1%,nodefs.available<1%@agent:*' \
  --k3s-arg '--kubelet-arg=eviction-minimum-reclaim=imagefs.available=1%,nodefs.available=1%@agent:*'
export KUBECONFIG="$(k3d kubeconfig write k3s-default)"
echo my passwd:$PASSWD
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=aascedu \
  --docker-password="$PASSWD" \
  --docker-email=arthurascedusnkrs@gmail.com
kubectl patch serviceaccount default -n gitlab -p '{"imagePullSecrets":[{"name":"regcred"}]}'
kubectl apply -f confs/namespaces.yml
# kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
# kubectl apply -f confs/disable_tls.yml
# kubectl apply -f confs/argocd_ingress.yml
# kubectl apply -f confs/wil_app.yml
# kubectl rollout restart deployment argocd-server -n argocd
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm install gitlab gitlab/gitlab \
  -n gitlab \
  -f /home/aascedu/bonus/gitlab_chart.yml
kubectl apply -f confs/gitlab_ingress.yml

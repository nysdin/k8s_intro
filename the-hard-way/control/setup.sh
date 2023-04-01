#!/bin/bash -eu

# 全ての Master ノードで以下のコンポートネントを起動する
## - kube-apiserver
## - kube-scheduler
## - kube-controller-manager

. ../common.sh

for instance in ${controllers[@]}; do
  gcloud compute scp setup_controller.sh ubuntu@${instance}:/tmp/setup_controller.sh
  gcloud compute ssh ubuntu@${instance} --command="chmod +x /tmp/setup_controller.sh && /tmp/setup_controller.sh"
done

echo "Verification"
cd ../certificate && pwd
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')
curl --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version

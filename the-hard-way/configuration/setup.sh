#!/bin/bash -eu

. ../common.sh

KUBERNETES_PUBLIC_ADDRESS=$(
  gcloud compute addresses describe kubernetes-the-hard-way \
        --region $(gcloud config get-value compute/region) \
        --format 'value(address)'
)

# --kubeconfig: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#config
## --certificate-authority に CA の証明書のパスを指定することで、kubeconfig file に base64エンコードされたデータが入力される
## 上記オプションで生データ kubeconfig に記載しているので、そのことを --embed-certs=true で表現する
## --embed-certs=false だと --certificate-authority に指定したパスの値がそのまま client-certificate-data に記載されてしまう
function set_kubeconfig() {
  # $1: cluster name
  # $2: Root CA Certificate Path
  # $3: Kubernete API Server URL
  # $4: Client Certificaet Path
  # $5: Client Private Key Path
  # $6: User Name
  # $7: kubeconfig file name
  # $8: Context Name
  kubectl config set-cluster ${1} \
    --certificate-authority=${2} \
    --embed-certs=true \
    --server=${3} \
    --kubeconfig=${7}

  kubectl config set-credentials ${6} \
    --client-certificate=${4} \
    --client-key=${5} \
    --embed-certs=true \
    --kubeconfig=${7}

  kubectl config set-context ${8:-default} \
    --cluster=kubernetes-the-hard-way \
    --user=${6} \
    --kubeconfig=${7}

  kubectl config use-context ${8:-default} --kubeconfig=${7}
}

echo "------------------------"
echo "create kubeconfig for kubelet"
echo "------------------------"
for instance in ${workers[@]}; do
  set_kubeconfig \
    "kubernetes-the-hard-way" \
    "../certificate/ca.pem" \
    "https://${KUBERNETES_PUBLIC_ADDRESS}:6443" \
    "../certificate/${instance}.pem" \
    "../certificate/${instance}-key.pem" \
    "${instance}" \
    "${instance}.kubeconfig"
done

echo "------------------------"
echo "create kubeconfig for kube-proxy"
echo "------------------------"
component_name="kube-proxy"
set_kubeconfig \
  "kubernetes-the-hard-way" \
  "../certificate/ca.pem" \
  "https://${KUBERNETES_PUBLIC_ADDRESS}:644" \
  "../certificate/${component_name}.pem" \
  "../certificate/${component_name}-key.pem" \
  "${component_name}" \
  "${component_name}.kubeconfig"

echo "------------------------"
echo "create kubeconfig for controller manager"
echo "------------------------"
# APIサーバを 127.0.0.1 にしているが、外部公開用IPアドレスにしても問題ない
component_name="kube-controller-manager"
set_kubeconfig \
  "kubernetes-the-hard-way" \
  "../certificate/ca.pem" \
  "https://127.0.0.1:6443" \
  "../certificate/${component_name}.pem" \
  "../certificate/${component_name}-key.pem" \
  "${component_name}" \
  "${component_name}.kubeconfig"

echo "------------------------"
echo "create kubeconfig for kube-scheduler"
echo "------------------------"
# APIサーバを 127.0.0.1 にしているが、外部公開用IPアドレスにしても問題ない
component_name="kube-scheduler"
set_kubeconfig \
  "kubernetes-the-hard-way" \
  "../certificate/ca.pem" \
  "https://127.0.0.1:6443" \
  "../certificate/${component_name}.pem" \
  "../certificate/${component_name}-key.pem" \
  "${component_name}" \
  "${component_name}.kubeconfig"

echo "------------------------"
echo "create kubeconfig for Admin User"
echo "------------------------"
# Masterノード上で kubectl を実行することを想定しているため、APIサーバを 127.0.0.1 に指定している
# 作業用PCで使用する場合は、外部公開用IPアドレスを指定する必要があり、この場合の kubeconfig は別途作成する
component_name="admin"
set_kubeconfig \
  "kubernetes-the-hard-way" \
  "../certificate/ca.pem" \
  "https://${KUBERNETES_PUBLIC_ADDRESS}:6443" \
  "../certificate/${component_name}.pem" \
  "../certificate/${component_name}-key.pem" \
  "${component_name}" \
  "${component_name}.kubeconfig"


echo "------------------------"
echo "workerノードに kubelet と kube-proxy の kubeconfig を配布"
echo "------------------------"
for instance in ${workers[@]}; do
  gcloud compute scp ${instance}.kubeconfig kube-proxy.kubeconfig ubuntu@${instance}:~/
done

echo "------------------------"
echo "Masterノードに kube-scheduler と kube-controller-manager と admin の kubeconfig を配布"
echo "------------------------"
for instance in ${controllers[@]}; do
  gcloud compute scp kube-scheduler.kubeconfig kube-controller-manager.kubeconfig admin.kubeconfig ubuntu@${instance}:~/
done


echo "------------------------"
echo "作業用PC用の kubeconfig 設定"
echo "------------------------"

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem

kubectl config set-context kubernetes-the-hard-way \
  --cluster=kubernetes-the-hard-way \
  --user=admin

kubectl config use-context kubernetes-the-hard-way

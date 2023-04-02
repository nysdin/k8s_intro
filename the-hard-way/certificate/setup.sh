set -eu

. ../common.sh

###############################################
#
# 証明書のセットアップスクリプト
#
###############################################

# cfssl コマンドの入力ファイル（CSR・署名設定ファイル） *.json をあらかじめ用意しておくこと。
# the-hard-way/certificate/create-csr.sh を実行すると全てのCSR構築用 json ファイルが作成できるようになってる

echo "cfsslを使って Root CA を建てる"
# official https://kubernetes.io/ja/docs/tasks/administer-cluster/certificates/#cfssl
# qiita https://qiita.com/AkiQ/items/5489033346a12c55ff43
## 以下で雛形を作成できる
### cfssl print-defaults config > ca-config.json
### cfssl print-defaults csr > ca-csr.json
echo "------------------------"
echo "Root CAを構築（後に kubernetes component の証明書を発行する際はこのRootCAから発行する）"
echo "------------------------"

# 前半で秘密鍵とCSRをjsonで標準出力. 後半で出力されたjsonをファイルに出力. ca は ファイル名のprefix

# RootCA として自己署名証明書 ・ CSR ・ 秘密鍵を作成
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
# 鍵の内容を確認
# openssl rsa -text -noout -in ca-key.pem
# CSRの内容を確認
# openssl req -text -noout -in ca.csr
# 証明書の内容を確認
# openssl x509 -text -noout -in ca.pem

echo "------------------------"
echo "各Kubernetes Component 用のサーバー/クライアント証明書と、adminユーザー用のクライアント証明書を作成"
echo "Admin User用の証明書作成"
echo "------------------------"

# ca.pem: さっき作った Root CA の証明書
## 秘密鍵と証明書作成
cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -profile=kubernetes \
      admin-csr.json | cfssljson -bare admin

echo "------------------------"
echo "全てのWorkerノード用にKubeletのクライアント証明書を作成する"
echo "------------------------"
## CN は system:node:<node name> にする必要がある
# kubelet は API サーバでもあるため SAN を指定するために -hostname option を追加している
for instance in ${workers[@]}; do
  EXTERNAL_IP=$(gcloud compute instances describe ${instance} --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
  INTERNAL_IP=$(gcloud compute instances describe ${instance} --format 'value(networkInterfaces[0].networkIP)')

  cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
        -profile=kubernetes \
        ${instance}-csr.json | cfssljson -bare ${instance}
done

echo "------------------------"
echo "Controller manager Client Certificate"
echo "------------------------"
## CN は system:kube-controller-manager にする

cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -profile=kubernetes \
      kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

echo "------------------------"
echo "Kuber Proxy Client Certificate"
echo "------------------------"

cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -profile=kubernetes \
      kube-proxy-csr.json | cfssljson -bare kube-proxy

echo "------------------------"
echo "Scheduler Client Certificate"
echo "------------------------"

cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -profile=kubernetes \
      kube-scheduler-csr.json | cfssljson -bare kube-scheduler

echo "------------------------"
echo "Kubernetes API Servier Certificate"
echo "------------------------"
# API Serverはクラスター内部からはkubernetesというServiceとしてアクセスされるのでCN=kubernetesとする
# 外部からもアクセスできるようにするため、-hostnameオプションでSANに以下を指定する。

# - 10.32.0.1 (apiserverのServiceのIP)
## - kube-apiserver 起動時の --service-cluster-ip-range で 10.32.0.0/24 を指定したのでそのネットワーク内から割り振られるんだと思う
# - 各Master NodeのPrivate IP Address
#   - 10.240.0.10
#   - 10.240.0.11
#   - 10.240.0.12
# - ${KUBERNETES_PUBLIC_ADDRESS} (外部公開用のIP Address)
# - 127.0.0.1
# - kubernetes.default （apiserverのServiceのホスト名）

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')
echo "------------------------"
echo "KUBERNETES_PUBLIC_ADDRESS = ${KUBERNETES_PUBLIC_ADDRESS}"
echo "------------------------"

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

echo "------------------------"
echo "Service Account Key Pair"
echo "------------------------"
## Controller Managerで稼働するToken ControllerがService Account Tokenを生成するための秘密鍵を作成
cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -profile=kubernetes \
      service-account-csr.json | cfssljson -bare service-account

####################################
#
# 上記で作成した証明書・秘密鍵を各サーバに配置
#
####################################


echo "------------------------"
echo "worker ノードに CA の証明書と各ノードの秘密鍵と証明書を転送する"
echo "------------------------"
for instance in ${workers[@]}; do
  gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ubuntu@${instance}:~/
done

echo "------------------------"
echo "Master ノードに CA・API Server・Service Account作成用の秘密鍵と証明書を転送"
echo "------------------------"
for instance in ${controllers[@]}; do
  gcloud compute scp ca.pem ca-key.pem kubernetes.pem kubernetes-key.pem service-account.pem service-account-key.pem ubuntu@${instance}:~/
done

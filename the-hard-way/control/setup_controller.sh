#!/bin/bash -eu

# アプリケーションの中心となるディレクトリ
# また各 control plane コンポーネントのコンフィグファイル(kubeconfig)の格納先
sudo mkdir -p /etc/kubernetes/config

#kubernetes v1.12.0
# https://github.com/kubernetes/kubernetes/releases/tag/v1.12.0

echo "-------------------"
echo "download kubernetes"
echo "-------------------"

KUBERNETES_DOWNLAD_PATH=/tmp/kubernetes
mkdir -p ${KUBERNETES_DOWNLAD_PATH}

if [[ ! -f /usr/local/bin/kube-apiserver ]] && [[ ! -f /usr/local/bin/kube-controller-manager ]] && [[ ! -f /usr/local/bin/kube-scheduler ]]; then
  wget -q --show-progress --https-only --timestamping \
    -P ${KUBERNETES_DOWNLAD_PATH} \
    "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-apiserver" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-controller-manager" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-scheduler" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl"

  chmod +x ${KUBERNETES_DOWNLAD_PATH}/kube-apiserver ${KUBERNETES_DOWNLAD_PATH}/kube-controller-manager ${KUBERNETES_DOWNLAD_PATH}/kube-scheduler ${KUBERNETES_DOWNLAD_PATH}/kubectl

  sudo mv -f ${KUBERNETES_DOWNLAD_PATH}/kube-apiserver ${KUBERNETES_DOWNLAD_PATH}/kube-controller-manager ${KUBERNETES_DOWNLAD_PATH}/kube-scheduler ${KUBERNETES_DOWNLAD_PATH}/kubectl /usr/local/bin/
fi

#######################################
#
# kube-apiserver
#
#######################################
echo "-------------------"
echo "Configure Kubernetes API Server"
echo "-------------------"

sudo mkdir -p /var/lib/kubernetes/

sudo mv -f ~/ca.pem ~/ca-key.pem ~/kubernetes-key.pem ~/kubernetes.pem \
    ~/service-account-key.pem ~/service-account.pem \
    ~/encryption-config.yaml /var/lib/kubernetes/

INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

# kube-apiserver の引数
# https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/
# kubelet はノード認可
# --etcd-*: etcdとの接続に関する設定で使用する証明書などを指定
## --etcd-cafile: Root CA証明書。 etcd 接続時、etcd のクライアント証明書はこのCA証明書から発行されている必要がある
## --etcd-certfile: etcd との接続時のクライアント証明書
# --kubelet-*: kubeletとの接続に関する設定で使用する証明書などを指定（証明書など etcd と同じ）
## --kubelet-certificate-authority: kubelet が使用するクライアント証明書の発行元CA証明書
## -kubelet-client-certificate: kubelet 接続時のクライアント証明書
# --tls-*: 自身がHTTPSサーバーとしてリクエストを受け付けるための設定
## --tls-cert-file: kube-apiserver のサーバ証明書
# --service-cluster-ip-range: Serviceが使用するIPのCIDR
# --client-ca-file: クライアントが API Server にアクセスする時この CA から発行されたクライアント証明書が必要になる
cat <<-EOF | sudo tee /etc/systemd/system/kube-apiserver.service
  [Unit]
  Description=Kubernetes API Server
  Documentation=https://github.com/kubernetes/kubernetes

  [Service]
  ExecStart=/usr/local/bin/kube-apiserver \\
    --advertise-address=${INTERNAL_IP} \\
    --allow-privileged=true \\
    --apiserver-count=3 \\
    --audit-log-maxage=30 \\
    --audit-log-maxbackup=3 \\
    --audit-log-maxsize=100 \\
    --audit-log-path=/var/log/audit.log \\
    --authorization-mode=Node,RBAC \\
    --bind-address=0.0.0.0 \\
    --client-ca-file=/var/lib/kubernetes/ca.pem \\
    --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
    --enable-swagger-ui=true \\
    --etcd-cafile=/var/lib/kubernetes/ca.pem \\
    --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
    --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
    --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
    --event-ttl=1h \\
    --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
    --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
    --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
    --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
    --kubelet-https=true \\
    --runtime-config=api/all \\
    --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
    --service-cluster-ip-range=10.32.0.0/24 \\
    --service-node-port-range=30000-32767 \\
    --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
    --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
    --v=2
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
EOF


#######################################
#
# kube-controller-manager
#
#######################################
echo "-------------------"
echo "Conifugre kube-controller-manager"
echo "-------------------"

sudo mv -f ~/kube-controller-manager.kubeconfig /var/lib/kubernetes/

# https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/
# --cluster-cidr: クラスターのCIDR
# --cluster-signing-cert-file: この証明書は、新しい証明書を生成するために使用される.例えば、新しいユーザーのために証明書を作成する場合、クラスター署名証明書が使用される。この証明書から新しい証明書を発行するので、Root CA証明書を指定する
# --service-account-private-key-file: Service Account Token発行時の鍵
# --service-cluster-ip-range: Service の CIDR
# --root-ca-file: 他サーバーに通信時、サーバ証明書の検証に使う Root CA証明書
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

#######################################
#
# kube-scheduler
#
#######################################
echo "-------------------"
echo "Conifugre kube-scheduler"
echo "-------------------"
sudo mv -f ~/kube-scheduler.kubeconfig /var/lib/kubernetes

cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: componentconfig/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

#######################################
#
# Start service
#
#######################################
sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl restart kube-apiserver kube-controller-manager kube-scheduler

#######################################
#
# Setup Nginx
#
#######################################


sudo apt -y install nginx
cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
    proxy_pass                    https://127.0.0.1:6443/healthz;
    proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

# sites-available と seites-enabled の違い
# https://qiita.com/tomokon/items/e782636c1e5ec6b5dfdc
sudo mv -f kubernetes.default.svc.cluster.local \
    /etc/nginx/sites-available/kubernetes.default.svc.cluster.local
sudo ln -fs /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/

sudo systemctl enable nginx
sudo systemctl restart nginx


#######################################
#
# Setup Nginx
#
#######################################
# kubectl get componentstatuses --kubeconfig admin.kubeconfig
# curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz

#######################################
#
# RBAC for kubelet authorization
#
#######################################

# system:kube-apiserver-to-kubelet という ClusterRole を作成
# apiGroupsの "" は、 core API Group を表す
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF

# kubernetes ユーザーに system:kube-apiserver-to-kubelet ロールを付与
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF

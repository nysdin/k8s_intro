#!/bin/bash -eu

# etcd をインストール
ETCD_DOWNLAD_PATH=/tmp/etcd
mkdir -p ${ETCD_DOWNLAD_PATH}
if [[ ! -f /usr/local/bin/etcd ]]; then
  wget -q --show-progress --https-only --timestamping \
    -O ${ETCD_DOWNLAD_PATH}/etcd-v3.3.9-linux-amd64.tar.gz \
    "https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz"
  # -C: 解凍先ディレクトリを指定
  tar xvf ${ETCD_DOWNLAD_PATH}/etcd-v3.3.9-linux-amd64.tar.gz -C ${ETCD_DOWNLAD_PATH}
  sudo mv -f ${ETCD_DOWNLAD_PATH}/etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/
fi

# Root CA証明書・APIサーバの秘密鍵と証明書を配置
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo cp -f ~/ca.pem ~/kubernetes-key.pem ~/kubernetes.pem /etc/etcd/

# systemd: etcd service の設定ファイル作成
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
ETCD_NAME=$(hostname -s)

# peer 系は 他の etcd サーバーとの通信時に使用する証明書などを指定している
## --certfile: サーバーとしての通信に使用する証明書
## --key-file: サーバーとしての通信に使用する秘密鍵
## --peer-cert-file: etcd間の通信に使うクライアント証明書
## --peer-key-file: etcd間の通信に使う秘密鍵
## --peer-client-cert-auth: etcd間の通信でもクライアント認証する
## --client-cert-auth: サーバーとしての通信でもクライアント認証する
## --trusted-ca-file: Root CA証明書
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-0=https://10.240.0.10:2380,controller-1=https://10.240.0.11:2380,controller-2=https://10.240.0.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl restart etcd

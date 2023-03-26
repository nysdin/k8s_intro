#!/bin/bash -eu

# 各 Master ノード上で実行する

. ../common.sh

# etcd v3.3.9
# https://github.com/etcd-io/etcd/releases/tag/v3.3.9

# supported platform
## https://etcd.io/docs/v3.5/op-guide/supported-platform/
## Linux AMD64以外 tier3 なの気になる・・・

for instance in ${controllers[@]}; do
  gcloud compute scp setup_etcd.sh ubuntu@${instance}:/tmp
  gcloud compute ssh ubuntu@${instance} --command="chmod +x /tmp/setup_etcd.sh && /tmp/setup_etcd.sh"
done

# 各Masterノードで以下のコマンドを実行
# sudo ETCDCTL_API=3 etcdctl member list \
#   --endpoints=https://127.0.0.1:2379 \
#   --cacert=/etc/etcd/ca.pem \
#   --cert=/etc/etcd/kubernetes.pem \
#   --key=/etc/etcd/kubernetes-key.pem

# 以下のような出力結果が出たら正常に etcd が稼働している
## クライアントとの通信に2379番
## etcd間の通信に2380番
# 3a57933972cb5131, started, controller-2, https://10.240.0.12:2380, https://10.240.0.12:2379
# f98dc20bce6225a0, started, controller-0, https://10.240.0.10:2380, https://10.240.0.10:2379
# ffed16798470cab5, started, controller-1, https://10.240.0.11:2380, https://10.240.0.11:2379

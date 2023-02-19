# kops による kubernetes cluster の構築

```shell
← kops version
Client version: 1.25.3
```

## 1. 前提

kops により様々な AWS リソースが作成されるので適当な権限を持った IAM ユーザーを準備
https://kops.sigs.k8s.io/getting_started/aws/#aws

## 2. DNS

gossip-based DNS を使用する際はスキップ
https://kops.sigs.k8s.io/getting_started/aws/#configure-dns

## 3. S3 Bucket 用意

cluster に関する情報の保存場所として S3 Bucket を作成する。（terraform の state ファイルみたいなもの)

また、Service Account が外部のパーミッション（IAM Role など？）を使用するために、OIDC Document 用の S3 Bucket も必要。上記と同じ Bucket でもいいがパブリックにする必要があるので、別途分けたほうがいいらしい。

S3 Bucket を暗号化できれば尚良し

##

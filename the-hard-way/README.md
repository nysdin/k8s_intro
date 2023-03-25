# The Hard Way

## 1. Server/Client Certificate & Private Key の行き先

| certificate/private key         | place                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| admin-key.pem                   | 作業用 PC(kubeconfig) （クライアント証明書）                                                                                                                                                                                                                                                                                                                                                                                                                            |
| admin.pem                       | 作業用 PC(kubeconfig)                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| ca-key.pem                      | controller-${i}:/var/lib/kubernetes/ca-key.pem                                                                                                                                                                                                                                                                                                                                                                                                                          |
| ca.pem                          | controller-${i}:/etc/etcd/ca.pem <br>  controller-${i}:/var/lib/kubernetes/ca.pem <br> worker-${i}:/var/lib/kubernetes/ca.pem <br> worker-${i}:/var/lib/kubelet/kubeconfig <br> worker-${i}:/var/lib/kube-proxy/kubeconfig <br> controller-${i}:/var/lib/kubernetes/kube-controller-manager.kubeconfig <br> controller-${i}:/var/lib/kubernetes/kube-scheduler.kubeconfig <br> 作業用 PC:admin.kubeconfig <br> Root CA の証明書なので全てのホスト（ノード）で必要になる |
| kube-controller-manager-key.pem | controller-${i}:/var/lib/kubernetes/kube-controller-manager.kubeconfig                                                                                                                                                                                                                                                                                                                                                                                                  |
| kube-controller-manager.pem     | controller-${i}:/var/lib/kubernetes/kube-controller-manager.kubeconfig                                                                                                                                                                                                                                                                                                                                                                                                  |
| kube-proxy-key.pem              | worker-${i}:/var/lib/kube-proxy/kubeconfig                                                                                                                                                                                                                                                                                                                                                                                                                              |
| kube-proxy.pem                  | worker-${i}:/var/lib/kube-proxy/kubeconfig                                                                                                                                                                                                                                                                                                                                                                                                                              |
| kube-scheduler-key.pem          | controller-${i}:/var/lib/kubernetes/kube-scheduler.kubeconfig                                                                                                                                                                                                                                                                                                                                                                                                           |
| kube-scheduler.pem              | controller-${i}:/var/lib/kubernetes/kube-scheduler.kubeconfig                                                                                                                                                                                                                                                                                                                                                                                                           |
| kubernetes-key.pem              | controller-${i}:/etc/etcd/kubernetes-key.pem <br> controller-${i}:/var/lib/kubernetes/kubernetes-key.pem                                                                                                                                                                                                                                                                                                                                                                |
| kubernetes.pem                  | controller-${i}:/etc/etcd/kubernetes-key.pem <br> controller-${i}:/var/lib/kubernetes/kubernetes-key.pem                                                                                                                                                                                                                                                                                                                                                                |
| service-account-key.pem         | controller-${i}:/var/lib/kubernetes/service-account-key.pem                                                                                                                                                                                                                                                                                                                                                                                                             |
| service-account.pem             | controller-${i}:/var/lib/kubernetes/service-account-key.pem                                                                                                                                                                                                                                                                                                                                                                                                             |
| worker-${i}-key.pem             | worker-${i}:/var/lib/kubelet/worker${i}-key.pem & worker-${i}:/var/lib/kubelet/kubeconfig                                                                                                                                                                                                                                                                                                                                                                               |
| worker-${i}.pem                 | worker-${i}:/var/lib/kubelet/worker-${i}-key.pem & worker-${i}:/var/lib/kubelet/kubeconfig （クライアント証明書）                                                                                                                                                                                                                                                                                                                                                       |

## 2. Network

| ネットワーク・IP アドレス | 名前         | 説明                                  |
| ------------------------- | ------------ | ------------------------------------- |
| 10.240.0.0/24             |              | VM インスタンスが配置されるサブネット |
| 10.240.0.10               | controller-0 | Master ノード#0 の IP                 |
| 10.240.0.11               | controller-1 | Master ノード#1 の IP                 |
| 10.240.0.12               | controller-2 | Master ノード#2 の IP                 |
| 10.240.0.20               | worker-0     | Worker ノード#0 の IP                 |
| 10.240.0.21               | worker-1     | Worker ノード#1 の IP                 |
| 10.240.0.22               | worker-2     | Worker ノード#2 の IP                 |

# tool

## cfssl

### CSR・秘密鍵作成

- パスフレーズなしの private key
- CSR
  上記２つを json で出力

```shell
cfssl genkey <json>
```

上記コマンドの json 出力を、秘密鍵ファイル・CSR ファイルとして出力

- `<prefix>.csr`
- `<prefix>-key.pem`
  上記２つのファイルが生成される

```shell
cfssl genkey <json> | cfssljson -bare <prefix>
```

### CA の作成

https://github.com/cloudflare/cfssl#generating-self-signed-root-ca-certificate-and-private-key

```shell
cfssl genkey -initca ca-csr.json | cfssljson -bare ca
```

```shell
$ tree
.
├── ca-key.pem (認証局の秘密鍵)
├── ca.csr (証明書発行要求)
└── ca.pem (自己署名証明書：認証局の秘密鍵で対応する公開鍵に署名した証明書)
```

```json:csr.json
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US", // country
      "L": "Portland", // City
      "O": "Kubernetes", // Organaization
      "OU": "CA", // Organaization Unit
      "ST": "Oregon" // State
    }
  ]
}
```

## 証明書作成

`-ca` : 証明書発行要求先となる CA の証明書を指定
`-ca-key` : 証明書発行要求先となる CA の秘密鍵
`csr.json` : 証明書発行要求ファイル

```shell
cfssl gencert -ca=ca.pem -ca-key=ca-kery.pem csr.json
```

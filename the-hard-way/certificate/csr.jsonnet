local base = {
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "JP",
      "L": "Bunkyo",
      "O": "Kubernetes",
      "OU": "",
      "ST": "Tokyo"
    }
  ]
};


{
  "admin-csr.json": {
    "CN": "admin",
  } + base,
  "ca-csr.json": {
    "CN": "Kubernetes"
  } + base,
  "kube-controller-manager-csr.json": {
    "CN": "system:kube-controller-manager"
  } + base,
  "kube-proxy-csr.json": {
    "CN": "system:kube-proxy"
  } + base,
  "kube-scheduler-csr.json": {
    "CN": "system:kube-scheduler"
  } + base,
  "kubernetes-csr.json": {
    "CN": "kubernetes"
  } + base,
  "service-account-csr.json": {
    "CN": "service-accounts"
  } + base,
  "worker-0-csr.json": {
    "CN": "system:node:worker-0"
  } + base,
  "worker-1-csr.json": {
    "CN": "system:node:worker-1"
  } + base,
  "worker-2-csr.json": {
    "CN": "system:node:worker-2"
  } + base
}

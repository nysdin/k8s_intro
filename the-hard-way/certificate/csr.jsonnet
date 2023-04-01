local make_csr(cn, o) = {
  "CN": cn,
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "JP",
      "L": "Bunkyo",
      "O": o,
      "OU": "Kubernetes",
      "ST": "Tokyo"
    }
  ]
};

{
  "ca-csr.json": make_csr(cn = "Kubernetes", o = "Kubernetes"),
  "admin-csr.json": make_csr(cn = "admin", o = "system:masters"),
  "worker-0-csr.json": make_csr(cn = "system:node:worker-0", o = "system:nodes"),
  "worker-1-csr.json": make_csr(cn = "system:node:worker-1", o = "system:nodes"),
  "worker-2-csr.json": make_csr(cn = "system:node:worker-2", o = "system:nodes"),
  "kube-controller-manager-csr.json": make_csr(cn = "system:kube-controller-manager", o = "system:kube-controller-manager"),
  "kube-proxy-csr.json": make_csr(cn = "system:kube-proxy", o = "system:node-proxier"),
  "kube-scheduler-csr.json": make_csr(cn = "system:kube-scheduler", o = "system:kube-scheduler"),
  "kubernetes-csr.json": make_csr(cn = "kubernetes", o = "Kubernetes"),
  "service-account-csr.json": make_csr(cn = "service-accounts", o = "Kubernetes"),
}

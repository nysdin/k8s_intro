#!/bin/bash -eu

kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml

echo "verification"

# kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
# POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
# kubectl exec -ti $POD_NAME -- nslookup kubernetes
# → kubectl exec -ti busybox -- nslookup kubernetes
# Server:    10.32.0.10
# Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

# Name:      kubernetes
# Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local

# container内でネットワークを調べる
# → k exec -it busybox -- /bin/sh
# / # ip r
# default via 10.200.2.1 dev eth0
# 10.200.2.0/24 dev eth0 scope link  src 10.200.2.3

# root@ubuntu:~# cat /etc/resolv.conf
# search default.svc.cluster.local svc.cluster.local cluster.local asia-northeast1-a.c.k8s-the-hard-way-pj.internal c.k8s-the-hard-way-pj.internal google.internal
# nameserver 10.32.0.10

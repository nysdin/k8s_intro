# Compute Instance
## Masterノードをたてる
for i in 0 1; do
  gcloud compute instances create controller-${i} \
        --async \
        --boot-disk-size 20GB \
        --can-ip-forward \ #別のVMから送信されたパケットを他のVMに転送できるようにする
        --image-family ubuntu-1804-lts \
        --image-project ubuntu-os-cloud \
        --machine-type e2-small \ # gcloud compute machine-types list | grep -e 'ec2' -e 'asia-northeast1-a' --- 2vCPU 2GM
        --private-network-ip 10.240.0.1${i} \
        --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \ # IAM Role 的な権限付与
        --subnet kubernetes \
        --tags kubernetes-the-hard-way,controller
done

## Worker Node
## You have selected a disk size of under [200GB]. This may result in poor I/O performance. For more information, see: https://developers.google.com/compute/docs/disks#performance.
for i in 0 1; do
  gcloud compute instances create worker-${i} \
        --async \
        --boot-disk-size 20GB \
        --can-ip-forward \
        --image-family ubuntu-1804-lts \
        --image-project ubuntu-os-cloud \
        --machine-type e2-small \
        --private-network-ip 10.240.0.2${i} \
        --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
        --subnet kubernetes \
        --tags kubernetes-the-hard-way,worker
done

# Instance確認
gcloud compute instances list

# SSH接続
gcloud compute ssh controller-0

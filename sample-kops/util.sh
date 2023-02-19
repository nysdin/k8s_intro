# creates a cloud specification in the registry
## https://kops.sigs.k8s.io/cli/kops_create_cluster/
## ↑を参考にしたが、 --control-plane-size など使えないオプションがあった
## ドキュメントが更新されていない？
# kops create cluster \
#   --name test-cluster.k8s.local \ # KOPS_CLUSTER_NAEM
#   --network-id vpc-0a20a586b7b51ca5a \ # redash-vpc
#   --zones ap-norhteast-1a \
#   --cloud aws \
#   --control-plane-size m5.large \
#   --node-size m5.large \
#   --node-security-groups sg-0091bf9ea0bdd28e5 \ # redash for ecs
#   --subnets subnet-0b90e1edf47908d5f subnet-0d3145dfc50b6899b \	 # redash-public-subnet-1a|c
#   --dry-run


# kops create cluster --help の options を参考
# 既存のリソースを使う
# https://kops.sigs.k8s.io/run_in_existing_vpc/
kops create cluster \
  --name=test-cluster.k8s.local \
  --zones=ap-northeast-1a \
  --cloud aws \
  --master-count 1 \
  --master-security-groups=sg-0091bf9ea0bdd28e5 \
  --master-size m5.large \
  --master-zones=ap-northeast-1a \
  --node-count 3 \
  --node-security-groups=sg-0091bf9ea0bdd28e5 \
  --node-size t2.medium \
  --subnets=subnet-0b90e1edf47908d5f,subnet-0d3145dfc50b6899b \
  --vpc vpc-0a20a586b7b51ca5a \
  --dry-run -o yaml


# Usage:
#   kops create cluster [CLUSTER] [flags]

# Examples:
#   # Create a cluster in AWS in a single zone.
#   kops create cluster --name=k8s-cluster.example.com \
#   --state=s3://my-state-store \
#   --zones=us-east-1a \
#   --node-count=2

#   # Create a cluster in AWS with High Availability masters. This cluster
#   # has also been configured for private networking in a kops-managed VPC.
#   # The bastion flag is set to create an entrypoint for admins to SSH.
#   export KOPS_STATE_STORE="s3://my-state-store"
#   export MASTER_SIZE="c5.large"
#   export NODE_SIZE="m5.large"
#   export ZONES="us-east-1a,us-east-1b,us-east-1c"
#   kops create cluster k8s-cluster.example.com \
#   --node-count 3 \
#   --zones $ZONES \
#   --node-size $NODE_SIZE \
#   --master-size $MASTER_SIZE \
#   --master-zones $ZONES \
#   --networking cilium \
#   --topology private \
#   --bastion="true" \
#   --yes

#   # Create a cluster in Digital Ocean.
#   export KOPS_STATE_STORE="do://my-state-store"
#   export ZONES="NYC1"
#   kops create cluster k8s-cluster.example.com \
#   --cloud digitalocean \
#   --zones $ZONES \
#   --master-zones $ZONES \
#   --node-count 3 \
#   --yes

#   # Generate a cluster spec to apply later.
#   # Run the following, then: kops create -f filename.yaml
#   kops create cluster --name=k8s-cluster.example.com \
#   --state=s3://my-state-store \
#   --zones=us-east-1a \
#   --node-count=2 \
#   --dry-run \
#   -oyaml > filename.yaml

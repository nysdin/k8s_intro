. ../common.sh

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# EncryptionConfig は、最新のk8sだと EncryptionConfiguration という命名になっているかも
## https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

for instance in ${controllers[@]}; do
  gcloud compute scp encryption-config.yaml ubuntu@${instance}:~/
done

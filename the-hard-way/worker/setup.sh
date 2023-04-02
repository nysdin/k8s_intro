#!/bin/bash -eu

. ../common.sh

for instance in ${workers[@]}; do
  gcloud compute scp setup_worker_node.sh ubuntu@${instance}:/tmp/setup_controller.sh
  gcloud compute ssh ubuntu@${instance} --command="chmod +x /tmp/setup_controller.sh && /tmp/setup_controller.sh"
done

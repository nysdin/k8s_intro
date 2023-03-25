workers=(worker-0 worker-1 worker-2)
controllers=(controller-0 controller-1 controller-2)
KUBERNETES_PUBLIC_ADDRESS=$(
  gcloud compute addresses describe kubernetes-the-hard-way \
        --region $(gcloud config get-value compute/region) \
        --format 'value(address)'
)

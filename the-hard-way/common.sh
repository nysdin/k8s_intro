workers=(worker-0 worker-1)
controllers=(controller-0 controller-1)
KUBERNETES_PUBLIC_ADDRESS=$(
  gcloud compute addresses describe kubernetes-the-hard-way \
        --region $(gcloud config get-value compute/region) \
        --format 'value(address)'
)

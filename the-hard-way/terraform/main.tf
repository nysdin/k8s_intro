terraform {
  required_version = ">= 1.3.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.47.0"
    }
  }
}

provider "google" {
  credentials = file("k8s-introduction.json")
  project     = "k8s-the-hard-way-pj"
  region      = "asia-northeast1"
  zone        = "asia-northeast1-a"
}

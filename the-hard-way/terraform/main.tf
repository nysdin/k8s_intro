terraform {
  required_version = ">= 1.3.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.47.0"
    }

    aws = {
      source = "hashicorp/aws"
      version = "~> 4.55.0"
    }
  }
}

provider "google" {
  credentials = file("k8s-introduction.json")
  project     = "k8s-the-hard-way-pj"
  region      = "asia-northeast1"
  zone        = "asia-northeast1-a"
}


provider "aws" {
  region = "ap-northeast-1"
  profile = "nysdin"
  default_tags {
    tags = {
      Terraform = "true"
      Managed_by = "nysdin/k8s_intro"
    }
  }
}

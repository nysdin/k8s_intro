terraform {
  backend "s3" {
    profile = "nysdin"
    bucket  = "nysdin-tf-state"
    key     = "k8s_intro/terraform.tfstate"
    region  = "ap-northeast-1"
  }
}

terraform {
  backend "s3" {
    profile = "nysdin"
    bucket  = "nysdin-tf-state"
    key     = "k8s-the-hard-way-pj/terraform.tfstate"
    region  = "ap-northeast-1"
  }
}

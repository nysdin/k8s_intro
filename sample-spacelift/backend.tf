terraform {
  backend "s3" {
    profile = "nysdin"
    bucket  = "nysdin-tf-state"
    key     = "sample-spacelift/terraform.tfstate"
    region  = "ap-northeast-1"
  }
}

terraform {
  required_version = ">= 1.3.6"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.55.0"
    }
  }
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

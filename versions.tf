
terraform {
  required_version = ">= 0.12"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    aws = {
      version = "~> 3.5.0"
    }
  }
}

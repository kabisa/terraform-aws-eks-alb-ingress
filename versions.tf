
terraform {
  required_version = ">= 0.13.1"

  required_providers {
    kubernetes = {
      version = ">= 1.13"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    aws = {
      version = ">= 3.5.0"
    }
    helm = {
      version = ">= 1.2.4"
    }
  }
}

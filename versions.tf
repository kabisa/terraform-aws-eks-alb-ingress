
terraform {
  required_version = ">= 0.12"

  required_providers {
    kubernetes = {
      version = ">= 1.13"
    }
    aws = {
      version = ">= 3.5.0"
    }
  }
}

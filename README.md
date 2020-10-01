# terraform-aws-eks-alb-ingress

This module requires our [openid connect module](https://github.com/kabisa/terraform-aws-eks-openid-connect)

Example usage:

```hcl-terraform
module "eks_openid_connect" {
  source = "git@github.com:kabisa/terraform-aws-eks-openid-connect.git?ref=1.0"
  # tf 0.13
  # depends_on              = [module.eks]
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  region                  = var.region
}

module "alb" {
  source = "git@github.com:kabisa/terraform-aws-eks-alb-ingress.git?ref=1.0"
  account_id = var.account_id
  eks_cluster_name = var.eks_cluster_name
  oidc_host_path = module.eks_openid_connect.oidc_host_path
  region = var.region
  vpc_id = module.vpc.vpc_id
}

resource "kubernetes_service" "my-service" {
  metadata {
    name = "my-service"
    labels = {
      "app" = "envoy-proxy"
    }
  }
  spec {
    type = "NodePort"
    port {
      port = 80
      name = "http"
      target_port = "http"
    }

    selector = {
      "app" = "my-app"
    }
  }
}

resource "kubernetes_ingress" "my-ingress" {
  metadata {
    name      = "my-ingress"
    annotations = {
      "kubernetes.io/ingress.class"          = "alb"
      "alb.ingress.kubernetes.io/scheme"     = "internet-facing"
      "alb.ingress.kubernetes.io/tags"       = "Environment=testing"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
    }
  }
  spec {
    rule {
      host = "example.com"
      http {
        path {
          path = "/"
          backend {
            service_name = "my-service"
            service_port = "http"
          }
        }
      }
    }
  }
}

```
# Terraform-aws-eks-alb-ingress

This module requires our [openid connect module](https://github.com/kabisa/terraform-aws-eks-openid-connect)

# Upgrading the module from version 2.1 and lower to >= 3.0.3:
Due to changes made in the helm chart you will need to recreate the entire stack. You should expect a downtime of 5 minutes.

Snippet from the [controller repo](https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller#upgrade):
```
The new controller is backwards compatible with the existing ingress objects. However, it will NOT coexist with the older aws-alb-ingress-controller. 

The old controller must be uninstalled completely before installing the new version.
```

## Upgrade steps

You should be logged in to the AWS console and watching the target group(s) of your cluster. 
You should also be prepared to restart the AWS LoadBalancer Controller deployment in your cluster.
Upgrading this module requires planning and applying changes two times. This is included in the steps below.

1. Comment out the current module and and apply the changes. This will cleanly remove the currently installed module.
2. Uncomment the module. Set the module version reference to _at least_ 3.0.3; the previous versions of the 3.0.x series are broken.
3. Run `terraform init` to download the new module.
4. set the variable `var.force_update` to `true` just to be sure.
5. Apply the changes and watch the target group(s) until they get into a draining state.
6. Run `terraform plan` again and apply the lingering changes.
7. In some undetermined cases the AWS LoadBalancer Controller can get stuck. To be sure, restart the deployment of the AWS LoadBalancer Controller.

The nodes should re-register to the Target Group(s) and your application should become available again.

# Example usage:

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 1.2.4 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.7.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 1.13 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.5.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 1.2.4 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 1.7.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 1.13 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.alb-ingress-controller-iam-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.alb-ingress-controller-iam-role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.alb-ingress-controller-iam-role-policy-attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.aws-load-balancer-controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.ingessclassparams](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.targetgroupbindings](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_cluster_role.alb_ingress_controller](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.alb_ingress_controller](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_service_account.alb_ingress_controller](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [aws_iam_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The AWS account ID. | `string` | n/a | yes |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | The name of the EKS cluster. | `string` | n/a | yes |
| <a name="input_force_update"></a> [force\_update](#input\_force\_update) | Force Helm resource update through delete/recreate if needed. | `bool` | `false` | no |
| <a name="input_oidc_host_path"></a> [oidc\_host\_path](#input\_oidc\_host\_path) | The host path of the OIDC provider. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_iam_policy_arn"></a> [aws\_iam\_policy\_arn](#output\_aws\_iam\_policy\_arn) | The IAM policy ARN for the ALB Ingress Controller. |
<!-- END_TF_DOCS -->
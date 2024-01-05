resource "aws_iam_policy" "alb-ingress-controller-iam-policy" {
  name   = "ALBIngressControllerIAMPolicy"
  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role" "alb-ingress-controller-iam-role" {
  name = "ALBIngressControllerIAMRole"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${var.oidc_host_path}:aud" = "sts.amazonaws.com"
            }
          }
          Effect = "Allow",
          Principal = {
            Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc_host_path}"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy_attachment" "alb-ingress-controller-iam-role-policy-attachment" {
  role       = aws_iam_role.alb-ingress-controller-iam-role.name
  policy_arn = aws_iam_policy.alb-ingress-controller-iam-policy.arn
}

resource "kubectl_manifest" "ingessclassparams" {
  yaml_body = file("${path.module}/yamls/ingressclassparams.yaml")

  wait = true
}

resource "kubectl_manifest" "targetgroupbindings" {
  yaml_body = file("${path.module}/yamls/targetgroupbindings.yaml")

  wait = true
}


resource "helm_release" "aws-load-balancer-controller" {
  depends_on = [kubectl_manifest.ingessclassparams, kubectl_manifest.targetgroupbindings]
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.2"
  #This defaults to false, recreation is required when upgrading the module from version 2.1 and lower
  force_update = var.force_update

  values = [
    templatefile(
      "${path.module}/yamls/loadbalancer-values.yaml",
      {
        cluster_name         = var.eks_cluster_name
        vpc_id               = var.vpc_id
        region               = var.region
        service_account_name = kubernetes_service_account.alb_ingress_controller.metadata[0].name
      }
    )
  ]
}

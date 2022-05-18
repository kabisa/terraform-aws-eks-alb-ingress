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

resource "kubectl_manifest" "crds" {
  yaml_body = file("${path.module}/yamls/crds.yaml")
}

# V 2.4.1
# https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/
# helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=<cluster-name>
resource "helm_release" "aws-load-balancer-controller" {
  depends_on = [kubectl_manifest.crds]
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.4.1" # appVersion: v2.4.1

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

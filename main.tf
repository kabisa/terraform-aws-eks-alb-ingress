data "aws_iam_policy_document" "policy" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:RevokeSecurityGroupIngress",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebAcl",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:GetServerCertificate",
      "iam:ListServerCertificates",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["cognito-idp:DescribeUserPoolClient"]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "waf-regional:GetWebACLForResource",
      "waf-regional:GetWebACL",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "tag:GetResources",
      "tag:TagResources",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["waf:GetWebACL"]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "shield:DescribeProtection",
      "shield:GetSubscriptionState",
      "shield:DeleteProtection",
      "shield:CreateProtection",
      "shield:DescribeSubscription",
      "shield:ListProtections",
    ]
  }
}

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

resource "kubectl_manifest" "alb-cluster-role" {
  lifecycle {
    ignore_changes = [uid]
  }
  yaml_body = templatefile("${path.module}/yamls/alb-rbac-role.yaml", {
    account_id   = var.account_id,
    alb_iam_role = aws_iam_role.alb-ingress-controller-iam-role.name,
  })
}

# crafted after: https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.8/docs/examples/alb-ingress-controller.yaml
# from docs: https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
# usually I prefer them as yamls because you can check the diff for new changes
# this one should be small enough and stable enough
resource "kubernetes_deployment" "alb-ingress-controller-deployment" {
  depends_on = [kubectl_manifest.alb-cluster-role]
  metadata {
    name      = "alb-ingress-controller"
    namespace = "kube-system"
  }
  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "alb-ingress-controller"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "alb-ingress-controller"
        }
      }
      spec {
        container {
          name = "alb-ingress-controller"
          args = [
            "--ingress-class=alb",
            "--cluster-name=${var.eks_cluster_name}",
            "--aws-vpc-id=${var.vpc_id}",
            "--aws-region=${var.region}",
            # Enables logging on all outbound requests sent to the AWS API.
            "--aws-api-debug"
          ]
          image = "docker.io/amazon/aws-alb-ingress-controller:v1.1.8"
        }
        service_account_name            = "alb-ingress-controller"
        automount_service_account_token = true
      }
    }
  }
}
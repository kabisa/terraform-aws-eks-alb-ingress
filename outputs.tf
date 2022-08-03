output "aws_iam_policy_arn" {
  value       = aws_iam_policy.alb-ingress-controller-iam-policy.arn
  description = "The IAM policy ARN for the ALB Ingress Controller."
}
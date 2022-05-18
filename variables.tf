variable "eks_cluster_name" {
  type = string
  description = "The name of the EKS cluster."
}

variable "region" {
  type = string
  description = "The AWS region."
}

variable "oidc_host_path" {
  type = string
  description = "The host path of the OIDC provider."
}

variable "vpc_id" {
  type = string
  description = "The VPC ID."
}

variable "account_id" {
  type = string
  description = "The AWS account ID."
}

variable "force_update" {
  type = bool
  default = false
  description = "Force resource update through delete/recreate if needed."
}
variable "env" {
  type = string
}

variable "service_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

# クラスタ管理者（AmazonEKSClusterAdminPolicy）にする IAM プリンシパルの ARN
variable "cluster_admin_principal_arn" {
  type = string
}

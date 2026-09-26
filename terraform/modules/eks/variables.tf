variable "env" {
  type = string
}

variable "service_name" {
  type = string
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

# クラスタ管理者（AmazonEKSClusterAdminPolicy）にする IAM プリンシパルの ARN
variable "cluster_admin_principal_arns" {
  type    = list(string)
  default = []
}

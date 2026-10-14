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

# Argo CD の UI へのログインに使う Identity Center のインスタンス ARN とリージョン
variable "argocd_idc_instance_arn" {
  type = string
}

variable "argocd_idc_region" {
  type = string
}

# Argo CD の ADMIN にする Identity Center のグループ ID
variable "argocd_admin_group_id" {
  type = string
}

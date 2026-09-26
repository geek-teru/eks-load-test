variable "env" {
  type    = string
  default = "dev"
}

variable "service_name" {
  type    = string
  default = "eks-load-test"
}

# CloudShell から kubectl を使う IAM プリンシパル（コンソールにログインしている本人）
variable "cluster_admin_principal_arns" {
  type    = list(string)
  default = []
}

data "aws_caller_identity" "current" {}

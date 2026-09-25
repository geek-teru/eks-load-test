variable "env" {
  type    = string
  default = "dev"
}

variable "service_name" {
  type    = string
  default = "eks-load-test"
}

data "aws_caller_identity" "current" {}

# 共通 VPC（terraform-aws-cmn-vpc）のサービス名。Name タグの参照に使う
variable "cmn_service_name" {
  type    = string
  default = "cmn"
}

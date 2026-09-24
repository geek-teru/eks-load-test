variable "env" {
  type    = string
  default = "prd"
}

variable "service_name" {
  type    = string
  default = "eks-load-test"
}

data "aws_caller_identity" "current" {}

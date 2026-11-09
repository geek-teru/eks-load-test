variable "env" {
  type    = string
  default = "dev"
}

variable "service_name" {
  type    = string
  default = "eks-load-test"
}

data "aws_caller_identity" "current" {}

# vpc
variable "cmn_vpc_config" {
  type = map(any)
  default = {
    cidr       = "10.20.0.0/16",
    managed_by = "terraform"
  }
}

# public subnet
variable "pub_subnet_config" {
  type = map(any)
  default = {
    az-a = { az = "ap-northeast-1a", cidr = "10.20.10.0/24" }
    az-c = { az = "ap-northeast-1c", cidr = "10.20.11.0/24" }
  }
}

# private subnet
variable "priv_subnet_config" {
  type = map(any)
  default = {
    az-a = { az = "ap-northeast-1a", cidr = "10.20.20.0/24" }
    az-c = { az = "ap-northeast-1c", cidr = "10.20.21.0/24" }
  }
}

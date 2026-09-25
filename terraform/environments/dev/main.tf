# ----------------------------------------
# Data Sources
# ----------------------------------------
# 共通 VPC（terraform-aws-cmn-vpc）を Name タグで参照する
data "aws_vpc" "cmn" {
  filter {
    name   = "tag:Name"
    values = ["${var.env}-${var.cmn_service_name}-vpc"]
  }
}

data "aws_subnets" "cmn_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.cmn.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.env}-${var.cmn_service_name}-private-*"]
  }
}

# ----------------------------------------
# Modules
# ----------------------------------------
module "eks" {
  source = "../../modules/eks"

  env          = var.env
  service_name = var.service_name
  vpc_id       = data.aws_vpc.cmn.id
  subnet_ids   = data.aws_subnets.cmn_private.ids
}

# ----------------------------------------
# Outputs
# ----------------------------------------
output "cmn_vpc_id" {
  value = data.aws_vpc.cmn.id
}

output "cmn_private_subnet_ids" {
  value = data.aws_subnets.cmn_private.ids
}

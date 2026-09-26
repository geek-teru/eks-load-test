# ----------------------------------------
# Data Sources
# ----------------------------------------
# 共通 VPC（terraform-aws-cmn-vpc）の state から VPC とサブネットを参照する
data "terraform_remote_state" "cmn_vpc" {
  backend = "s3"

  config = {
    bucket = "dev-terraform-aws"
    key    = "cmn-vpc/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

locals {
  cmn_vpc_id             = data.terraform_remote_state.cmn_vpc.outputs.vpc.cmn_vpc.id
  cmn_private_subnet_ids = data.terraform_remote_state.cmn_vpc.outputs.vpc.cmn_vpc_priv_subnet_ids
}

# ----------------------------------------
# Modules
# ----------------------------------------
module "eks" {
  source = "../../modules/eks"

  env          = var.env
  service_name = var.service_name
  vpc_id       = local.cmn_vpc_id
  subnet_ids   = local.cmn_private_subnet_ids

  cluster_admin_principal_arns = var.cluster_admin_principal_arns
}

# ----------------------------------------
# Outputs
# ----------------------------------------
output "cmn_vpc_id" {
  value = local.cmn_vpc_id
}

output "cmn_private_subnet_ids" {
  value = local.cmn_private_subnet_ids
}

output "eks_cluster_name" {
  value = module.eks.eks_cluster_name
}

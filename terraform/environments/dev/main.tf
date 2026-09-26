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

# クラスタ管理者にする IAM ユーザーの ARN（プレーンテキスト）
data "aws_secretsmanager_secret_version" "cluster_admin_principal_arns" {
  secret_id = "arn:aws:secretsmanager:ap-northeast-1:${local.account_id}:secret:cluster_admin_principal_arns-qOXGr6"
}

locals {
  account_id = data.aws_caller_identity.current.account_id

  cmn_vpc_id             = data.terraform_remote_state.cmn_vpc.outputs.vpc.cmn_vpc.id
  cmn_private_subnet_ids = data.terraform_remote_state.cmn_vpc.outputs.vpc.cmn_vpc_priv_subnet_ids

  # ARN は秘密情報ではないため sensitive を外す（for_each に sensitive な値は渡せない）
  cluster_admin_principal_arns = [trimspace(nonsensitive(data.aws_secretsmanager_secret_version.cluster_admin_principal_arns.secret_string))]
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

  cluster_admin_principal_arns = local.cluster_admin_principal_arns
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

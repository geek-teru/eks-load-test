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

# Identity Center（terraform-aws-cmn-sso で管理）のインスタンスと Argo CD の管理者グループ
data "aws_ssoadmin_instances" "identity_center" {}

data "aws_identitystore_group" "argocd_admins" {
  identity_store_id = local.idc_identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "argocd-admins"
    }
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id

  cmn_vpc_id             = data.terraform_remote_state.cmn_vpc.outputs.vpc.cmn_vpc.id
  cmn_private_subnet_ids = data.terraform_remote_state.cmn_vpc.outputs.vpc.cmn_vpc_priv_subnet_ids

  cluster_admin_principal_arn = trimspace(data.aws_secretsmanager_secret_version.cluster_admin_principal_arns.secret_string)

  idc_instance_arn      = tolist(data.aws_ssoadmin_instances.identity_center.arns)[0]
  idc_identity_store_id = tolist(data.aws_ssoadmin_instances.identity_center.identity_store_ids)[0]
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

  cluster_admin_principal_arn = local.cluster_admin_principal_arn

  argocd_idc_instance_arn = local.idc_instance_arn
  argocd_idc_region       = "ap-northeast-1"
  argocd_admin_group_id   = data.aws_identitystore_group.argocd_admins.group_id
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

output "argocd_server_url" {
  value = module.eks.argocd_server_url
}

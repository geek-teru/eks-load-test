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

  cluster_admin_principal_arn = trimspace(data.aws_secretsmanager_secret_version.cluster_admin_principal_arns.secret_string)

  idc_instance_arn      = tolist(data.aws_ssoadmin_instances.identity_center.arns)[0]
  idc_identity_store_id = tolist(data.aws_ssoadmin_instances.identity_center.identity_store_ids)[0]
}

# ----------------------------------------
# Modules
# ----------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  env            = var.env
  service_name   = var.service_name
  aws_account_id = local.account_id

  vpc_config         = var.cmn_vpc_config
  pub_subnet_config  = var.pub_subnet_config
  priv_subnet_config = var.priv_subnet_config
}

module "eks_cluster" {
  source = "../../modules/eks-cluster"

  env          = var.env
  service_name = var.service_name
  subnet_ids   = module.vpc.priv_subnet_ids

  cluster_admin_principal_arn = local.cluster_admin_principal_arn
}

module "eks_fargate" {
  source = "../../modules/eks-fargate"

  env          = var.env
  service_name = var.service_name
  cluster_name = module.eks_cluster.eks_cluster_name
  subnet_ids   = module.vpc.priv_subnet_ids
  namespaces   = ["kube-system", "default"]
}

module "eks_argocd" {
  source = "../../modules/eks-argocd"

  env          = var.env
  service_name = var.service_name
  cluster_name = module.eks_cluster.eks_cluster_name

  idc_instance_arn = local.idc_instance_arn
  idc_region       = "ap-northeast-1"
  admin_group_id   = data.aws_identitystore_group.argocd_admins.group_id
}

# ----------------------------------------
# Outputs
# ----------------------------------------

output "eks_cluster_name" {
  value = module.eks_cluster.eks_cluster_name
}

output "argocd_server_url" {
  value = module.eks_argocd.argocd_server_url
}

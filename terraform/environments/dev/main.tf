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
module "eks_cluster" {
  source = "../../modules/eks-cluster"

  env          = var.env
  service_name = var.service_name
  subnet_ids   = local.cmn_private_subnet_ids

  cluster_admin_principal_arn = local.cluster_admin_principal_arn
}

module "eks_fargate" {
  source = "../../modules/eks-fargate"

  env          = var.env
  service_name = var.service_name
  cluster_name = module.eks_cluster.eks_cluster_name
  subnet_ids   = local.cmn_private_subnet_ids
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
output "cmn_vpc_id" {
  value = local.cmn_vpc_id
}

output "cmn_private_subnet_ids" {
  value = local.cmn_private_subnet_ids
}

output "eks_cluster_name" {
  value = module.eks_cluster.eks_cluster_name
}

output "argocd_server_url" {
  value = module.eks_argocd.argocd_server_url
}

# ----------------------------------------
# Moved
# ----------------------------------------
# module "eks" を eks_cluster / eks_fargate / eks_argocd に分けたため、state のアドレスを付け替える
moved {
  from = module.eks.aws_iam_role.eks_cluster
  to   = module.eks_cluster.aws_iam_role.eks_cluster
}

moved {
  from = module.eks.aws_iam_role_policy_attachment.eks_cluster
  to   = module.eks_cluster.aws_iam_role_policy_attachment.eks_cluster
}

moved {
  from = module.eks.aws_eks_cluster.eks_cluster
  to   = module.eks_cluster.aws_eks_cluster.eks_cluster
}

moved {
  from = module.eks.aws_vpc_security_group_ingress_rule.cluster_https
  to   = module.eks_cluster.aws_vpc_security_group_ingress_rule.cluster_https
}

moved {
  from = module.eks.aws_eks_access_entry.cluster_admin
  to   = module.eks_cluster.aws_eks_access_entry.cluster_admin
}

moved {
  from = module.eks.aws_eks_access_policy_association.cluster_admin
  to   = module.eks_cluster.aws_eks_access_policy_association.cluster_admin
}

moved {
  from = module.eks.aws_eks_addon.vpc_cni
  to   = module.eks_cluster.aws_eks_addon.vpc_cni
}

moved {
  from = module.eks.aws_eks_addon.kube_proxy
  to   = module.eks_cluster.aws_eks_addon.kube_proxy
}

moved {
  from = module.eks.aws_iam_role.eks_fargate_pod
  to   = module.eks_fargate.aws_iam_role.eks_fargate_pod
}

moved {
  from = module.eks.aws_iam_role_policy_attachment.eks_fargate_pod
  to   = module.eks_fargate.aws_iam_role_policy_attachment.eks_fargate_pod
}

moved {
  from = module.eks.aws_eks_fargate_profile.eks_fargate
  to   = module.eks_fargate.aws_eks_fargate_profile.eks_fargate
}

moved {
  from = module.eks.aws_eks_addon.coredns
  to   = module.eks_fargate.aws_eks_addon.coredns
}

moved {
  from = module.eks.aws_iam_role.eks_argocd
  to   = module.eks_argocd.aws_iam_role.eks_argocd
}

moved {
  from = module.eks.aws_eks_capability.argocd
  to   = module.eks_argocd.aws_eks_capability.argocd
}

moved {
  from = module.eks.aws_eks_access_policy_association.argocd
  to   = module.eks_argocd.aws_eks_access_policy_association.argocd
}

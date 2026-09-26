# vpc_id を渡した環境（dev）だけクラスタを作る
locals {
  create_cluster = var.vpc_id != null
}

# ----------------------------------------
# EKS Cluster
# ----------------------------------------
resource "aws_eks_cluster" "eks_cluster" {
  count = local.create_cluster ? 1 : 0

  name     = "${var.env}-${var.service_name}"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  access_config {
    authentication_mode = "API"
    # 作成者（GitHub Actions のロール）にもクラスタ管理者を付ける
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

# ----------------------------------------
# Access Entries
# ----------------------------------------
# CloudShell から kubectl を使う IAM プリンシパルをクラスタ管理者にする
resource "aws_eks_access_entry" "cluster_admin" {
  for_each = local.create_cluster ? toset(var.cluster_admin_principal_arns) : toset([])

  cluster_name  = aws_eks_cluster.eks_cluster[0].name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  for_each = aws_eks_access_entry.cluster_admin

  cluster_name  = each.value.cluster_name
  principal_arn = each.value.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# ----------------------------------------
# CloudShell Security Group
# ----------------------------------------
# CloudShell（VPC 環境）に付ける SG。プライベートエンドポイントへはこの SG から届ける
resource "aws_security_group" "cloudshell" {
  count = local.create_cluster ? 1 : 0

  name        = "${var.env}-${var.service_name}-cloudshell"
  description = "CloudShell VPC environment for ${var.env}-${var.service_name}"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env}-${var.service_name}-cloudshell"
  }
}

resource "aws_vpc_security_group_egress_rule" "cloudshell_all" {
  count = local.create_cluster ? 1 : 0

  security_group_id = aws_security_group.cloudshell[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# クラスタ SG への 443 を CloudShell の SG から許可する
resource "aws_vpc_security_group_ingress_rule" "cluster_from_cloudshell" {
  count = local.create_cluster ? 1 : 0

  security_group_id            = aws_eks_cluster.eks_cluster[0].vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.cloudshell[0].id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "kubectl from CloudShell"
}

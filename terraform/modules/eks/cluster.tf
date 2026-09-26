# ----------------------------------------
# EKS Cluster
# ----------------------------------------
resource "aws_eks_cluster" "eks_cluster" {
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
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = var.cluster_admin_principal_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  cluster_name  = aws_eks_access_entry.cluster_admin.cluster_name
  principal_arn = aws_eks_access_entry.cluster_admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# ----------------------------------------
# Cluster Security Group Rules
# ----------------------------------------
# エンドポイントはプライベートのみ（パブリック IP を持たない）ため、届くのは VPC 内からだけ
resource "aws_vpc_security_group_ingress_rule" "cluster_https" {
  security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "kubectl to private endpoint"
}

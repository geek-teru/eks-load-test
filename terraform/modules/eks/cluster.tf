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
  for_each = toset(var.cluster_admin_principal_arns)

  cluster_name  = aws_eks_cluster.eks_cluster.name
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

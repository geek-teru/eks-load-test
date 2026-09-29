# ----------------------------------------
# EKS Add-ons
# ----------------------------------------
# クラスタ作成時に入るセルフマネージドのものをマネージドアドオンで置き換えるため、
# 作成時の競合は OVERWRITE にする
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
}

# CoreDNS は既定で EC2 ノード向けのため、computeType = Fargate で Fargate に載せる
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"

  configuration_values = jsonencode({
    computeType = "Fargate"
  })

  # Fargate プロファイルが無いと Pod が Pending のままでアドオンが ACTIVE にならない
  depends_on = [aws_eks_fargate_profile.eks_fargate]
}

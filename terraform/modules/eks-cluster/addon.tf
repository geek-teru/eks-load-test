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

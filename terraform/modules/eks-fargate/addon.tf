# ----------------------------------------
# EKS Add-ons
# ----------------------------------------
# CoreDNS は既定で EC2 ノード向けのため、computeType = Fargate で Fargate に載せる。
# 作成時に入るセルフマネージドのものを置き換えるため、競合は OVERWRITE にする
resource "aws_eks_addon" "coredns" {
  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"

  configuration_values = jsonencode({
    computeType = "Fargate"
  })

  # Fargate プロファイルが無いと Pod が Pending のままでアドオンが ACTIVE にならない
  depends_on = [aws_eks_fargate_profile.eks_fargate]
}

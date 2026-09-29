# ----------------------------------------
# Fargate Profile
# ----------------------------------------
# ワーカーノードは置かず、kube-system（CoreDNS）と default の Pod を Fargate で動かす
resource "aws_eks_fargate_profile" "eks_fargate" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "${var.env}-${var.service_name}"
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod.arn
  # Fargate の Pod はプライベートサブネットでしか動かない
  subnet_ids = var.subnet_ids

  selector {
    namespace = "kube-system"
  }

  selector {
    namespace = "default"
  }

  depends_on = [aws_iam_role_policy_attachment.eks_fargate_pod]
}

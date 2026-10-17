# ----------------------------------------
# Fargate Profile
# ----------------------------------------
# ワーカーノードは置かず、指定した namespace の Pod を Fargate で動かす
resource "aws_eks_fargate_profile" "eks_fargate" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = "${var.env}-${var.service_name}"
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod.arn
  # Fargate の Pod はプライベートサブネットでしか動かない
  subnet_ids = var.subnet_ids

  dynamic "selector" {
    for_each = var.namespaces

    content {
      namespace = selector.value
    }
  }

  depends_on = [aws_iam_role_policy_attachment.eks_fargate_pod]
}

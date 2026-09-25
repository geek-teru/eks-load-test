output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "eks_fargate_pod_role_arn" {
  value = aws_iam_role.eks_fargate_pod.arn
}

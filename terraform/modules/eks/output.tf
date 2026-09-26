output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "eks_fargate_pod_role_arn" {
  value = aws_iam_role.eks_fargate_pod.arn
}

output "eks_cluster_name" {
  value = one(aws_eks_cluster.eks_cluster[*].name)
}

output "eks_cluster_endpoint" {
  value = one(aws_eks_cluster.eks_cluster[*].endpoint)
}

output "eks_cluster_security_group_id" {
  value = one(aws_eks_cluster.eks_cluster[*].vpc_config[0].cluster_security_group_id)
}

output "cloudshell_security_group_id" {
  value = one(aws_security_group.cloudshell[*].id)
}

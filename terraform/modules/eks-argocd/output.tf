output "argocd_role_arn" {
  value = aws_iam_role.eks_argocd.arn
}

output "argocd_server_url" {
  value = aws_eks_capability.argocd.configuration[0].argo_cd[0].server_url
}

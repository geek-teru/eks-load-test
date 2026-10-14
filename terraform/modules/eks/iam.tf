# ----------------------------------------
# EKS Cluster Role
# ----------------------------------------
resource "aws_iam_role" "eks_cluster" {
  name = "${var.env}-${var.service_name}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
        Action    = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ----------------------------------------
# Fargate Pod Execution Role
# ----------------------------------------
resource "aws_iam_role" "eks_fargate_pod" {
  name = "${var.env}-${var.service_name}-eks-fargate-pod"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "eks-fargate-pods.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_fargate_pod" {
  role       = aws_iam_role.eks_fargate_pod.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# ----------------------------------------
# EKS Capability Role (Argo CD)
# ----------------------------------------
# 同期元は公開の GitHub リポジトリで AWS の権限は要らないため、権限ポリシーは付けない
resource "aws_iam_role" "eks_argocd" {
  name = "${var.env}-${var.service_name}-eks-argocd"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "capabilities.eks.amazonaws.com" }
        Action    = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })
}

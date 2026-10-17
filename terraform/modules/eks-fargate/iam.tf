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

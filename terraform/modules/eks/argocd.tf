# ----------------------------------------
# EKS Capability (Argo CD)
# ----------------------------------------
# マネージドの Argo CD。UI へのログインは Identity Center で行う
resource "aws_eks_capability" "argocd" {
  cluster_name              = aws_eks_cluster.eks_cluster.name
  capability_name           = "${var.env}-${var.service_name}-argocd"
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.eks_argocd.arn
  delete_propagation_policy = "RETAIN"

  configuration {
    argo_cd {
      namespace = "argocd"

      aws_idc {
        idc_instance_arn = var.argocd_idc_instance_arn
        idc_region       = var.argocd_idc_region
      }

      rbac_role_mapping {
        role = "ADMIN"

        identity {
          id   = var.argocd_admin_group_id
          type = "SSO_GROUP"
        }
      }
    }
  }
}

# ----------------------------------------
# Access Policy Association
# ----------------------------------------
# capability のロールのアクセスエントリは capability の作成時に自動で作られるため、
# エントリは作らずポリシーだけを紐づけ、同じクラスタへデプロイできるようにする
resource "aws_eks_access_policy_association" "argocd" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_iam_role.eks_argocd.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_capability.argocd]
}

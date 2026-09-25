# ----------------------------------------
# Modules
# ----------------------------------------
module "eks" {
  source = "../../modules/eks"

  env          = var.env
  service_name = var.service_name
}

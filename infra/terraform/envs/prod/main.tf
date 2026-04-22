locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"
  app_secret_name = "${var.project_name}/${var.environment}/data-pipeline/app"
}

module "network" {
  source = "../../modules/network"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = local.cluster_name
  vpc_id       = module.network.vpc_id
  subnet_ids   = module.network.private_subnet_ids
}

module "app_secret" {
  source = "../../modules/secrets-manager"

  project_name = var.project_name
  environment  = var.environment
  secret_name  = local.app_secret_name
  secret_value = var.eks_deployment_secret_value
}

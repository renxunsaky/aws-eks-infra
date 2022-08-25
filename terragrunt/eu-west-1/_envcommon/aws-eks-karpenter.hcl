terraform {
  source = "../../../../../terraform//aws-eks-karpenter"
}

generate "helm_provider" {
  path      = "helm_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "helm" {
      kubernetes {
        config_path = "~/.kube/config"
      }
    }
    EOF
}

locals {
  region = yamldecode(file(find_in_parent_folders("region.yaml")))
  env    = yamldecode(file(find_in_parent_folders("env.yaml")))
  tenant = yamldecode(file(find_in_parent_folders("tenant.yaml")))
  stack  = "eks-karpenter"
  name   = "${local.env.project}-${local.env.env}-${local.stack}"
}

inputs = {
  terraform_state_bucket = local.env.terraform_state_bucket
  region                 = local.region.region
  project                = local.env.project
  env                    = local.env.env
  dns_domain_suffix      = local.env.dns_domain_suffix
  stack                  = local.stack
  tenant                 = local.tenant.tenant
  vpc_id                 = local.env.vpc_id
  role_name              = local.name
  tags                   = merge(
  local.env.tags,
  {
    Name  = local.name
    Stack = local.stack
  }
  )
}
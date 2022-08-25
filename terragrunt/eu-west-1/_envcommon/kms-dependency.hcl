terraform {
  source = "../../../../../terraform//kms-dependency"
}

locals {
  region = yamldecode(file(find_in_parent_folders("region.yaml")))
  env    = yamldecode(file(find_in_parent_folders("env.yaml")))
  tenant = yamldecode(file(find_in_parent_folders("tenant.yaml")))
  stack  = "kms-dependency"
  name   = "${local.env.project}-${local.env.env}-${local.stack}"
}

inputs = {
  terraform_state_bucket = local.env.terraform_state_bucket
  region                 = local.region.region
  project                = local.env.project
  env                    = local.env.env
  stack                  = local.stack
  tenant                 = local.tenant.tenant
  vpc_id                 = local.env.vpc_id
  tags                   = merge(
    local.env.tags,
    {
      Name  = local.name
      Stack = local.stack
    }
  )
}
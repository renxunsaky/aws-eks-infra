terraform {
  source = "${local.base_source_url}?ref=v2.2.4-alpha"
}

dependency "eks" {
  config_path = "../eks"
}

locals {
  base_source_url = "git::https://github.com/streamnative/terraform-aws-cloud.git//modules/eks-vpc-tags/"
  region          = yamldecode(file(find_in_parent_folders("region.yaml")))
  env             = yamldecode(file(find_in_parent_folders("env.yaml")))
  tenant          = yamldecode(file(find_in_parent_folders("tenant.yaml")))
  stack           = "eks-vpc-tags"
  name            = "${local.env.project}-${local.env.env}-${local.stack}"
}

inputs = {
  terraform_state_bucket = local.env.terraform_state_bucket
  region                 = local.region.region
  project                = local.env.project
  env                    = local.env.env
  stack                  = local.stack
  tenant                 = local.tenant.tenant

  tags = merge(
  local.env.tags,
  {
    Name  = "${local.name}"
    Stack = local.stack
  }
  )

  cluster_name       = dependency.eks.outputs.cluster_id
  private_subnet_ids = local.env.private_subnet_ids
  vpc_id             = local.env.vpc_id
}

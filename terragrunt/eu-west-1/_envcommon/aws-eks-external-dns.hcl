terraform {
  source = "${local.base_source_url}//?ref=v1.0.0"
}

dependency "eks" {
  config_path = "../eks"
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
  base_source_url    = "git::https://github.com/lablabs/terraform-aws-eks-external-dns.git"
  region             = yamldecode(file(find_in_parent_folders("region.yaml")))
  env                = yamldecode(file(find_in_parent_folders("env.yaml")))
  tenant             = yamldecode(file(find_in_parent_folders("tenant.yaml")))
  stack              = "aws-eks-load-balancer-controller"
  name               = "${local.env.project}-${local.env.env}-${local.stack}"
  helm_chart_version = "6.5.6"
  tags               = merge(
  local.env.tags,
  {
    Name  = "${local.name}"
    Stack = local.stack
  }
  )
}

inputs = {
  terraform_state_bucket = local.env.terraform_state_bucket
  region                 = local.region.region
  project                = local.env.project
  env                    = local.env.env
  stack                  = local.stack
  tenant                 = local.tenant.tenant

  cluster_identity_oidc_issuer     = dependency.eks.outputs.oidc_provider
  cluster_identity_oidc_issuer_arn = dependency.eks.outputs.oidc_provider_arn
  namespace                        = "external-dns"
  helm_description                 = "Terraform deployed helm release for AWS EKS external dns"
  irsa_role_name_prefix            = "${local.env.project}-${local.env.env}-eks-aws"
  irsa_tags                        = local.tags
  tags                             = local.tags
  values                           = yamlencode({
    "nodeSelector" : { "eks.amazonaws.com/nodegroup" : "${local.env.project}-${local.env.env}-eks-core" }
  })
}

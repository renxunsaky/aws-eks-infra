terraform {
  source = "${local.base_source_url}//?ref=v0.3.0"
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
  base_source_url      = "git::https://github.com/lablabs/terraform-helm-argocd.git"
  region               = yamldecode(file(find_in_parent_folders("region.yaml")))
  env                  = yamldecode(file(find_in_parent_folders("env.yaml")))
  tenant               = yamldecode(file(find_in_parent_folders("tenant.yaml")))
  stack                = "aws-eks-argocd"
  name                 = "${local.env.project}-${local.env.env}-${local.stack}"
  core_node_group_name = "${local.env.project}-${local.env.env}-eks-core"

  tags = merge(
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
  helm_chart_version     = "4.9.7"
  self_managed_use_helm  = true
  k8s_namespace          = "argocd"
  values                 = yamlencode({
    "redis-ha": {
      "enabled": true
    }

    "redis": {
      "nodeSelector": {
        "eks.amazonaws.com/nodegroup": local.core_node_group_name
      }
    }

    "controller": {
      "enableStatefulSet": true,
      "nodeSelector": {
        "eks.amazonaws.com/nodegroup": local.core_node_group_name
      }
    }

    "server": {
      "replicas": 2,
      "nodeSelector": {
        "eks.amazonaws.com/nodegroup": local.core_node_group_name
      },
      "ingress": {
        "enabled": "true",
        "annotations": {
          "alb.ingress.kubernetes.io/target-type": "ip",
          "alb.ingress.kubernetes.io/ssl-redirect": "443",
          "alb.ingress.kubernetes.io/group.name": "${local.env.project}-${local.env.env}-eks-${local.tenant.tenant}",
          "alb.ingress.kubernetes.io/listen-ports": "[{'HTTPS': 443}]",
          "kubernetes.io/ingress.class": "alb",
          "external-dns.alpha.kubernetes.io/hostname": "argocd.${local.env.dns_domain_suffix}"
        }
      }
      "env": [
        {
          name: "ARGOCD_API_SERVER_REPLICAS",
          value: "2"
        }
      ]
    }

    "repoServer": {
      "replicas": 2,
      "nodeSelector": {
        "eks.amazonaws.com/nodegroup": local.core_node_group_name
      }
    }

    "controller": {
      "nodeSelector": {
        "eks.amazonaws.com/nodegroup": local.core_node_group_name
      }
    }

    "dex": {
      "nodeSelector": {
        "eks.amazonaws.com/nodegroup": local.core_node_group_name
      }
    }

    "applicationSet": {
      "nodeSelector": {
        "eks.amazonaws.com/nodegroup": local.core_node_group_name
      }
    }

    "nodeSelector" : {
      "eks.amazonaws.com/nodegroup" : local.core_node_group_name
    }
  })
  tags                   = local.tags
}

terraform {
  source = "${local.base_source_url}//?ref=v18.21.0"
}

dependency "kms_dependency" {
  config_path = "../kms-dependency"
}

locals {
  base_source_url = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git"
  region          = yamldecode(file(find_in_parent_folders("region.yaml")))
  env             = yamldecode(file(find_in_parent_folders("env.yaml")))
  tenant          = yamldecode(file(find_in_parent_folders("tenant.yaml")))
  stack           = "eks"
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

  # Section for EKS cluster parameters
  cluster_name                    = local.name
  cluster_version                 = "1.22"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  enable_irsa                     = true
  iam_role_use_name_prefix        = false
  iam_role_name                   = "${local.name}-cluster"

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni    = {
      resolve_conflicts = "OVERWRITE"
    }

    aws-ebs-csi-driver = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [
    {
      provider_key_arn = dependency.kms_dependency.outputs.key_arn
      resources        = ["secrets"]
    }
  ]
  vpc_id     = local.env.vpc_id
  subnet_ids = local.env.private_subnet_ids

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    use_name_prefix          = false
    iam_role_use_name_prefix = false
    disk_size                = 50
    instance_types           = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    "${local.name}-core" = {
      min_size     = 3
      max_size     = 3
      desired_size = 3

      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      iam_role_name  = "${local.name}-node-group-core"

      iam_role_additional_policies = [
        # Required by Karpenter
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
    }

    "${local.name}-spark-drivers" = {
      min_size     = 0 # If using HPA, the minimum size should be at least 1
      max_size     = 3
      desired_size = 0 # If using HPA, the minimum size should be at least 1

      instance_types = ["r5.2xlarge"]
      capacity_type  = "ON_DEMAND"
      iam_role_name  = "${local.name}-node-group-spark-drivers"
      labels         = {
        "spark-role" = "driver"
      }
    }

    "${local.name}-spark-executors" = {
      min_size     = 0 # If using HPA, the minimum size should be at least 1
      max_size     = 10
      desired_size = 0 # If using HPA, the minimum size should be at least 1

      instance_types = ["r5.2xlarge", "r5.4xlarge"]
      capacity_type  = "SPOT"
      iam_role_name  = "${local.name}-node-group-spark-executors"
      labels         = {
        "spark-role" = "executor"
      }
    }
  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name      = "${local.name}-fargate"
      selectors = [
        {
          namespace = "default"
          labels    = {
            "kube/nodeType" : "fargate"
          }
        }
      ]
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = local.name
  }

  node_security_group_additional_rules = {
    https_ingress = {
      description                   = "Allow call webhook of load balancer"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      type                          = "ingress"
      source_cluster_security_group = true
    }

    karpenter_ingress = {
      description                   = "Allow call webhook of karpenter"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  cluster_security_group_additional_rules = {
    https_ingress = {
      description                   = "Allow call cluster endpoint"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "ingress"
      source_cluster_security_group = true
      cidr_blocks                   = ["0.0.0.0/0"]
    }
  }

  remote_access = {
    ec2_ssh_key               = local.name
    source_security_group_ids = [local.env.generic_security_group_id]
  }
}
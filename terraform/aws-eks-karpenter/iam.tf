module "karpenter_irsa_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts-eks?ref=v5.1.0"

  role_name                               = var.role_name
  policy_name_prefix                      = "${var.project}-${var.env}-${var.stack}-"
  attach_karpenter_controller_policy      = true
  karpenter_controller_cluster_id         = data.terraform_remote_state.eks.outputs.cluster_id
  karpenter_controller_node_iam_role_arns = [
    data.terraform_remote_state.eks.outputs.eks_managed_node_groups[local.core_node_name].iam_role_arn
  ]

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    eks = {
      provider_arn               = data.terraform_remote_state.eks.outputs.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${data.terraform_remote_state.eks.outputs.cluster_id}"
  role = data.terraform_remote_state.eks.outputs.eks_managed_node_groups[local.core_node_name].iam_role_name
}

resource "aws_iam_role_policy" "karpenter_controller_additional" {
  name = "${var.project}-${var.env}-${var.stack}-additional"
  role = module.karpenter_irsa_role.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
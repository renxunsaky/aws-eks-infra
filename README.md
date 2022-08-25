# Infra with Terraform and Terragrunt for EKS and its peripheral components

## Please note that you need to change the configuration in:
 - [terragrunt/eu-west-1/region.yaml](terragrunt/eu-west-1/region.yaml)
 - [terragrunt/eu-west-1/prod/env.yaml](terragrunt/eu-west-1/prod/env.yaml)
 - [terragrunt/eu-west-1/prod/terragrunt.hcl](terragrunt/eu-west-1/prod/terragrunt.hcl)
 - [terragrunt/eu-west-1/dev/env.yaml](terragrunt/eu-west-1/dev/env.yaml)
 - [terragrunt/eu-west-1/dev/terragrunt.hcl](terragrunt/eu-west-1/dev/terragrunt.hcl)

## To deploy EKS and its related components, it's important to respect the following order:
    1. eks-vpc-tags
    2. eks
    3. aws-eks-load-balancer-controller
    4. aws-eks-external-dns
    5. aws-eks-metrics-server
    6. aws-eks-karpenter or aws-eks-autoscaler
    7. aws-eks-argocd


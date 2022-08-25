include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "../../../_envcommon/aws-eks-vpc-tags.hcl"
}
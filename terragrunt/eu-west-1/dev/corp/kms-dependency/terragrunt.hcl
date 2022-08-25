terraform {
  source = "../../../../../terraform//kms-dependency"
}

include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "../../../_envcommon/kms-dependency.hcl"
}
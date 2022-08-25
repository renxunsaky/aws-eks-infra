remote_state {
  backend = "s3"
  config  = {
    bucket              = "dataArc-prod-terraform-states"
    key                 = "${path_relative_to_include()}"
    region              = "eu-west-1"
    encrypt             = true
    dynamodb_table      = "dataArc-prod-terraform-states-locks"
    s3_bucket_tags      = {
      Name           = "dataArc-prod-terraform-states"
      Project        = "data"
      TeamName       = "data"
      Component      = "terraform-states"
      Tenant         = "core"
      Env            = "prod"
      CreationMethod = "terraform"
      Owner          = "sakyrenxun@gmail.com"
    }
    dynamodb_table_tags = {
      Name           = "dataArc-prod-terraform-states-locks"
      Project        = "data"
      TeamName       = "data"
      Component      = "terraform-states-locks"
      Tenant         = "core"
      Env            = "prod"
      CreationMethod = "terraform"
      Owner          = "sakyrenxun@gmail.com"
    }
  }
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

generate = local.common.generate

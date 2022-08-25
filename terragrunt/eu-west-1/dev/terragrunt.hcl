remote_state {
  backend = "s3"
  config  = {
    bucket              = "dataArc-dev-terraform-states"
    key                 = "${path_relative_to_include()}"
    region              = "eu-west-1"
    encrypt             = true
    dynamodb_table      = "dataArc-dev-terraform-states-locks"
    s3_bucket_tags      = {
      Name           = "dataArc-dev-terraform-states"
      Project        = "data"
      TeamName       = "data"
      Component      = "terraform-states"
      Tenant         = "core"
      Env            = "dev"
      CreationMethod = "terraform"
      Owner          = "sakyrenxun@gmail.com"
    }
    dynamodb_table_tags = {
      Name           = "dataArc-dev-terraform-states-locks"
      Project        = "data"
      TeamName       = "data"
      Component      = "terraform-states-locks"
      Tenant         = "core"
      Env            = "dev"
      CreationMethod = "terraform"
      Owner          = "sakyrenxun@gmail.com"
    }
  }
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

generate = local.common.generate

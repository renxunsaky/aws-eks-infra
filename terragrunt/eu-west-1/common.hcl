generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.0.7"
      backend "s3" {}
    }

    provider "aws" {
      region = var.region
    }
    EOF
}

generate "common_variables" {
  path      = "common_variables.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    variable "region" {
      type    = string
    }

    variable "project" {
      type        = string
      description = "Project name."
    }

    variable "env" {
      type        = string
      description = "Environment name."
    }

    variable "tenant" {
      type        = string
      description = "Tenant name."
    }

    variable "stack" {
      type        = string
      description = "Stack name."
    }

    variable "terraform_state_bucket" {
      type        = string
      description = "Remote Terraform state bucket name."
    }
    EOF
}
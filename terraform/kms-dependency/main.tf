data "terraform_remote_state" "key" {
  backend = "s3"
  config = {
    region = var.region
    bucket = var.terraform_state_bucket
    key    = "${var.tenant}/key"
  }
}
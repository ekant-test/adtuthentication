data "aws_caller_identity" "this" {}
data "aws_region" "this" {}
# configure the project specific but otherwise static values
locals {
  account_id   = data.aws_caller_identity.this.account_id
  domain       = "example"
  service_name = "adjoin and unjoin"
  owner        = "ekant"
  contact      = "ekantmate@gmail.com"
  costcode     = "xxxx"
  cloud_id     = "ekant"
  common_tags = {
    "service:name"     = local.service_name
    "service:owner"    = local.owner
    "service:contact"  = local.contact
    "billing:costcode" = local.costcode
  }
}

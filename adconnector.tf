data "aws_vpc" "default" {
  filter {
    name   = "tag:Name"
    values = ["default-vpc"] # insert values here
  }
}

data "aws_security_group" "default" {
  filter {
    name   = "tag:Name"
    values = ["test"] # insert values here
  }
}

data "aws_subnet" "internal_app" {
  for_each = data.aws_subnet_ids.internal_app.ids
  id       = each.value
}

data "aws_subnet_ids" "internal_app" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "tag:Name"
    values = ["*internal*"] # insert values here
  }
}
data "aws_secretsmanager_secret_version" "creds" {
  secret_id = var.secret
}
locals {
  secret_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}
data "aws_secretsmanager_secret" "adunjoin" {
  name = "aws-ad-connector-service-account"
}
resource "aws_directory_service_directory" "connector" {
  name     = "ekant.com"
  password = local.secret_creds.password
  size     = "Small"
  type     = "ADConnector"
  connect_settings {
    customer_dns_ips  = ["x.x.x.x", "x.x.x.x"] ## DNS IP Address
    customer_username = local.secret_creds.username
    subnet_ids        = [values(data.aws_subnet.internal_app)[1].id, values(data.aws_subnet.internal_app)[2].id]
    vpc_id            = data.aws_vpc.default.id
  }
}

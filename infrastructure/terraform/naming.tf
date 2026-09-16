resource "random_id" "deployment" {
  byte_length = 4

  keepers = {
    vpc_id = aws_vpc.main.id
  }
}

locals {
  resource_suffix = random_id.deployment.hex

  rds_identifier   = "aws-enterprise-cicd-postgres-${local.resource_suffix}"
  rds_subnet_group = "aws-enterprise-cicd-postgres-${local.resource_suffix}"

  secret_prefix = "aws-enterprise-cicd/app/${local.resource_suffix}"
}

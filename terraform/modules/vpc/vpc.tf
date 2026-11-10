# vpc
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_config.cidr
  instance_tenancy = "default"

  tags = {
    Name = "${var.env}-${var.service_name}-vpc"
  }
}

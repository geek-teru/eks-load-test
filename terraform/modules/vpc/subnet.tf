# public subnet
resource "aws_subnet" "pub_subnet" {
  for_each          = var.pub_subnet_config
  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr
  tags = {
    Name = "${var.env}-${var.service_name}-public-${each.key}"
  }
}

# private subnet
resource "aws_subnet" "priv_subnet" {
  for_each          = var.priv_subnet_config
  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr
  tags = {
    Name = "${var.env}-${var.service_name}-private-${each.key}"
  }
}

resource "aws_eip" "nat_eip" {
  for_each = var.priv_subnet_config

  tags = {
    Name        = "${var.env}-${var.service_name}-${var.priv_subnet_config[each.key].az}-nat"
    Environment = var.env
  }
  depends_on = [
    aws_subnet.pub_subnet,
  ]
}

# NAT gateway for each public subnet on each availability zone.
resource "aws_nat_gateway" "vpc_ngw" {
  for_each = var.priv_subnet_config

  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = aws_subnet.pub_subnet[each.key].id

  tags = {
    Name        = "${var.env}-${var.service_name}-${var.priv_subnet_config[each.key].az}-ngw"
    Environment = var.env
  }

  depends_on = [
    aws_subnet.pub_subnet,
  ]
}

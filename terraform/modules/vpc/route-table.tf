# public route table
# public subnetはAZにかかわらずInternetGatewayに向けたルートをもつ
resource "aws_route_table" "pub_rtb" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.env}-${var.service_name}-pub-rtb"
  }
}

resource "aws_route" "pub_route" {
  route_table_id         = aws_route_table.pub_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_igw.id

  depends_on = [
    aws_internet_gateway.vpc_igw,
    aws_route_table.pub_rtb,
  ]
}

resource "aws_route_table_association" "pub-rt-association" {
  for_each = var.pub_subnet_config

  subnet_id      = aws_subnet.pub_subnet[each.key].id
  route_table_id = aws_route_table.pub_rtb.id
}

# private route table
# private subnetは各AZでそれぞれのAZのNATGatewayに向けたルートをもつ
resource "aws_route_table" "priv_rtb" {
  for_each = var.priv_subnet_config
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name = "${var.env}-${var.service_name}-priv-${each.value.az}-rtb"
  }
}

resource "aws_route" "priv_route" {
  for_each               = var.priv_subnet_config
  route_table_id         = aws_route_table.priv_rtb[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpc_ngw[each.key].id

  depends_on = [
    aws_nat_gateway.vpc_ngw,
    aws_route_table.priv_rtb,
  ]
}

resource "aws_route_table_association" "priv-rt-association" {
  for_each = var.priv_subnet_config

  subnet_id      = aws_subnet.priv_subnet[each.key].id
  route_table_id = aws_route_table.priv_rtb[each.key].id
}

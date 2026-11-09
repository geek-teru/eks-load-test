# internet gateway
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.env}-${var.service_name}-igw"
    Environment = var.env
  }
}

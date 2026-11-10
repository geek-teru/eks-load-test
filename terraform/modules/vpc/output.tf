output "cmn_vpc" {
  value = aws_vpc.vpc
}

output "pub_subnet_ids" {
  value = [
    for subnet in aws_subnet.pub_subnet : subnet.id
  ]
}

output "priv_subnet_ids" {
  value = [
    for subnet in aws_subnet.priv_subnet : subnet.id
  ]
}

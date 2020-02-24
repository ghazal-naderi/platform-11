output "public_subnets" {
  value = data.aws_subnet.public_subnets
}

output "private_subnets" {
  value = aws_subnet.private_subnets
}
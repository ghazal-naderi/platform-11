data "aws_subnet_ids" "public_subnet_ids" {
  vpc_id = var.vpc_id
}

data "aws_subnet" "public_subnets" {
  for_each = data.aws_subnet_ids.public_subnet_ids.ids
  id       = each.value
}

resource "aws_subnet" "private_subnets" {
    for_each          = var.private_subnet_confs 
    vpc_id            = var.vpc_id
    cidr_block        = each.value.cidr
    availability_zone = each.value.az

    tags = {
      Name = "private-${each.value.az}-subnet"
    }
}

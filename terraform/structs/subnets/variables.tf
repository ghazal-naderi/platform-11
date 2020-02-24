variable "vpc_id" {
  description = "ID of the VPC to create subnets within"
}

variable "private_subnet_confs" {
  description = "Config objects to use for private subnets"
  type = map
}

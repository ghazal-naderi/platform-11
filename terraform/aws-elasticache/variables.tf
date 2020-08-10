variable "name" {
  description = "Instance name to be use for resource naming and tags"
  default     = "cache"
}

variable "shards" {
  description = "The number of shards to be used for ElastiCache"
  default = "1"
}

variable "node_type" {
  description = "The type or size of the ElastiCache node(s)"
  default = "cache.t3.medium"
}

variable "vpc_id" {
  description = "ID of the VPC within which the cache will be created"
}

variable "cache_subnet_confs" {
  description = "Config objects to use for cache subnets"
  type        = map
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks that should be allowed to access the cache subnets"
  type        = list
}


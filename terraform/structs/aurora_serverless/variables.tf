variable "name" {
    description = "Instance name to be use for resource naming and tags"
    default = "serverless_db"
}

variable "master_username" {
    description = "Master username for DB instance"
    default = "postgresql"
}

variable "vpc_id" {
    description = "ID of the VPC within which the DB will be created"
}

variable "ingress_cidr_blotcks" {
    description = "CIDR blocks that should be allowed to access the DB subnets"
    type = list
}

variable "db_subnets" {
    description = "Subnets which the DB will be created within. Ideally these should be private"
    type = map
}

variable "auto_pause" {
    description = "Whether or not the DB should pause on idle"
}

variable "max_capacity" {
    description = "Maximum ACU capacity. Must be a power of two up to max 256"
}

variable "min_capacity" {
    description = "Minimum ACU capacity. Must be a power of two up to max 256"
}

variable "seconds_until_auto_pause" {
    description = "Number of seconds with of idle connection acitivity before the DB will pause"
}

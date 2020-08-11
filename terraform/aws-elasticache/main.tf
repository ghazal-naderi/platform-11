resource "aws_security_group" "cache" {
  vpc_id      = var.vpc_id
  name        = format("cache-%s-sg", var.name)
  description = format("Security Group for %s ElastiCache instance", var.name)

  ingress {
    protocol    = "tcp"
    from_port   = 6379
    to_port     = 6379
    cidr_blocks = var.ingress_cidr_blocks
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "cache_subnets" {
  for_each          = var.cache_subnet_confs
  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.name}-cache-${each.value.az}-subnet"
  }
}

resource "aws_elasticache_subnet_group" "default" {
  name        = var.name
  description = format("ElastiCache subnet group for %s ElastiCache instance", var.name)
  subnet_ids  = [for s in aws_subnet.cache_subnets : s.id]
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = var.name
  replication_group_description = "Redis cluster"
  node_type                     = var.node_type
  port                          = 6379
  transit_encryption_enabled    = true
  at_rest_encryption_enabled    = true
  parameter_group_name          = "default.redis5.0.cluster.on"
  snapshot_retention_limit      = 1
  snapshot_window               = "00:00-05:00"

  automatic_failover_enabled = true

  cluster_mode {
    replicas_per_node_group = 1
    num_node_groups         = var.shards
  }
  security_group_ids = [aws_security_group.cache.id]
  subnet_group_name  = aws_elasticache_subnet_group.default.name

  tags = {
    Name = var.name
  }
}

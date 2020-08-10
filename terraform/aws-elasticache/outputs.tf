output "elasticache_id" {
  value       = aws_elasticache_replication_group.redis.replication_group_id
  description = "The ID for the cluster"
}
output "primary_endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "The endpoint for the ElastiCache cluster for primary data access"
}
output "configuration_endpoint" {
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address
  description = "The endpoint for the ElastiCache cluster for host discovery"
}


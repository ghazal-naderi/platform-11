output "db_id" {
  value       = aws_rds_cluster.postgresql.id
  description = "The ID for the db"
}

output "db_name" {
  value       = aws_rds_cluster.postgresql.database_name
  description = "The name for the db"
}

output "endpoint" {
  value       = aws_rds_cluster.postgresql.endpoint
  description = "The endpoint for the db"
}

output "reader_endpoint" {
  value       = aws_rds_cluster.postgresql.reader_endpoint
  description = "The read only endpoint for the db"
}

output "master_username" {
  value       = aws_rds_cluster.postgresql.master_username
  description = "The master username for the db"
}

output "temp_password" {
  value       = random_password.temp.result
  description = "The initial random temp password"
  sensitive   = true
}

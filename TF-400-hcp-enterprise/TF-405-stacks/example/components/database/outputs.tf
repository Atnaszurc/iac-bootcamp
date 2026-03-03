output "endpoint" {
  description = "Database endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "Database host address"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}
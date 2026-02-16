# ─────────────────────────────────────────────
# RDS Module — Outputs
# ─────────────────────────────────────────────

output "db_instance_id" {
  value = aws_db_instance.main.id
}

output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_address" {
  value = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "db_credentials_secret_arn" {
  description = "ARN do secret com credenciais do banco"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

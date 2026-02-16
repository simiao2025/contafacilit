output "db_credentials_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "app_secrets_arn" {
  value = aws_secretsmanager_secret.app_secrets.arn
}

# ─────────────────────────────────────────────
# ElastiCache Module — Outputs
# ─────────────────────────────────────────────

output "redis_endpoint" {
  description = "Endpoint primário do Redis"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_port" {
  description = "Porta do Redis"
  value       = aws_elasticache_replication_group.main.port
}

output "redis_connection_string" {
  description = "Connection string do Redis"
  value       = "rediss://${aws_elasticache_replication_group.main.primary_endpoint_address}:${aws_elasticache_replication_group.main.port}"
}

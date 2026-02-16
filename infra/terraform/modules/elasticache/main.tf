# ─────────────────────────────────────────────
# ElastiCache Module — Redis
# ─────────────────────────────────────────────

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-redis-subnet"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

resource "aws_elasticache_parameter_group" "main" {
  family = "redis7"
  name   = "${var.project_name}-${var.environment}-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = var.tags
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-${var.environment}"
  description          = "Redis cluster para ${var.project_name} ${var.environment}"

  # Engine
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.main.name

  # Cluster
  num_cache_clusters = var.num_cache_nodes
  automatic_failover_enabled = var.num_cache_nodes > 1
  multi_az_enabled           = var.num_cache_nodes > 1

  # Network
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [var.security_group_id]

  # Security
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  # Maintenance
  maintenance_window       = "sun:05:00-sun:06:00"
  snapshot_retention_limit  = var.environment == "prod" ? 7 : 1
  snapshot_window           = "04:00-05:00"
  auto_minor_version_upgrade = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redis"
  })
}

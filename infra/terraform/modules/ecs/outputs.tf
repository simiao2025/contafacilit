# ─────────────────────────────────────────────
# ECS Module — Outputs
# ─────────────────────────────────────────────

output "cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "api_service_name" {
  value = aws_ecs_service.api.name
}

output "worker_service_name" {
  value = aws_ecs_service.worker.name
}

output "alb_dns_name" {
  description = "DNS name do ALB para configurar CNAME"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID do ALB para Route53 alias"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  value = aws_lb.main.arn
}

# ─────────────────────────────────────────────
# Monitoring Module — Variables
# ─────────────────────────────────────────────

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_api_service_name" {
  type = string
}

variable "ecs_worker_service_name" {
  type = string
}

variable "ecs_ia_worker_service_name" {
  type = string
}

variable "sqs_events_queue_name" {
  type = string
}

variable "sqs_ai_jobs_queue_name" {
  type = string
}

variable "rds_instance_id" {
  type = string
}

variable "alb_arn" {
  type = string
}

variable "alarm_email" {
  description = "E-mail para receber alertas"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

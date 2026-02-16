# ─────────────────────────────────────────────
# ECS Module — Variables
# ─────────────────────────────────────────────

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "db_credentials_secret_arn" {
  type = string
}

variable "redis_connection_string" {
  type = string
}

# ─── API Service ─────────────────────────────

variable "api_image" {
  description = "Imagem Docker da API"
  type        = string
  default     = "contafacilit/api:latest"
}

variable "api_cpu" {
  description = "CPU units para API (1 vCPU = 1024)"
  type        = number
  default     = 512
}

variable "api_memory" {
  description = "Memória em MB para API"
  type        = number
  default     = 1024
}

variable "api_desired_count" {
  description = "Número desejado de tasks da API"
  type        = number
  default     = 2
}

variable "api_min_count" {
  description = "Mínimo de tasks da API"
  type        = number
  default     = 2
}

variable "api_max_count" {
  description = "Máximo de tasks da API"
  type        = number
  default     = 10
}

# ─── Worker Service ──────────────────────────

variable "worker_image" {
  description = "Imagem Docker do Worker"
  type        = string
  default     = "contafacilit/worker:latest"
}

variable "worker_cpu" {
  type    = number
  default = 256
}

variable "worker_memory" {
  type    = number
  default = 512
}

variable "worker_desired_count" {
  type    = number
  default = 1
}

variable "worker_min_count" {
  type    = number
  default = 1
}

variable "worker_max_count" {
  type    = number
  default = 5
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ─────────────────────────────────────────────
# RDS Module — Variables
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

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Armazenamento em GB"
  type        = number
  default     = 50
}

variable "max_allocated_storage" {
  description = "Armazenamento máximo para autoscaling"
  type        = number
  default     = 200
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "contafacilit"
}

variable "db_username" {
  description = "Usuário master do banco"
  type        = string
  default     = "contafacilit_admin"
}

variable "multi_az" {
  description = "Habilitar Multi-AZ"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Dias de retenção de backup"
  type        = number
  default     = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}

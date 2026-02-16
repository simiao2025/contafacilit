# ─────────────────────────────────────────────
# ElastiCache Module — Variables
# ─────────────────────────────────────────────

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "node_type" {
  description = "Tipo do node ElastiCache"
  type        = string
  default     = "cache.t3.medium"
}

variable "num_cache_nodes" {
  description = "Número de nodes no cluster"
  type        = number
  default     = 2
}

variable "tags" {
  type    = map(string)
  default = {}
}

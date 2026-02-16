# ═════════════════════════════════════════════
# ContaFacilit — Ambiente PROD
# Dimensionado para 10.000 clientes
# ═════════════════════════════════════════════

terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "contafacilit-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "contafacilit-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "contafacilit"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

# ─── Variables ───────────────────────────────

variable "aws_region" {
  default = "us-east-1"
}

variable "alarm_email" {
  type = string
}

locals {
  project_name = "contafacilit"
  environment  = "prod"

  tags = {
    Project     = local.project_name
    Environment = local.environment
  }
}

# ═════════════════════════════════════════════
# MODULES
# ═════════════════════════════════════════════

module "vpc" {
  source = "../../modules/vpc"

  project_name = local.project_name
  environment  = local.environment
  vpc_cidr     = "10.2.0.0/16"

  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]

  tags = local.tags
}

module "security" {
  source = "../../modules/security"

  project_name = local.project_name
  environment  = local.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr

  tags = local.tags
}

module "rds" {
  source = "../../modules/rds"

  project_name       = local.project_name
  environment        = local.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.rds_security_group_id

  # Prod: dimensionado para 10.000 clientes
  instance_class          = "db.r6g.large"   # 2 vCPU, 16 GB RAM
  allocated_storage       = 100
  max_allocated_storage   = 500
  multi_az                = true
  backup_retention_period = 14

  tags = local.tags
}

module "elasticache" {
  source = "../../modules/elasticache"

  project_name       = local.project_name
  environment        = local.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.redis_security_group_id

  # Prod: 3 nodes Multi-AZ
  node_type       = "cache.r6g.large"
  num_cache_nodes = 3

  tags = local.tags
}

  tags = local.tags
}

module "kms" {
  source = "../../modules/kms"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags
}

module "sqs" {
  source = "../../modules/sqs"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags
}

module "waf" {
  source = "../../modules/waf"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags
}

module "ecs" {
  source = "../../modules/ecs"

  project_name              = local.project_name
  environment               = local.environment
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  private_subnet_ids        = module.vpc.private_subnet_ids
  ecs_security_group_id     = module.security.ecs_security_group_id
  alb_security_group_id     = module.security.alb_security_group_id
  db_credentials_secret_arn = module.rds.db_credentials_secret_arn
  redis_connection_string   = module.elasticache.redis_connection_string
  sqs_events_queue_arn      = module.sqs.events_queue_arn
  sqs_ai_jobs_queue_arn     = module.sqs.ai_jobs_queue_arn
  waf_acl_arn               = module.waf.waf_acl_arn

  # Prod: dimensionado para 10.000 clientes
  api_cpu           = 1024       # 1 vCPU
  api_memory        = 2048       # 2 GB
  api_desired_count = 3
  api_min_count     = 2
  api_max_count     = 10

  worker_cpu           = 512
  worker_memory        = 1024
  worker_desired_count = 2
  worker_min_count     = 1
  worker_max_count     = 5

  ia_worker_cpu           = 2048 # IA exige mais recursos em prod
  ia_worker_memory        = 4096
  ia_worker_desired_count = 2
  ia_worker_max_count     = 10

  tags = local.tags
}

module "s3" {
  source = "../../modules/s3"

  project_name = local.project_name
  environment  = local.environment

  tags = local.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name               = local.project_name
  environment                = local.environment
  ecs_cluster_name           = module.ecs.cluster_name
  ecs_api_service_name       = module.ecs.api_service_name
  ecs_worker_service_name    = module.ecs.worker_service_name
  ecs_ia_worker_service_name = module.ecs.ia_worker_service_name
  rds_instance_id            = module.rds.db_instance_id
  alb_arn                    = module.ecs.alb_arn
  sqs_events_queue_name      = replace(module.sqs.events_queue_url, "/.*\\//", "")
  sqs_ai_jobs_queue_name     = replace(module.sqs.ai_jobs_queue_url, "/.*\\//", "")
  alarm_email                = var.alarm_email

  tags = local.tags
}

# ─── Outputs ─────────────────────────────────

output "alb_dns_name" {
  description = "DNS do ALB — apontar CNAME do domínio aqui"
  value       = module.ecs.alb_dns_name
}

output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}

output "redis_endpoint" {
  value     = module.elasticache.redis_endpoint
  sensitive = true
}

output "documents_bucket" {
  value = module.s3.documents_bucket_name
}

output "db_credentials_secret_arn" {
  description = "ARN do Secret Manager com credenciais do banco"
  value       = module.rds.db_credentials_secret_arn
  sensitive   = true
}

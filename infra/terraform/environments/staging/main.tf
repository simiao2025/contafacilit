# ═════════════════════════════════════════════
# ContaFacilit — Ambiente STAGING
# ═════════════════════════════════════════════

terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "contafacilit-terraform-state"
    key            = "staging/terraform.tfstate"
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
      Environment = "staging"
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
  environment  = "staging"

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
  vpc_cidr     = "10.1.0.0/16"

  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]

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

  # Staging: reflete prod mas com sizing menor
  instance_class          = "db.t3.medium"
  allocated_storage       = 30
  max_allocated_storage   = 100
  multi_az                = true
  backup_retention_period = 3

  tags = local.tags
}

module "elasticache" {
  source = "../../modules/elasticache"

  project_name       = local.project_name
  environment        = local.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.redis_security_group_id

  # Staging: 2 nodes com failover
  node_type       = "cache.t3.small"
  num_cache_nodes = 2

  tags = local.tags
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

  api_cpu           = 512
  api_memory        = 1024
  api_desired_count = 2
  api_min_count     = 1
  api_max_count     = 4

  worker_cpu           = 256
  worker_memory        = 512
  worker_desired_count = 1
  worker_min_count     = 1
  worker_max_count     = 3

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

  project_name            = local.project_name
  environment             = local.environment
  ecs_cluster_name        = module.ecs.cluster_name
  ecs_api_service_name    = module.ecs.api_service_name
  ecs_worker_service_name = module.ecs.worker_service_name
  rds_instance_id         = module.rds.db_instance_id
  alb_arn                 = module.ecs.alb_arn
  alarm_email             = var.alarm_email

  tags = local.tags
}

# ─── Outputs ─────────────────────────────────

output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "redis_endpoint" {
  value = module.elasticache.redis_endpoint
}

output "documents_bucket" {
  value = module.s3.documents_bucket_name
}

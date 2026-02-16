# ═════════════════════════════════════════════
# ContaFacilit — Terraform Infrastructure
# ═════════════════════════════════════════════
# SaaS fiscal multi-tenant para profissionais
# do marketing digital.
# ═════════════════════════════════════════════

## Estrutura de Diretórios

```
infra/terraform/
├── versions.tf                          # Versões do Terraform e providers
├── modules/
│   ├── vpc/                             # VPC, subnets, NAT Gateway, routing
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   ├── security/                        # Security Groups (ALB, ECS, RDS, Redis)
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   ├── rds/                             # PostgreSQL Multi-AZ + Secrets Manager
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   ├── elasticache/                     # Redis replication group
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   ├── ecs/                             # Fargate (API + Worker) + ALB + Auto Scaling
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   ├── s3/                              # Buckets de documentos e logs
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   └── monitoring/                      # CloudWatch alarms + dashboard
│       ├── variables.tf
│       ├── main.tf
│       └── outputs.tf
└── environments/
    ├── dev/main.tf                      # Ambiente de desenvolvimento
    ├── staging/main.tf                  # Ambiente de homologação
    └── prod/main.tf                     # Produção (10.000 clientes)
```

## Pré-requisitos

1. **Terraform** >= 1.5.0 instalado
2. **AWS CLI** configurado com credenciais
3. **S3 bucket** para state: `contafacilit-terraform-state`
4. **DynamoDB table** para locks: `contafacilit-terraform-locks`

### Bootstrap do backend (executar uma vez):

```bash
aws s3api create-bucket \
  --bucket contafacilit-terraform-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket contafacilit-terraform-state \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name contafacilit-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Uso

### Deploy de um ambiente:

```bash
cd infra/terraform/environments/dev
terraform init
terraform plan -var="alarm_email=team@contafacilit.com.br"
terraform apply -var="alarm_email=team@contafacilit.com.br"
```

### Comparação de ambientes:

| Recurso | Dev | Staging | Prod |
|---------|-----|---------|------|
| AZs | 2 | 2 | 3 |
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| RDS Instance | db.t3.small | db.t3.medium | db.r6g.large |
| RDS Multi-AZ | ❌ | ✅ | ✅ |
| RDS Storage | 20-50 GB | 30-100 GB | 100-500 GB |
| RDS Backup | 1 dia | 3 dias | 14 dias |
| Redis Nodes | 1 (t3.micro) | 2 (t3.small) | 3 (r6g.large) |
| ECS API Tasks | 1-2 | 1-4 | 2-10 |
| ECS API CPU/Mem | 256/512 | 512/1024 | 1024/2048 |
| ECS Worker Tasks | 1-2 | 1-3 | 1-5 |
| NAT Gateways | 1 | 1 | 3 (HA) |
| Delete Protection | ❌ | ❌ | ✅ |
| Log Retention | 14 dias | 14 dias | 90 dias |

## Segurança

- **RDS e Redis** isolados em subnets privadas (sem acesso público)
- **Security Groups** restritivos (apenas tráfego necessário entre camadas)
- **Credenciais** do banco geradas automaticamente e armazenadas no **Secrets Manager**
- **Encryption** at rest (RDS, Redis, S3) e in transit (TLS)
- **S3** com bloqueio total de acesso público
- **ALB** redireciona HTTP → HTTPS (certificado ACM necessário)

## Auto Scaling

O ECS utiliza **Target Tracking** com 3 métricas:
- **CPU** > 70% → scale out (API) / > 75% (Worker)
- **Memória** > 80% → scale out
- **Requests/target** > 1000 → scale out (API)

Cooldown: 60s (scale out) / 300s (scale in)

## Monitoramento

CloudWatch Dashboard com 4 painéis:
1. ECS API — CPU & Memory
2. ECS Worker — CPU & Memory
3. RDS — CPU, Connections, Storage
4. ALB — Requests, Latency p95, 5xx Errors

Alertas via SNS (e-mail) para:
- CPU alta (ECS, RDS)
- Memória alta (ECS)
- Storage baixo (RDS)
- Connections alta (RDS)
- 5xx errors (ALB)
- Latência p95 > 3s (ALB)

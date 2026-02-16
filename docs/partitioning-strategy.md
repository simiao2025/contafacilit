# Estratégia de Particionamento — bank_transactions

## Objetivo

Otimizar performance de queries em tabelas de alto volume através de **RANGE Partitioning** mensal no PostgreSQL 16.

## Decisões Técnicas

### Por que RANGE por mês?
- Transações bancárias são **naturalmente temporais** — queries sempre filtram por período.
- O particionamento por mês permite **Partition Pruning** automático: o PostgreSQL ignora partições fora do range da query.
- Em 10.000 clientes com ~100 transações/mês, cada partição terá ~1M de linhas (gerenciável).

### Primary Key Composta
A PK da tabela particionada **obrigatoriamente inclui a coluna de partição**:
```sql
PRIMARY KEY (id, occurred_at)
```
Isso é uma exigência do PostgreSQL para tabelas particionadas.

### Índices Locais (por partição)
Cada partição recebe automaticamente seus próprios índices:

| Índice | Colunas | Propósito |
|:---|:---|:---|
| `idx_bank_tx_org_occurred` | `organization_id, occurred_at DESC` | Queries multi-tenant por período |
| `idx_bank_tx_external_id` | `external_id` (parcial) | Reconciliação bancária |
| `idx_bank_tx_account` | `bank_account_id, occurred_at DESC` | Extrato por conta |

### Criação Automática de Partições
A função `create_monthly_partitions()` cria partições futuras automaticamente. Deve ser executada mensalmente via **pg_cron** ou **AWS Lambda + EventBridge**.

## Impacto no Prisma
O Prisma não suporta nativamente tabelas particionadas. As queries continuam funcionando normalmente, pois o particionamento é **transparente** para a aplicação. Apenas a migration inicial deve ser executada via SQL puro (não via `prisma migrate`).

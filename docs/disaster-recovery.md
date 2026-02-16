# ContaFacilit — Estratégia de Disaster Recovery (DR)

> **Versão:** 1.0  
> **Status:** Especificação Técnica  
> **Objetivo:** Garantir a continuidade do negócio e a integridade de dados financeiros em cenários de falha catastrófica.

---

## 1. Objetivos de Recuperação (SLAs)

Para um SaaS contábil, a perda de dados é inaceitável. Nossos SLAs de DR são:

- **RPO (Recovery Point Objective):** 5 minutos.  
  *Garantia de que, em caso de falha, perderemos no máximo os últimos 5 minutos de dados graças ao Point-in-Time Recovery (PITR).*
- **RTO (Recovery Time Objective):** 20 minutos.  
  *Tempo máximo para restaurar a operação completa em um novo ambiente ou failover.*

---

## 2. Estratégia de Banco de Dados (RDS)

O Amazon RDS é o coração do sistema. Implementamos:

### 2.1 Multi-AZ (Alta Disponibilidade)
- **Produção:** O RDS opera em modo **Multi-AZ**, mantendo uma réplica síncrona em uma Availability Zone diferente.
- **Failover:** Automático em caso de falha na zona primária (sem perda de dados).

### 2.2 Política de Backup e Retenção
- **Automated Backups:** Retenção de **35 dias** (limite máximo do RDS).
- **Snapshot Final:** Gerado automaticamente ao deletar qualquer instância.
- **PITR:** Habilitado, permitindo restaurar o banco para qualquer segundo dentro do período de retenção.

---

## 3. Script de Restauração Automatizada

O script `scripts/aws/rds-restore.sh` automatiza o processo de:
1. Identificar o snapshot mais recente ou data específica.
2. Criar uma nova instância de RDS a partir do backup.
3. Validar a conectividade.
4. (Opcional) Trocar o CNAME do banco no Route53/Secrets Manager.

---

## 4. Teste de Restore Mensal (Drill)

Não existe Disaster Recovery sem teste.
- **Ambiente de Drill:** Todo mês, o ambiente de `staging-restore` é destruído e recriado a partir de um backup de produção.
- **Validação:** Um script automático verifica se o número de `organizations` e `tax_calculations` condiz com a produção.

---

## 5. Proteção de Borda e Aplicação

- **WAF:** Configurações exportadas via Terraform para rápida replicação.
- **S3 Backups:** Documentos fiscais e comprovantes armazenados com **Cross-Region Replication (CRR)** para uma região secundária (ex: us-east-1 -> sa-east-1).

---

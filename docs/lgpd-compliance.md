# ContaFacilit — Módulo de Compliance LGPD

> **Versão:** 1.0  
> **Status:** Especificação Técnica  
> **Base Legal:** Lei 13.709/2018 (LGPD) + Resolução Bacen 4.893/2021

---

## 1. Exclusão Total de Dados (Direito ao Esquecimento)

Endpoint que executa o **hard delete** ou **soft delete cascata** de todos os dados de uma organização.

- **Endpoint:** `DELETE /compliance/organizations/:id/data`
- **Proteção:** Apenas `ADMIN` pode solicitar. Requer confirmação (token de confirmação).
- **Fluxo:**
  1. Valida que o solicitante é ADMIN da organização.
  2. Anonimiza dados fiscais obrigatórios (retenção legal de 5 anos).
  3. Executa soft delete cascata em todas as tabelas vinculadas ao `organization_id`.
  4. Registra o evento no `AuditLog` com hash de integridade.

---

## 2. Anonimização Reversível

Para dados fiscais com obrigação legal de retenção (5 anos — CTN Art. 173):

- **Campos anonimizados:** razão social, CNPJ, nomes de usuários, emails.
- **Método:** AES-256-GCM com chave derivada do `organization_id` + master key.
- **Reversibilidade:** Apenas via ordem judicial, utilizando a chave mestra armazenada no AWS KMS.

---

## 3. Registro de Consentimento Open Finance

Modelo `DataConsent` para rastrear consentimentos explícitos:

- **Campos:** tipo de consentimento, data de aceite, IP, user-agent, escopo dos dados.
- **Imutabilidade:** Consentimentos nunca são deletados, apenas revogados.
- **Auditoria:** Cada consentimento gera um registro no `AuditLog`.

---

## 4. Política de Retenção Configurável

Tabela `RetentionPolicy` que define por quanto tempo cada tipo de dado é mantido:

| Tipo de Dado | Retenção Padrão | Base Legal |
|:---|:---|:---|
| Dados Fiscais | 5 anos | CTN Art. 173 |
| Transações Bancárias | 5 anos | Bacen 4.893 |
| Logs de Auditoria | 10 anos | Compliance |
| Dados Pessoais | Até revogação | LGPD Art. 15 |

---

## 5. Exportação de Auditoria

Endpoint para exportar todos os logs de auditoria de uma organização em formato JSON estruturado, facilitando auditorias externas e fiscalizações.

- **Endpoint:** `GET /compliance/organizations/:id/audit-export`
- **Formato:** JSON com hash SHA-256 de integridade.

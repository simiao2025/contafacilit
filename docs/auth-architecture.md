# ContaFacilit — Arquitetura de Autenticação e Segurança

> **Versão:** 2.0  
> **Data:** 2026-02-16  
> **Status:** Hardened Enterprise Security  
> **Framework:** NestJS + Passport.js + AES-256-GCM

---

## 1. Fluxo de Autenticação (JWT + Rotação)

O sistema utiliza **Refresh Tokens Rotativos** para balancear segurança e experiência do usuário.

### 1.1 Login e Tokens
- **AccessToken (JWT):** Expiração estrita de **15 minutos**. Contém `sub` (user_id), `org` (organization_id) e `role`.
- **RefreshToken (Opaque):** Expiração de **7 dias**. Rotacionado a cada uso.
- **Detecção de Reuso:** Se um Refresh Token antigo for reutilizado, o sistema invalida **todas** as sessões do usuário imediatamente (Security Event: `TOKEN_REUSE_DETECTED`).

---

## 2. Multi-tenancy & Zero Trust

Cada requisição é isolada pelo `organization_id` extraído do JWT.

### 2.1 Enforcement em 3 Níveis
1.  **Aplicação (Guards):** O `JwtAuthGuard` valida o token e o `RolesGuard` valida o acesso.
2.  **Lógica de Negócio (Services):** Todos os filtros de banco de dados utilizam o `org_id` injetado pelo `Request`.
3.  **Banco de Dados (RLS):** Policies de Row Level Security no PostgreSQL garantem que mesmo em caso de falha na aplicação, os dados não vazem entre tenants.

### 2.2 Proteção contra Privilege Escalation
- Usuários não podem alterar seu próprio `role` ou `organization_id`.
- Promoções para `ADMIN` exigem que o solicitante também seja `ADMIN` da mesma organização e o evento é registrado na trilha de segurança.

---

## 3. Criptografia de Dados Sensíveis (AES-256-GCM)

Tokens de integração (Pluggy, Hotmart, etc.) não são armazenados em texto simples.

- **Estratégia:** AES-256-GCM (Authenticated Encryption).
- **Chave:** Derivada de uma Master Key (AWS KMS) + Sal per-tenant.
- **Local:** Tabela `integrations.credentials_vault_id` agora armazena o payload criptografado se não estiver usando Secrets Manager externo.

---

## 4. Auditoria e Eventos de Segurança

Eventos críticos registrados na tabela `audit_logs`:
- `AUTH_LOGIN_SUCCESS` / `AUTH_LOGIN_FAILURE`
- `AUTH_TOKEN_REVOKED`
- `SECURITY_PRIVILEGE_ESCALATION_ATTEMPT`
- `INTEGRATION_CREDENTIALS_ACCESS`

---

## 5. Rate Limiting e Filtros

- **Global Throttler:** Limite de requisições por IP e por User.
- **Login Throttler:** Proteção agressiva contra brute-force no endpoint `/auth/login`.
- **Validation Pipes:** Sanitização rigorosa de inputs para prevenir SQL Injection e XSS.

---

## 6. Mapeamento de Roles (RBAC)

| Role | Permissões | Nível de Risco |
| :--- | :--- | :--- |
| **ADMIN** | Gestão de Org, Usuários e Faturamento. | Alto |
| **CONTADOR** | Apurações Fiscais e Conciliação. | Médio |
| **COLABORADOR** | Visualização e Upload de Documentos. | Baixo |

---

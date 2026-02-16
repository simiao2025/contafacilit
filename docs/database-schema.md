# ContaFacilit — Modelagem de Banco de Dados (SaaS Financeiro)

> **Versão:** 3.0  
> **Data:** 2026-02-16  
> **Especialidade:** Performance PostgreSQL para SaaS Multi-tenant  
> **Capacidades:** pgvector, Soft Delete, RBT12 Sliding Windows

---

## 1. Contexto Multi-tenancy & pgvector

- **Isolamento:** Uso obrigatório de `organization_id` em tabelas de dados de clientes.
- **pgvector:** Suporte nativo para embeddings de mensagens da IA para busca semântica.

```sql
-- Extensões Necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector"; -- Requer AWS RDS pgvector habilitado
```

---

## 2. Tipos de Domínio (Enums)

```sql
CREATE TYPE user_role AS ENUM ('ADMIN', 'CONTADOR', 'COLABORADOR');
CREATE TYPE org_status AS ENUM ('ACTIVE', 'SUSPENDED', 'CANCELLED');
CREATE TYPE tax_anexo AS ENUM ('I', 'II', 'III', 'IV', 'V');
CREATE TYPE calc_status AS ENUM ('DRAFT', 'CALCULATED', 'FINALIZED');
CREATE TYPE bank_acc_type AS ENUM ('CHECKING', 'SAVINGS', 'PAYMENT');
CREATE TYPE integration_provider AS ENUM ('PLUGGY', 'BELVO', 'HOTMART', 'KIWIFY', 'EDUZZ');
```

---

## 3. Esquema de Tabelas (Sessão por Módulo)

### 3.1 Núcleo e Identidade
```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cnpj CHAR(14) NOT NULL UNIQUE,
    razao_social VARCHAR(255) NOT NULL,
    status org_status NOT NULL DEFAULT 'ACTIVE',
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    email VARCHAR(255) NOT NULL,
    password_hash TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'COLABORADOR',
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT uq_user_email_org UNIQUE(email, organization_id) -- Permite mesmo email em orgs diferentes se necessário
);
```

### 3.2 Financeiro e Integrações
```sql
CREATE TABLE bank_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    provider_id TEXT NOT NULL, -- ID no Pluggy/Belvo
    account_name TEXT NOT NULL,
    account_type bank_acc_type NOT NULL,
    balance NUMERIC(15, 2) NOT NULL DEFAULT 0,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE bank_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    bank_account_id UUID NOT NULL REFERENCES bank_accounts(id),
    external_id TEXT UNIQUE, -- ID da transação no banco original
    amount NUMERIC(15, 2) NOT NULL,
    description TEXT,
    occurred_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE integrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    provider integration_provider NOT NULL,
    credentials_vault_id TEXT NOT NULL, -- ID no AWS Secrets Manager para o token
    is_active BOOLEAN DEFAULT TRUE,
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(organization_id, provider)
);
```

### 3.3 Fiscal (Motor & Receitas)
```sql
CREATE TABLE motor_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version_tag VARCHAR(50) NOT NULL UNIQUE,
    config JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE revenues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    competencia CHAR(7) NOT NULL, -- YYYY-MM
    amount NUMERIC(15, 2) NOT NULL,
    source integration_provider,
    occurred_at DATE NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ÍNDICE CRÍTICO PARA RBT12 (Sliding Window 12m)
CREATE INDEX idx_revenues_sliding_window ON revenues (organization_id, occurred_at) 
WHERE deleted_at IS NULL;

CREATE TABLE tax_calculations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    motor_version_id UUID NOT NULL REFERENCES motor_versions(id),
    competencia CHAR(7) NOT NULL,
    amount_rbt12 NUMERIC(15, 2) NOT NULL,
    tax_amount NUMERIC(15, 2) NOT NULL,
    status calc_status DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT uq_tax_calc_org_month UNIQUE(organization_id, competencia)
);
```

### 3.4 Inteligência Artificial (pgvector)
```sql
CREATE TABLE ai_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    user_id UUID NOT NULL REFERENCES users(id),
    title TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ai_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES ai_conversations(id),
    role TEXT NOT NULL, -- 'user' or 'assistant'
    content TEXT NOT NULL,
    embedding vector(1536), -- Vector dim 1536 para OpenAI/titile embeddings
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ai_messages_embedding ON ai_messages USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

### 3.5 Auditoria
```sql
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES organizations(id),
    user_id UUID REFERENCES users(id),
    event TEXT NOT NULL,
    old_data JSONB,
    new_data JSONB,
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_tenant ON audit_logs (organization_id, created_at DESC);
```

---

## 4. Otimizações de Escalabilidade (10k+ Clientes)

1.  **Partial Indexes:** Uso de `WHERE deleted_at IS NULL` em todos os índices de busca para manter performance com soft delete.
2.  **Constraint Isolation:** Todas as constraints `UNIQUE` e de `FK` incluem o `organization_id` ou garantem o vínculo claro com o tenant.
3.  **JSONB for Flexibility:** `motor_versions.config` e `audit_logs.data` usam JSONB para evolução de esquema sem migrations bloqueantes.

---

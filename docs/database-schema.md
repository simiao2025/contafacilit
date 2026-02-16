# ContaFacilit — Modelagem de Banco de Dados

> **Versão:** 1.0  
> **Data:** 2026-02-16  
> **Status:** Produção-Ready  
> **Engine:** PostgreSQL 16+

---

## 1. Estratégia de Multi-tenancy

O sistema utiliza a estratégia de **Shared Database com Discriminador de Coluna**.
- Todas as tabelas relacionadas a dados de clientes possuem a coluna `organization_id`.
- O isolamento deve ser reforçado na camada de aplicação e, opcionalmente, via PostgreSQL **Row Level Security (RLS)**.

---

## 2. Tipos Enumerate (Enums)

```sql
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'organization_status') THEN
        CREATE TYPE organization_status AS ENUM ('ACTIVE', 'SUSPENDED', 'CANCELLED');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'anexo_simples') THEN
        CREATE TYPE anexo_simples AS ENUM ('I', 'II', 'III', 'IV', 'V');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'calculation_status') THEN
        CREATE TYPE calculation_status AS ENUM ('DRAFT', 'CALCULATED', 'FINALIZED');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'revenue_status') THEN
        CREATE TYPE revenue_status AS ENUM ('PENDING', 'VALIDATED', 'LOCKED');
    END IF;
END $$;
```

---

## 3. Esquema de Tabelas

### 3.1 Organizations & Users

```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cnpj CHAR(14) NOT NULL UNIQUE,
    razao_social VARCHAR(255) NOT NULL,
    nome_fantasia VARCHAR(255),
    data_abertura DATE NOT NULL,
    anexo_padrao anexo_simples NOT NULL DEFAULT 'III',
    fator_r_aplicavel BOOLEAN NOT NULL DEFAULT FALSE,
    status organization_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_org ON users(organization_id);
```

### 3.2 Motor Versions (Metadados Tributários)

```sql
CREATE TABLE motor_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_tag VARCHAR(50) NOT NULL UNIQUE, -- e.g., '2026.1.0'
    config_json JSONB NOT NULL, -- Contém as faixas e alíquotas por anexo
    vigencia_inicio DATE NOT NULL,
    vigencia_fim DATE,
    changelog TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_motor_vigencia ON motor_versions(vigencia_inicio) WHERE vigencia_fim IS NULL;
```

### 3.3 Revenues (Receitas Brutas)

```sql
CREATE TABLE revenues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    competencia CHAR(7) NOT NULL, -- Formato 'YYYY-MM'
    data_recebimento DATE NOT NULL,
    valor_bruto NUMERIC(15, 2) NOT NULL CHECK (valor_bruto > 0),
    descricao VARCHAR(500),
    origem VARCHAR(100),
    status revenue_status NOT NULL DEFAULT 'PENDING',
    deleted_at TIMESTAMPTZ, -- Soft delete
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices Críticos para RBT12
CREATE INDEX idx_revenues_rbt12 ON revenues (organization_id, competencia) 
WHERE deleted_at IS NULL;

CREATE INDEX idx_revenues_org_status ON revenues(organization_id, status);
```

### 3.4 Tax Calculations (Apurações)

```sql
CREATE TABLE tax_calculations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    motor_version_id UUID NOT NULL REFERENCES motor_versions(id),
    competencia CHAR(7) NOT NULL,
    
    -- Inputs (Snapshots)
    receita_bruta_mes NUMERIC(15, 2) NOT NULL,
    rbt12_calculado NUMERIC(15, 2) NOT NULL,
    fator_r_calculado NUMERIC(5, 4),
    anexo_aplicado anexo_simples NOT NULL,
    
    -- Outputs
    faixa_enquadrada INTEGER NOT NULL CHECK (faixa_enquadrada BETWEEN 1 AND 6),
    aliquota_nominal NUMERIC(6, 4) NOT NULL,
    parcela_deduzir NUMERIC(15, 2) NOT NULL,
    aliquota_efetiva NUMERIC(6, 4) NOT NULL,
    valor_das NUMERIC(15, 2) NOT NULL,
    
    status calculation_status NOT NULL DEFAULT 'DRAFT',
    finalized_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Garantia de Apuração Única por Mês
    CONSTRAINT uq_tax_calc_month UNIQUE (organization_id, competencia)
);

CREATE INDEX idx_tax_calc_org_status ON tax_calculations(organization_id, status);
```

### 3.5 Audit Logs

```sql
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES organizations(id),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL, -- e.g., 'CALCULATION_FINALIZED'
    target_table VARCHAR(100) NOT NULL,
    target_id UUID NOT NULL,
    data_before JSONB,
    data_after JSONB,
    request_ip INET,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_org_created ON audit_logs(organization_id, created_at DESC);
```

---

## 4. Estratégia de Performance para RBT12

O cálculo do RBT12 exige somar as receitas dos últimos 12 meses. Para 10.000 clientes, isso pode ser custoso se feito de forma ingênua.

### 4.1 Indexação Baseada em Range
O índice `idx_revenues_rbt12` permite que o banco localize rapidamente as receitas de uma empresa em um intervalo de meses.

```sql
-- Exemplo de query otimizada para RBT12
SELECT SUM(valor_bruto) 
FROM revenues 
WHERE organization_id = $1 
  AND deleted_at IS NULL 
  AND competencia < '2026-02' 
  AND competencia >= '2025-02';
```

### 4.2 Materialização (Cache)
Para a V1, o valor do RBT12 é persistido na tabela `tax_calculations` assim que o cálculo é realizado. Isso evita re-processamento em cada visualização do dashboard.

---

## 5. Escalabilidade e Segurança

### 5.1 Partitioning (Futuro)
Se a tabela `revenues` ou `audit_logs` crescer demais (ex: milhões de linhas), pode-se implementar **Table Partitioning por Range de Data** ou por `organization_id` (Hash).

### 5.2 Row Level Security (RLS)
Recomenda-se ativar RLS para garantir que um cliente nunca veja os dados de outro, mesmo em caso de bug na aplicação.

```sql
ALTER TABLE revenues ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy ON revenues
USING (organization_id = current_setting('app.current_organization_id')::UUID);
```

### 5.3 Vacuum & Analyze
Configuração de **Autovacuum** agressivo é fundamental em sistemas fiscais devido a alta taxa de inserção/deleção temporal.

---

## 6. Constraints de Integridade (Checklist)

- [x] `NUMERIC` para precisão decimal (evita erros de ponto flutuante).
- [x] `UNIQUE (organization_id, competencia)` para evitar duplicidade de impostos no mesmo mês.
- [x] `CHECK (valor_bruto > 0)` para garantir consistência fiscal básica.
- [x] `REFERENCES` com chaves estrangeiras para integridade referencial.
- [x] `TIMESTAMPTZ` para lidar corretamente com fusos horários brasileiros (Brasília).

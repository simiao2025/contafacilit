-- 001_initial_schema.sql
-- Esse arquivo contém a estrutura inicial do banco de dados do ContaFacilit.

-- 1. Enums
CREATE TYPE organization_status AS ENUM ('ACTIVE', 'SUSPENDED', 'CANCELLED');
CREATE TYPE anexo_simples AS ENUM ('I', 'II', 'III', 'IV', 'V');
CREATE TYPE calculation_status AS ENUM ('DRAFT', 'CALCULATED', 'FINALIZED');
CREATE TYPE revenue_status AS ENUM ('PENDING', 'VALIDATED', 'LOCKED');

-- 2. Organizations
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

-- 3. Users
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

-- 4. Motor Versions
CREATE TABLE motor_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_tag VARCHAR(50) NOT NULL UNIQUE,
    config_json JSONB NOT NULL,
    vigencia_inicio DATE NOT NULL,
    vigencia_fim DATE,
    changelog TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_motor_vigencia ON motor_versions(vigencia_inicio) WHERE vigencia_fim IS NULL;

-- 5. Revenues
CREATE TABLE revenues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    competencia CHAR(7) NOT NULL,
    data_recebimento DATE NOT NULL,
    valor_bruto NUMERIC(15, 2) NOT NULL CHECK (valor_bruto > 0),
    descricao VARCHAR(500),
    origem VARCHAR(100),
    status revenue_status NOT NULL DEFAULT 'PENDING',
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_revenues_rbt12 ON revenues (organization_id, competencia) WHERE deleted_at IS NULL;
CREATE INDEX idx_revenues_org_status ON revenues(organization_id, status);

-- 6. Tax Calculations
CREATE TABLE tax_calculations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    motor_version_id UUID NOT NULL REFERENCES motor_versions(id),
    competencia CHAR(7) NOT NULL,
    receita_bruta_mes NUMERIC(15, 2) NOT NULL,
    rbt12_calculado NUMERIC(15, 2) NOT NULL,
    fator_r_calculado NUMERIC(5, 4),
    anexo_aplicado anexo_simples NOT NULL,
    faixa_enquadrada INTEGER NOT NULL CHECK (faixa_enquadrada BETWEEN 1 AND 6),
    aliquota_nominal NUMERIC(6, 4) NOT NULL,
    parcela_deduzir NUMERIC(15, 2) NOT NULL,
    aliquota_efetiva NUMERIC(6, 4) NOT NULL,
    valor_das NUMERIC(15, 2) NOT NULL,
    status calculation_status NOT NULL DEFAULT 'DRAFT',
    finalized_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tax_calc_month UNIQUE (organization_id, competencia)
);
CREATE INDEX idx_tax_calc_org_status ON tax_calculations(organization_id, status);

-- 7. Audit Logs
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES organizations(id),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    target_table VARCHAR(100) NOT NULL,
    target_id UUID NOT NULL,
    data_before JSONB,
    data_after JSONB,
    request_ip INET,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_audit_org_created ON audit_logs(organization_id, created_at DESC);

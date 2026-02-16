-- ═══════════════════════════════════════════════════════════════════════════
-- ContaFacilit — Migration: Partitioning bank_transactions by RANGE (Month)
-- Objetivo: Otimizar queries de alto volume para transações bancárias
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── Passo 1: Renomear tabela original ──────────────────────────────────
ALTER TABLE bank_transactions RENAME TO bank_transactions_old;

-- ─── Passo 2: Criar tabela particionada ─────────────────────────────────
CREATE TABLE bank_transactions (
    id              UUID        NOT NULL DEFAULT gen_random_uuid(),
    organization_id UUID        NOT NULL REFERENCES organizations(id),
    bank_account_id UUID        NOT NULL REFERENCES bank_accounts(id),
    external_id     TEXT,
    amount          DECIMAL(15,2) NOT NULL,
    description     TEXT,
    occurred_at     TIMESTAMP   NOT NULL,
    created_at      TIMESTAMP   NOT NULL DEFAULT now(),

    -- Primary key DEVE incluir a coluna de partição
    PRIMARY KEY (id, occurred_at)
) PARTITION BY RANGE (occurred_at);

-- ─── Passo 3: Criar partições históricas e futuras ──────────────────────
-- 2024
CREATE TABLE bank_transactions_2024_01 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE bank_transactions_2024_02 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE bank_transactions_2024_03 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE bank_transactions_2024_04 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE bank_transactions_2024_05 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE bank_transactions_2024_06 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE bank_transactions_2024_07 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE bank_transactions_2024_08 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE bank_transactions_2024_09 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE bank_transactions_2024_10 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE bank_transactions_2024_11 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE bank_transactions_2024_12 PARTITION OF bank_transactions
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

-- 2025
CREATE TABLE bank_transactions_2025_01 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE bank_transactions_2025_02 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE bank_transactions_2025_03 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE bank_transactions_2025_04 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE bank_transactions_2025_05 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE bank_transactions_2025_06 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE bank_transactions_2025_07 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
CREATE TABLE bank_transactions_2025_08 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE bank_transactions_2025_09 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE bank_transactions_2025_10 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE bank_transactions_2025_11 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE bank_transactions_2025_12 PARTITION OF bank_transactions
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- 2026
CREATE TABLE bank_transactions_2026_01 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE bank_transactions_2026_02 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE bank_transactions_2026_03 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE bank_transactions_2026_04 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE bank_transactions_2026_05 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE bank_transactions_2026_06 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE bank_transactions_2026_07 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE bank_transactions_2026_08 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE bank_transactions_2026_09 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE bank_transactions_2026_10 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE bank_transactions_2026_11 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE bank_transactions_2026_12 PARTITION OF bank_transactions
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- ─── Passo 4: Índices locais por partição ───────────────────────────────
-- (Criados automaticamente em cada partição pelo PostgreSQL)

-- Índice composto para queries multi-tenant otimizadas
CREATE INDEX idx_bank_tx_org_occurred
    ON bank_transactions (organization_id, occurred_at DESC);

-- Índice para reconciliação por ID externo
CREATE INDEX idx_bank_tx_external_id
    ON bank_transactions (external_id)
    WHERE external_id IS NOT NULL;

-- Índice para busca por conta bancária
CREATE INDEX idx_bank_tx_account
    ON bank_transactions (bank_account_id, occurred_at DESC);

-- ─── Passo 5: Migrar dados da tabela antiga ─────────────────────────────
INSERT INTO bank_transactions
    SELECT * FROM bank_transactions_old;

-- ─── Passo 6: Remover tabela original após validação ────────────────────
-- CUIDADO: Executar SOMENTE após validar que a migração está ok
-- DROP TABLE bank_transactions_old;

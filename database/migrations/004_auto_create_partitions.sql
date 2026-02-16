-- ═══════════════════════════════════════════════════════════════════════════
-- ContaFacilit — Criação Automática de Partições Futuras
-- Executar mensalmente via cron ou pg_cron
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION create_monthly_partitions(
    p_table_name TEXT,
    p_months_ahead INTEGER DEFAULT 3
)
RETURNS VOID AS $$
DECLARE
    v_start_date    DATE;
    v_end_date      DATE;
    v_partition_name TEXT;
    v_month         INTEGER;
BEGIN
    FOR v_month IN 0..p_months_ahead LOOP
        v_start_date := date_trunc('month', now() + (v_month || ' months')::INTERVAL);
        v_end_date   := v_start_date + INTERVAL '1 month';
        v_partition_name := p_table_name || '_' || to_char(v_start_date, 'YYYY_MM');

        -- Verifica se a partição já existe
        IF NOT EXISTS (
            SELECT 1 FROM pg_class WHERE relname = v_partition_name
        ) THEN
            EXECUTE format(
                'CREATE TABLE %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
                v_partition_name,
                p_table_name,
                v_start_date::TEXT,
                v_end_date::TEXT
            );
            RAISE NOTICE 'Partição criada: %', v_partition_name;
        ELSE
            RAISE NOTICE 'Partição já existe: %', v_partition_name;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ─── Uso Imediato ─────────────────────────────────────────────────────────
-- Cria partições para os próximos 6 meses automaticamente
SELECT create_monthly_partitions('bank_transactions', 6);

-- ─── Schedule via pg_cron (se disponível no RDS) ──────────────────────────
-- SELECT cron.schedule(
--     'create-partitions-monthly',
--     '0 0 1 * *',  -- Dia 1 de cada mês à meia-noite
--     $$SELECT create_monthly_partitions('bank_transactions', 3)$$
-- );

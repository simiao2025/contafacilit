#!/bin/bash

# ──────────────────────────────────────────────────────────────────────────────
# ContaFacilit — RDS Disaster Recovery Restore Script
# Uso: ./rds-restore.sh <environment> <point_in_time>
# Exemplo: ./rds-restore.sh prod "2026-02-16T12:00:00Z"
# ──────────────────────────────────────────────────────────────────────────────

ENV=$1
RESTORE_TIME=$2
PROJECT="contafacilit"
SOURCE_DB="${PROJECT}-${ENV}"
TARGET_DB="${SOURCE_DB}-restored-$(date +%Y%m%d%H%M)"

if [ -z "$ENV" ] || [ -z "$RESTORE_TIME" ]; then
    echo "Erro: Faltam parâmetros. Uso: ./rds-restore.sh <env> <timestamp_iso>"
    exit 1
fi

echo "🚀 Iniciando restauração Point-in-Time para $ENV..."
echo "📅 Ponto de restauração: $RESTORE_TIME"
echo "📦 Origem: $SOURCE_DB"
echo "🛠️ Destino: $TARGET_DB"

# Comando de Restore
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier "$SOURCE_DB" \
    --target-db-instance-identifier "$TARGET_DB" \
    --restore-time "$RESTORE_TIME" \
    --publicly-accessible false \
    --multi-az true

if [ $? -eq 0 ]; then
    echo "✅ Solicitação de restauração enviada com sucesso!"
    echo "⏳ Acompanhe o progresso no console AWS ou via: aws rds describe-db-instances --db-instance-identifier $TARGET_DB"
else
    echo "❌ Falha ao iniciar restauração."
    exit 1
fi

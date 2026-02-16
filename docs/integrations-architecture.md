# ContaFacilit — Arquitetura de Integrações e Webhooks

> **Versão:** 1.0  
> **Status:** Design de Engenharia Finalizado  
> **Estratégia:** Event-Driven + Provider Pattern

---

## 1. Visão Geral

O módulo de integrações é responsável por conectar a ContaFacilit com fontes externas de dados financeiros e de vendas. Ele foi projetado para ser resiliente a falhas de terceiros e escalável para processar grandes volumes de webhooks simultâneos.

---

## 2. Arquitetura de Webhooks (Event-Driven)

Para garantir que não percamos dados de vendas ou eventos bancários durante picos de tráfego, utilizamos uma arquitetura de fila.

### Fluxo de Ingestão:
1.  **Recepção (API Gateway/ALB):** O endpoint `/integrations/webhooks/:provider` recebe a requisição (POST).
2.  **Validação Rápida:** O sistema valida a assinatura do webhook (HMAC/Shared Secret) para garantir a autenticidade.
3.  **Enfileiramento (AWS SQS):** O payload bruto é enviado para a fila `sqs-events-queue`. A API responde `202 Accepted` imediatamente em < 100ms.
4.  **Processamento (IA/Worker):** O Worker consome a mensagem da fila, identifica o tenant (`organization_id`) e processa a lógica de negócio (ex: criar uma `Revenue`).

---

## 3. Padrão Provider (Abstração)

Implementamos uma interface comum para todos os provedores, facilitando a adição de novas integrações sem alterar o núcleo do sistema.

```typescript
interface IntegrationProvider {
  name: string;
  syncTransactions(params: SyncParams): Promise<SyncResult>;
  validateWebhook(payload: any, signature: string): boolean;
  parseWebhook(payload: any): NormalizedEvent;
}
```

### Provedores Planejados:
- **Banking (Pluggy/Belvo):** Open Finance para captura de extratos e saldos.
- **Vendas (Hotmart/Kiwify):** Captura automática de vendas digitais e reembolsos.
- **Payments (Stripe):** Integração com checkout e assinaturas.

---

## 4. Reconciliação Automática

O motor de reconciliação atua comparando dois fluxos de dados:
1.  **Fluxo de Vendas (Integrations):** O que a plataforma diz que vendeu.
2.  **Fluxo de Caixa (Bank Transactions):** O que efetivamente caiu na conta bancária.

**Lógica de Match:**
- Critérios: `valor` (líquido de taxas), `data` (considerando prazo de antecipação) e `identificador de venda` (se disponível no extrato).
- Status de Reconciliação: `PENDING`, `RECONCILED`, `DISCREPANCY`.

---

## 5. Segurança e Armazenamento

- **Credentials Vault:** Todos os tokens de API são criptografados via **AES-256-GCM** (conforme Fase 4) antes de serem salvos no banco de dados.
- **HMAC Validation:** Todo webhook deve ser validado contra o segredo compartilhado configurado na integração.

---

## 6. Escalabilidade e Limites

- **Backpressure:** O uso de SQS protege o banco de dados de sobrecarga em lançamentos de grandes infoprodutores.
- **Idempotência:** Todo processamento de webhook verifica o `external_id` (ID da transação na origem) para evitar duplicidade de lançamentos fiscais.

---

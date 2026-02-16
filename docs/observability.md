# ContaFacilit — Estratégia de Observabilidade e Confiabilidade

> **Versão:** 1.0  
> **Status:** Design de Engenharia Finalizado  
> **Pilares:** Logs, Métricas, Tracing e Incident Response

---

## 1. Logs Estruturados (Logging)

Para sistemas financeiros, logs textuais simples são insuficientes. Adotamos **Logs Estruturados em JSON** para facilitar a análise automatizada.

- **Standard:** Cada log deve conter `timestamp`, `level`, `context`, `organization_id`, `user_id` e `trace_id`.
- **Ferramenta:** Winston (Backend) enviando logs para o **AWS CloudWatch** (Staging/Prod).
- **Segurança:** Filtros automáticos (Sanitizers) para mascarar CPFs, CNPJs e números de cartão de crédito.

```json
{
  "timestamp": "2026-02-16T13:30:13Z",
  "level": "info",
  "message": "Tax calculation finalized",
  "org_id": "uuid",
  "trace_id": "req-123",
  "metadata": { "competencia": "2026-01", "amount": 1250.00 }
}
```

---

## 2. Métricas de Performance (Metrics)

Monitoramos a saúde do sistema através dos **Golden Signals**:

1.  **Latency:** Tempo médio de resposta por endpoint (P95 < 500ms).
2.  **Traffic:** Requisições por segundo (RPS).
3.  **Errors:** Taxa de erro (4xx e 5xx). Alerta imediato se 5xx > 1% em 5 min.
4.  **Saturation:** CPU/Memória dos containers Fargate e profundidade da fila SQS.

---

## 3. Tracing Distribuído (Distributed Tracing)

Implementamos o rastreamento de requisições que cruzam diferentes serviços (API -> Worker -> IA Agent).

- **Trace ID:** Gerado no middleware da API e propagado via headers HTTP e atributos de mensagem SQS.
- **Visualização:** CloudWatch ServiceLens ou integração com OpenTelemetry (OTel).

---

## 4. Alertas Automáticos

Alertas críticos enviados via **Slack/PagerDuty** baseados em métricas do CloudWatch:

| Alerta | Gatilho | Severidade |
| :--- | :--- | :--- |
| **API Down** | Taxa de erro 5xx > 5% | Crítica |
| **DB Latency** | DB Query Time > 1s | Alta |
| **SQS Backlog** | IA Jobs Age > 10 min | Média |
| **Security Breach** | Token Reuse > 0 | Crítica |

---

## 5. Plano de Resposta a Incidentes (Incident Response)

### Fluxo de Escalação:
1.  **Detecção:** Alerta automático no Slack.
2.  **Triagem:** Engenheiro On-call verifica se o impacto é global ou por tenant.
3.  **Remediação:** Aplicação de SRE Playbooks (ex: rollback, flush de cache, escala horizontal).
4.  **Post-mortem:** Documentação da causa raiz (RCA) e plano de prevenção.

---

## 6. Teste de Carga (Stress Testing)

Utilizamos o **k6** para simular cenários reais:
- **Baseline:** 1.000 usuários simultâneos navegando.
- **Peak:** 5.000 usuários consultando impostos simultaneamente.
- **Goal:** Garantir latência < 1s no P99 durante picos.

---

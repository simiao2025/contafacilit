# ContaFacilit — Arquitetura de Inteligência Artificial Especializada

> **Versão:** 1.0  
> **Status:** Design de Engenharia Finalizado  
> **Tecnologias:** OpenAI + pgvector + RAG (Retrieval-Augmented Generation)

---

## 1. Visão Geral

O Agente de IA da ContaFacilit foi projetado para ser um assistente financeiro e contábil "zero-leak", garantindo que as informações de uma organização nunca sejam acessíveis por outra. Ele utiliza a técnica de **RAG** para consultar dados reais do cliente (extratos, receitas, impostos) e fornecer respostas precisas e contextualizadas.

---

## 2. Arquitetura de Dados (pgvector)

Toda a memória semântica e documentos da organização são armazenados com **embeddings** (vetores numéricos) no PostgreSQL utilizando a extensão `pgvector`.

### 2.1 Isolamento Multi-tenant
Cada entrada de mensagem ou documento no banco de dados possui obrigatoriamente a coluna `organization_id`.
- **Pesquisa Semântica:** A consulta SQL para busca de similaridade inclui sempre o filtro:
  `WHERE organization_id = $1 AND deleted_at IS NULL`
- **Garantia:** O banco de dados e a camada de serviço (NestJS) impõem essa restrição em todas as chamadas ao `pgvector`.

---

## 3. Fluxo de Consulta (Request/Response)

### Passo a Passo:
1.  **Entrada:** Usuário envia uma pergunta.
2.  **Embedding:** O sistema gera o vetor da pergunta via OpenAI (`text-embedding-3-small`).
3.  **Retrieval (RAG):**
    - Busca no banco os Top 5 fragmentos mais similares filtrados pelo `organization_id`.
    - Recupera o histórico recente da conversa (`ai_conversations` + `ai_messages`).
4.  **Prompt Construction:**
    - Monta o context window com: System Prompt (Instruções), Contexto Local (Dados recuperados) e Histórico.
5.  **Generation:** OpenAI (`gpt-4-turbo` ou `gpt-3.5-turbo`) gera a resposta.
6.  **Saída & Auditoria:** A resposta é retornada ao usuário e logada em `audit_logs` para rastreabilidade de custo e segurança.

---

## 4. Segurança e Privacidade

### 4.1 Proteção contra Privilege Escalation
O Agente respeita o RBAC:
- Se um usuário tem role `COLABORADOR`, o Agente não responderá perguntas sobre dados sensíveis de faturamento estratégico que o usuário não teria acesso no dashboard.

### 4.2 Sanitização de Dados (Data Leakage)
- Filtros de saída evitam que o modelo exponha segredos de sistema ou dados de outros tenants caso ocorra uma falha catastrófica no Prompt.
- **System Prompt Rígido:** Instruído explicitamente a nunca "quebrar" o isolamento de tenant.

---

## 5. Auditoria e Custos

Cada interação gera um registro detalhado:
- `user_id` e `organization_id`.
- `tokens_used` (Prompt + Completion).
- `latency_ms`.
- `event: AI_QUERY_PROCESSED`.

---

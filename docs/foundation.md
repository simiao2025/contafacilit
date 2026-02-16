# ContaFacilit — Project Foundation (Fase 0 - Atualizado)

> **Versão:** 2.0  
> **Data:** 2026-02-16  
> **Status:** Finalizado (Pronto para Versionamento)  
> **Especialidade:** SaaS Fiscal Multi-tenant & Automação Contábil

---

## 1. Visão Geral do Produto

O **ContaFacilit** evoluiu de um simples motor de cálculo para uma **Plataforma de Contabilidade Digital Automatizada**. O objetivo é eliminar a fricção entre o faturamento no marketing digital (Hotmart, Kiwify, Eduzz, Amazon, etc.) e o cumprimento das obrigações acessórias do **Simples Nacional**.

A plataforma atua como o "Cérebro Fiscal" do empreendedor digital, integrando fluxos financeiros, bancários e tributários em um ambiente isolado (multi-tenant) e escalável.

---

## 2. Pilares de Arquitetura & Funcionalidades

### 2.1 Integração Bancária e de Plataformas
- **Bancária (Open Finance):** Conectividade via APIs (Pluggy/Belvo) para conciliação automática de entradas e saídas.
- **Plataformas Digitais:** Webhooks e APIs nativas para captura de vendas em tempo real, tratando reembolsos e chargebacks automaticamente.

### 2.2 Motor Tributário (Simples Nacional)
- Cálculo automatizado de RBT12, Alíquota Efetiva e Fator R.
- Segregação de receitas (Anexos I, II, III, IV e V).
- Emissão automatizada de guias DAS (via integração com e-CAC/RFB).

### 2.3 Agente IA para Atendimento
- Suporte técnico e contábil Nível 1 via LLM treinado nas normas da Receita Federal.
- Consultoria preventiva: alerta o usuário sobre proximidade de exclusão do Simples por faturamento.

---

## 3. Modelo Operacional & Responsabilidade

### 3.1 Responsabilidade Legal
- **Plataforma:** Atua como provedora de tecnologia e automação. Não substitui a responsabilidade técnica do Contador (CRC) nas obrigações que exigem assinatura profissional, mas automatiza a geração das memórias de cálculo.
- **Contribuinte:** Responsável pela veracidade dos dados importados e pelo pagamento tempestivo das guias geradas.

### 3.2 Governança de Dados & LGPD
- **Finalidade:** Processamento estritamente para fins fiscais e contábeis.
- **Segurança:** Isolamento lógico via `organization_id` (RLS), criptografia AES-256 para tokens de integração e Logs de Auditoria imutáveis.
- **Diretos do Titular:** Implementação de fluxos automáticos para exportação e exclusão de dados pessoais (Direito ao Esquecimento).

---

## 4. Roadmap de Produto (V1, V2, V3)

### **V1: Core & Automação Inicial (MVP+)**
- Cadastro Multi-tenant e RBAC.
- Motor de Cálculo Simples Nacional (Anexos III e V).
- Importação via Planilha (CSV) e Integração Webhook (Vendas).
- Dashboard de Faturamento Acumulado.
- Relatório de Memória de Cálculo.

### **V2: Integração & IA (Escalabilidade)**
- Integração Open Finance (Extratos Bancários).
- Agente IA de Atendimento Nível 1.
- Automação de Emissão de Nota Fiscal de Serviço (NFS-e) para as principais prefeituras.
- Monitoramento do e-CAC automático.

### **V3: Ecossistema & Inteligência (Advanced)**
- Marketplace de Serviços Contábeis Premium.
- Planejamento Tributário Preditivo (Simulações de mudança para Lucro Presumido).
- Integração com Folha de Pagamento (Pró-labore automatizado para Fator R).
- Expansão para Anexos I e II.

---

## 5. Riscos Regulatórios & Mitigação

| Risco | Descrição | Mitigação |
|---|---|---|
| **Mudança Legislativa** | Alteração nas faixas do Simples ou Reforma Tributária. | Motor tributário desacoplado; tabelas parametrizadas no banco de dados. |
| **Instabilidade Governo** | Queda do portal e-CAC ou APIs da Receita. | Fila de processamento (Sidekiq/BullMQ) com retry exponencial. |
| **Erros de Interpretação** | IA dando conselhos contábeis errôneos. | IA limitada a documentos oficiais da RFB com disclaimer claro; supervisão humana se necessário. |

---

## 6. Governança de Dados (MT & 10k Clientes)

- **Escalabilidade:** Arquitetura baseada em ECS Fargate com auto-scaling e Aurora PostgreSQL para alta disponibilidade.
- **Multi-tenancy:** Uso rigoroso de Row-Level Security (RLS) no banco de dados.
- **Backup:** PITR (Point-in-Time Recovery) de 35 dias e DR (Disaster Recovery) cross-region.

---

## 7. Histórico de Versões

| Versão | Data | Descrição |
|---|---|---|
| 1.0 | 2026-02-16 | Versão inicial (Calculadora de Impostos). |
| 2.0 | 2026-02-16 | Redefinição para Plataforma de Contabilidade Digital Automatizada. |

---

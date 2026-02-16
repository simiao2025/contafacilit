# ContaFacilit — Foundation Document

> **Versão:** 1.0  
> **Data:** 2026-02-16  
> **Autor:** Product Management  
> **Status:** Draft  

---

## 1. Problema

Profissionais do marketing digital — infoprodutores, afiliados, gestores de tráfego e agências — enfrentam dificuldades significativas para manter a conformidade fiscal com o Simples Nacional. A grande maioria não possui formação contábil e depende de contadores externos que, frequentemente, não compreendem a dinâmica de receitas variáveis e multi-fonte típicas do mercado digital.

**Dores identificadas:**

- **Complexidade tributária:** O cálculo do Simples Nacional envolve faixas progressivas, alíquotas efetivas e deduções que variam mês a mês conforme o faturamento acumulado dos últimos 12 meses (RBT12).
- **Dados fragmentados:** Receitas chegam de múltiplas plataformas (Hotmart, Kiwify, Eduzz, Google Ads Manager, Meta Ads) em formatos diferentes, dificultando a consolidação.
- **Custo e atraso:** Contadores tradicionais cobram valores elevados e não entregam visibilidade em tempo real sobre a situação fiscal.
- **Risco de multas:** Erros ou atrasos no recolhimento do DAS geram multas e juros que impactam diretamente a margem de lucro.

---

## 2. Público-Alvo

| Persona | Descrição | Necessidade Principal |
|---|---|---|
| **Infoprodutor** | Criador de cursos, e-books e mentorias que vende através de plataformas digitais. Faturamento mensal de R$ 5k a R$ 200k. | Saber exatamente quanto de imposto pagar cada mês sem depender do contador. |
| **Afiliado** | Profissional que promove produtos de terceiros e recebe comissões. Receitas variáveis e multi-fonte. | Consolidar receitas de diversas plataformas e calcular o DAS corretamente. |
| **Gestor de Tráfego** | Especialista em mídia paga que presta serviço como PJ. Emite notas para múltiplos clientes. | Controlar o faturamento acumulado para não estourar o teto do Simples Nacional. |
| **Agência Digital** | Empresa com equipe que atende múltiplos clientes. Faturamento mais complexo com múltiplos anexos do Simples. | Dashboard consolidado com visão gerencial de obrigações fiscais. |

**Características comuns:**
- Alta afinidade com tecnologia
- Preferência por soluções self-service e automatizadas
- Baixa tolerância a interfaces complexas ou burocráticas
- Valorizam velocidade e clareza na informação

---

## 3. Proposta de Valor

> **Calcule seu Simples Nacional em minutos, não em dias.**

O ContaFacilit é uma plataforma web que permite a profissionais do marketing digital calcular automaticamente os impostos do Simples Nacional a partir do upload de extratos de receitas, eliminando planilhas manuais e reduzindo a dependência de contadores para tarefas operacionais.

**Diferenciais:**

1. **Cálculo automático e preciso** — Motor de cálculo atualizado com as tabelas vigentes do Simples Nacional, considerando RBT12, faixas, alíquotas efetivas e deduções por anexo.
2. **Upload simples** — Importação de receitas via CSV, sem necessidade de integração técnica na V1.
3. **Dashboard intuitivo** — Visão clara do faturamento mensal, imposto devido, histórico e projeções.
4. **Relatório PDF mensal** — Documento pronto para enviar ao contador ou arquivar, com memória de cálculo detalhada.
5. **Preço acessível** — Modelo SaaS com mensalidade acessível ao profissional individual.

---

## 4. Escopo V1

### 4.1 Funcionalidades Incluídas

| # | Funcionalidade | Descrição |
|---|---|---|
| F1 | **Cadastro de Empresa** | Registro de dados da empresa (CNPJ, razão social, regime tributário, anexo do Simples Nacional, data de abertura). |
| F2 | **Upload de Receitas (CSV)** | Importação de arquivo CSV com colunas padronizadas (data, descrição, valor, origem). Validação de formato e feedback de erros. |
| F3 | **Cálculo do Simples Nacional** | Motor de cálculo que aplica as regras do Simples Nacional: RBT12, faixa de faturamento, alíquota nominal, parcela a deduzir e alíquota efetiva. Suporte aos Anexos I a V. |
| F4 | **Dashboard** | Painel principal com: faturamento do mês, imposto estimado (DAS), faturamento acumulado 12 meses, gráfico de evolução, alertas de proximidade do teto. |
| F5 | **Relatório PDF Mensal** | Geração de PDF com memória de cálculo, detalhamento das receitas, alíquota aplicada e valor do DAS. Download e histórico de relatórios gerados. |
| F6 | **Autenticação e Multi-tenancy** | Login seguro (e-mail + senha), recuperação de senha. Isolamento de dados por `organization_id` em modelo shared database. |

### 4.2 Requisitos Não-Funcionais

| Requisito | Meta |
|---|---|
| **Disponibilidade** | 99,5% uptime mensal |
| **Performance** | Cálculo concluído em < 3 segundos para até 5.000 linhas de CSV |
| **Segurança** | Dados criptografados em trânsito (TLS) e em repouso. Conformidade com LGPD. |
| **Escalabilidade** | Arquitetura preparada para suportar 10.000 clientes simultâneos |
| **Multi-tenancy** | Shared database com isolamento por `organization_id` em todas as tabelas |

---

## 5. Fora do Escopo (V1)

Os itens abaixo estão **explicitamente excluídos** da V1 e poderão ser avaliados em versões futuras:

| Item | Motivo da Exclusão |
|---|---|
| Emissão de Nota Fiscal (NF-e / NFS-e) | Complexidade regulatória e necessidade de certificado digital A1. Requer integração com prefeituras e SEFAZ. |
| Integração automática com plataformas (Hotmart, Kiwify, Eduzz, etc.) | Reduz escopo técnico da V1. O upload CSV cobre a necessidade de forma suficiente. |
| Aplicativo mobile (iOS / Android) | A plataforma web responsiva atende o MVP. Mobile será priorizado com base em dados de uso. |
| Cálculo de outros regimes (Lucro Presumido, MEI) | Foco exclusivo no Simples Nacional na V1 para garantir precisão e qualidade. |
| Gestão de funcionários / folha de pagamento | Fora do core do produto. |
| Chat com contador / marketplace de contadores | Feature de relacionamento que será avaliada pós-tração. |

---

## 6. Métricas de Sucesso

### 6.1 Métricas de Produto

| Métrica | Meta (6 meses pós-lançamento) | Instrumento |
|---|---|---|
| **Usuários cadastrados** | 2.000 | Analytics |
| **Clientes pagantes (MRR)** | 500 | Billing system |
| **Taxa de conversão (free → paid)** | ≥ 15% | Analytics |
| **Retenção mensal (M1)** | ≥ 70% | Cohort analysis |
| **NPS** | ≥ 50 | Pesquisa in-app |

### 6.2 Métricas Técnicas

| Métrica | Meta | Instrumento |
|---|---|---|
| **Uptime** | ≥ 99,5% | Monitoring (UptimeRobot / Datadog) |
| **Tempo médio de cálculo** | < 3s | APM |
| **Taxa de erro no cálculo** | < 0,1% | Testes automatizados + auditoria manual |
| **Tempo de upload CSV (p95)** | < 5s para 5.000 linhas | APM |

### 6.3 Métricas de Negócio

| Métrica | Meta (12 meses) | Instrumento |
|---|---|---|
| **MRR** | R$ 50.000 | Billing |
| **CAC** | < R$ 80 | Marketing analytics |
| **LTV / CAC** | ≥ 3:1 | Finance model |
| **Churn mensal** | < 5% | Billing |

---

## 7. Riscos Técnicos

| # | Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|---|
| R1 | **Atualização das tabelas do Simples Nacional** — Governo pode alterar faixas e alíquotas sem aviso prévio. | Média | Alto | Parametrizar tabelas de alíquotas no banco de dados (não hardcoded). Monitorar Diário Oficial e portais da Receita Federal. |
| R2 | **Isolamento de dados insuficiente no multi-tenant** — Falha no filtro por `organization_id` pode expor dados de outro cliente. | Baixa | Crítico | Row-Level Security (RLS) no PostgreSQL. Testes automatizados de isolamento. Code review obrigatório em queries. |
| R3 | **Parsing de CSV inconsistente** — Plataformas geram CSVs com formatos variados (separadores, encoding, layout de colunas). | Alta | Médio | Definir template padrão de CSV. Validação robusta com feedback de erros claros. Templates de exemplo por plataforma. |
| R4 | **Performance sob carga** — Cálculo de RBT12 com muitas transações pode ser lento em escala. | Média | Médio | Cache do faturamento acumulado. Processamento assíncrono para uploads grandes. Testes de carga antes do lançamento. |
| R5 | **Conformidade com LGPD** — Tratamento inadequado de dados fiscais sensíveis. | Média | Alto | Política de privacidade, criptografia de dados sensíveis, auditoria de acessos, procedimento de exclusão de dados. |
| R6 | **Erros de cálculo fiscal** — Bugs no motor de cálculo podem gerar valores incorretos de DAS. | Média | Crítico | Suite de testes com cenários reais validados por contador. Testes de regressão automatizados. Disclaimer legal na plataforma. |

---

## 8. Premissas

1. **Regime tributário:** A V1 atende exclusivamente empresas optantes pelo Simples Nacional. Outros regimes estão fora do escopo.

2. **Formato de dados:** Os usuários são capazes de exportar suas receitas em formato CSV a partir das plataformas que utilizam (Hotmart, Kiwify, Eduzz, etc.). A plataforma fornecerá templates e documentação de apoio.

3. **Responsabilidade fiscal:** A plataforma é uma ferramenta de apoio ao cálculo. A responsabilidade legal pelo recolhimento correto dos tributos permanece com o contribuinte e seu contador. Um disclaimer jurídico será exibido claramente.

4. **Infraestrutura cloud:** A aplicação será hospedada em cloud provider (AWS, GCP ou similar), utilizando PostgreSQL como banco de dados relacional.

5. **Multi-tenancy:** O modelo de shared database com `organization_id` é suficiente para a meta inicial de 10.000 clientes. A migração para database-per-tenant será avaliada se a base ultrapassar 50.000 clientes.

6. **Equipe mínima:** O desenvolvimento da V1 será conduzido por uma equipe enxuta (2-3 engenheiros + 1 designer), com ciclo de entrega de 8 a 12 semanas.

7. **Tabelas do Simples Nacional:** As tabelas de alíquotas vigentes em 2026 (Lei Complementar 123/2006 e atualizações) serão utilizadas como base. A plataforma será projetada para acomodar atualizações futuras sem deploy de código.

8. **Monetização:** Modelo freemium com funcionalidades básicas gratuitas e plano pago para cálculo completo, relatórios PDF e histórico ilimitado. Pricing a ser definido com base em pesquisa de mercado.

---

## Histórico de Versões

| Versão | Data | Autor | Descrição |
|---|---|---|---|
| 1.0 | 2026-02-16 | Product Management | Versão inicial do Foundation Document |

---

> **Próximos passos:** Após aprovação deste documento, iniciar a fase de Discovery técnico com definição de arquitetura, modelagem de dados e prototipação de telas (wireframes).

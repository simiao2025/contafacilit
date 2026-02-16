# ContaFacilit — Motor de Cálculo Tributário (Simples Nacional)

> **Versão:** 1.0  
> **Status:** Especificação Técnica  
> **Escopo:** Autônomos e Pequenas Empresas (Anexos III e V)

---

## 1. Regras de Negócio (Brasil)

O motor implementa o cálculo do Simples Nacional com base na Receita Bruta Acumulada nos últimos 12 meses (RBT12) e a aplicação do **Fator R**.

### 1.1 RBT12 (Sliding Window)
O cálculo segue a fórmula:
- `RBT12 = Soma das receitas brutas dos 12 meses anteriores ao período de apuração.`
- Independente de o mês ter sido calculado ou não, a soma busca na tabela `revenues` os registros com `deleted_at IS NULL`.

### 1.2 Fator R
O Fator R determina se uma empresa de serviços será tributada pelo Anexo III (mais barato) ou Anexo V (mais caro).
- `Fator R = Folha de Salários (12 meses) / Receita Bruta (12 meses)`
- **Regra:**
  - Se `Fator R >= 0.28 (28%)` → Tributação pelo **Anexo III**.
  - Se `Fator R < 0.28 (28%)` → Tributação pelo **Anexo V**.

---

## 2. Tabelas de Alíquotas (Simples Nacional 2024-2026)

O sistema utiliza o versionamento via `motor_versions.config`. Estrutura base:

### Anexo III (Serviços - TI, Engenharia, etc. com Fator R)
| Faixa | RBT12 (R$) | Alíquota Nominal | Parcela a Deduzir (R$) |
| :--- | :--- | :--- | :--- |
| 1ª | Até 180.000,00 | 6,00% | 0 |
| 2ª | 180.000,01 a 360.000,00 | 11,20% | 9.360,00 |
| 3ª | 360.000,01 a 720.000,00 | 13,50% | 17.640,00 |
| 4ª | 720.000,01 a 1.800.000,00 | 16,00% | 35.640,00 |
| 5ª | 1.800.000,01 a 3.600.000,00 | 21,00% | 125.640,00 |
| 6ª | 3.600.000,01 a 4.800.000,00 | 33,00% | 648.000,00 |

### Anexo V (Serviços sem Fator R)
| Faixa | RBT12 (R$) | Alíquota Nominal | Parcela a Deduzir (R$) |
| :--- | :--- | :--- | :--- |
| 1ª | Até 180.000,00 | 15,50% | 0 |
| 2ª | 180.000,01 a 360.000,00 | 18,00% | 4.500,00 |
| 3ª | 360.000,01 a 720.000,00 | 19,50% | 9.900,00 |
| 4ª | 720.000,01 a 1.800.000,00 | 20,50% | 17.100,00 |
| 5ª | 1.800.000,01 a 3.600.000,00 | 23,00% | 62.100,00 |
| 6ª | 3.600.000,01 a 4.800.000,00 | 30,50% | 540.000,00 |

---

## 3. Algoritmo de Cálculo (Determinístico)

1.  **Input:** `ReceitaMês`, `RBT12`, `Folha12`.
2.  **Passo 1:** Calcular Fator R.
3.  **Passo 2:** Escolher Anexo (III se Fator R >= 28%, senão V).
4.  **Passo 3:** Identificar a Faixa com base no RBT12.
5.  **Passo 4:** Aplicar Alíquota Efetiva:
    - `Alíquota Efetiva = (RBT12 * AlíquotaNominal - ParcelaDeduzir) / RBT12`
6.  **Passo 5:** Calcular Valor do Imposto:
    - `Valor DAS = ReceitaMês * AlíquotaEfetiva`

---

## 4. Garantia de Determinismo

- O motor é uma **Pure Function**: Dado o mesmo input e regras de versão, o output será idêntico (independente de horário ou UTC).
- Arredondamentos seguem a norma da Receita Federal (duas casas decimais, padrão contábil).

---

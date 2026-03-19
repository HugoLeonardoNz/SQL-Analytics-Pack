# 📡 SQL Analytics Pack — FiberNet ISP

<div align="center">

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14%2B-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Window%20Functions%20%7C%20CTEs-orange?style=for-the-badge)
![Domain](https://img.shields.io/badge/Domain-Telecom%20%2F%20ISP-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completo-brightgreen?style=for-the-badge)

**10 queries analíticas aplicadas a um ISP fictício (FiberNet).**  
Churn, cohort, inadimplência aging, ranking de vendedores e crescimento de MRR com Window Functions, CTEs e PostgreSQL 14+.

[▶ Ver Queries](#-queries) · [📊 Ver Insights](insights/resumo_resultados.md) · [🚀 Rodar Localmente](#-como-rodar)

</div>

---

## 🎯 Contexto de Negócio

A **FiberNet** é um ISP fictício baseado em estrutura real de provedor de internet por fibra óptica.
Os dados são sintéticos, mas refletem desafios reais do setor:

- **Alta rotatividade** em planos básicos vs. baixo churn em planos premium
- **Inadimplência acumulada** difícil de recuperar após 90 dias
- **Concentração geográfica** de receita em poucas cidades
- **Qualidade de carteira** que varia por vendedor mesmo com volumes similares

---

## 📁 Estrutura do Projeto

```
sql-analytics-pack/
│
├── README.md
├── datasets/
│   ├── schema.sql             ← estrutura das 7 tabelas (sem dados reais)
│   └── seed.sql               ← 300 clientes + 4.241 boletos + 220 tickets
├── queries/
│   ├── 01_receita_por_cidade.sql
│   ├── 02_churn_por_plano.sql
│   ├── 03_cohort_clientes.sql
│   ├── 04_ranking_vendedores.sql
│   ├── 05_inadimplencia_aging.sql
│   ├── 06_ticket_medio_por_plano.sql
│   ├── 07_crescimento_mensal.sql
│   ├── 08_clientes_em_risco.sql
│   ├── 09_tempo_medio_cancelamento.sql
│   └── 10_top_cidades_churn.sql
└── insights/
    └── resumo_resultados.md   ← resultados verificados com o seed
```

---

## 🔍 Queries

| # | Query | Técnicas SQL | Pergunta de Negócio |
|---|-------|-------------|---------------------|
| 01 | [receita_por_cidade](queries/01_receita_por_cidade.sql) | `SUM`, `AVG`, Window `OVER()` | Onde está concentrada a receita? |
| 02 | [churn_por_plano](queries/02_churn_por_plano.sql) | `FILTER`, `NULLIF`, CTE | Planos baratos têm mais evasão? |
| 03 | [cohort_clientes](queries/03_cohort_clientes.sql) | `DATE_TRUNC`, `TO_CHAR`, CTE | Clientes de qual trimestre retêm mais? |
| 04 | [ranking_vendedores](queries/04_ranking_vendedores.sql) | `DENSE_RANK`, múltiplos `FILTER` | Quem vende mais *e* melhor? |
| 05 | [inadimplencia_aging](queries/05_inadimplencia_aging.sql) | `CASE WHEN`, CTE, `DATE` arith. | Quanto está em risco de não recuperar? |
| 06 | [ticket_medio_por_plano](queries/06_ticket_medio_por_plano.sql) | `EXTRACT`, `AGE`, LTV estimado | Qual plano gera mais valor por cliente? |
| 07 | [crescimento_mensal](queries/07_crescimento_mensal.sql) | `FULL OUTER JOIN`, `ROWS BETWEEN` | MRR crescendo ou contraindo? |
| 08 | [clientes_em_risco](queries/08_clientes_em_risco.sql) | Score composto, múltiplos CTEs | Quem priorizar na retenção? |
| 09 | [tempo_medio_cancelamento](queries/09_tempo_medio_cancelamento.sql) | `MODE()`, `EXTRACT`, medidas stat. | Quando o cliente desiste? |
| 10 | [top_cidades_churn](queries/10_top_cidades_churn.sql) | `DENSE_RANK`, `FILTER`, múlt. agg. | Quais cidades exigem atenção operacional? |

---

## 📊 Principais Resultados

> Números verificados rodando as queries contra o `seed.sql`. Detalhes completos em [`insights/resumo_resultados.md`](insights/resumo_resultados.md).

### MRR por Cidade
| Cidade | Contratos Ativos | MRR | % Receita |
|--------|-----------------|-----|-----------|
| Betim | 63 | R$ 7.833,70 | 27,4% |
| Contagem | 54 | R$ 6.894,60 | 24,1% |
| Ribeirão das Neves | 50 | R$ 6.245,00 | 21,9% |
| Esmeraldas | 37 | R$ 4.456,30 | 15,6% |
| Ibirité | 23 | R$ 3.127,70 | 11,0% |

### Churn por Plano
| Plano | Mensalidade | Churn |
|-------|------------|-------|
| Fibra 100MB | R$ 89,90 | **36,7%** ⚠️ |
| Fibra 200MB | R$ 109,90 | 26,2% |
| Fibra 500MB | R$ 139,90 | 14,5% |
| Fibra 1GB | R$ 179,90 | **10,2%** ✅ |

> Clientes no plano básico cancelam **3,6× mais** que no plano premium.

### Aging de Inadimplência
| Faixa | Boletos | Valor em Aberto |
|-------|---------|-----------------|
| Até 30 dias | 23 | R$ 3.027,70 |
| 31–60 dias | 25 | R$ 3.007,50 |
| 61–90 dias | 26 | R$ 3.007,40 |
| **Acima de 90 dias** | **309** | **R$ 37.909,10** |

---

## 🚀 Como Rodar

### Pré-requisitos
- PostgreSQL 14+ instalado ([download](https://www.postgresql.org/download/))
- psql ou qualquer client SQL (DBeaver, TablePlus, DataGrip…)

```bash
# 1. Clone o repositório
git clone https://github.com/hugo-leonardo-a15066167/sql-analytics-pack.git
cd sql-analytics-pack

# 2. Crie o banco e carregue o schema
psql -U postgres -c "CREATE DATABASE fibernet;"
psql -U postgres -d fibernet -f datasets/schema.sql

# 3. Popule com os dados fictícios
psql -U postgres -d fibernet -f datasets/seed.sql

# 4. Execute qualquer query
psql -U postgres -d fibernet -f queries/02_churn_por_plano.sql
```

### 🌐 Sem PostgreSQL instalado?
Use o **[DB Fiddle](https://www.db-fiddle.com)** (selecione PostgreSQL 14):
1. Cole o conteúdo de `schema.sql` + `seed.sql` na aba **Schema SQL**
2. Cole a query desejada na aba **Query SQL**
3. Clique em **Run** — sem instalar nada

---

## 🧠 Técnicas Utilizadas

```sql
-- Window Functions
DENSE_RANK() OVER (ORDER BY receita_nova DESC)
SUM(...) OVER (ORDER BY mes ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

-- CTEs encadeadas
WITH overdue AS (...),
     classified AS (SELECT *, CASE WHEN ... END AS faixa FROM overdue)
SELECT ... FROM classified

-- Funções de agregação avançadas
MODE() WITHIN GROUP (ORDER BY motivo)
COUNT(*) FILTER (WHERE status = 'cancelled')
EXTRACT(MONTH FROM AGE(cancellation_date, start_date))

-- Joins e anti-joins
FULL OUTER JOIN para combinar MRR novo + cancelado por mês
LEFT JOIN para score de risco composto
```

---

## 👤 Autor

**Hugo Leonardo**  
Analista de Dados | SQL · Python · BI

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Hugo%20Leonardo-0077B5?style=flat&logo=linkedin)](https://www.linkedin.com/in/hugo-leonardo-a15066167/)

---

<div align="center">
<sub>Dados 100% fictícios gerados para fins de portfólio. Nenhuma informação real de clientes foi utilizada.</sub>
</div>

# SQL Analytics Pack — FiberNet ISP

<div align="center">

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14%2B-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Window%20Functions%20%7C%20CTEs%20%7C%20Aggregates-orange?style=for-the-badge)
![Domain](https://img.shields.io/badge/Domain-Telecom%20%2F%20ISP-0ea5e9?style=for-the-badge)
![Queries](https://img.shields.io/badge/Queries-10-6366f1?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completo-10b981?style=for-the-badge)
![CI](https://github.com/HugoLeonardoNz/SQL-Analytics-Pack/actions/workflows/dbt_ci.yml/badge.svg)

**10 queries analíticas aplicadas a um ISP fictício (FiberNet) com 300 clientes.**  
Churn por plano, cohort de retenção, aging de inadimplência, scoring de risco e crescimento de MRR — Window Functions, CTEs e PostgreSQL 14+.

[Ver Queries](#-queries) · [Ver Insights](analysis/findings.md) · [Como Rodar](#-como-rodar)

</div>

---

## Universo FiberNet — Escala Canônica

Os 3 projetos desta série representam a **mesma empresa fictícia** em granularidades complementares:

| Granularidade | Projetos | Escala | Abrangência |
|---|---|---|---|
| **Análise Regional** | SQL Analytics Pack · Churn Predictor | 300 contratos | Região Centro-MG: Betim, Contagem, Ribeirão das Neves, Esmeraldas, Ibirité |
| **Visão Operacional Nacional** | Telecom KPI Dashboard | ~82.500 clientes | 5 regiões nacionais (Norte, Sul, Leste, Oeste, Centro) |

A divergência de escala é **intencional**: o SQL Pack e o Churn Predictor mergulham numa amostra regional de alta granularidade para análise SQL profunda e modelagem preditiva. O KPI Dashboard consolida a operação completa para monitoramento em tempo real — os mesmos padrões de negócio (churn por plano, inadimplência, MRR), em escala nacional.

---

## Contexto de Negócio

A **FiberNet** é um ISP fictício baseado na estrutura real de um provedor de fibra óptica.  
O dataset é sintético, mas modela desafios genuínos do setor:

- **Alta rotatividade em planos básicos** — Fibra 100MB cancela 3,6× mais que o Fibra 1GB
- **Inadimplência de difícil recuperação** — 80,7% do saldo aberto já ultrapassa 90 dias
- **Concentração geográfica** — 3 cidades respondem por 73% do MRR total
- **Qualidade de carteira variável** — spread de 13pp de churn entre o melhor e o pior vendedor

---

## Estrutura

```
sql-analytics-pack/
│
├── README.md
├── data/
│   ├── schema.sql          ← 7 tabelas: clients, contracts, plans, sellers,
│   │                          financial_receivables, tickets, sales
│   └── seed.sql            ← 300 clientes · 4.241 boletos · 220 tickets (2022–2024)
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
└── analysis/
    └── findings.md         ← resultados verificados com o seed + interpretação de negócio
```

---

## Queries

| # | Arquivo | Técnicas SQL | Pergunta de Negócio |
|---|---------|--------------|---------------------|
| 01 | [receita_por_cidade](queries/01_receita_por_cidade.sql) | `SUM`, `AVG`, `OVER()` | Onde está concentrada a receita? |
| 02 | [churn_por_plano](queries/02_churn_por_plano.sql) | CTE, `FILTER`, `NULLIF` | Planos baratos têm mais evasão? |
| 03 | [cohort_clientes](queries/03_cohort_clientes.sql) | `DATE_TRUNC`, `TO_CHAR`, CTE | Qual coorte retém mais clientes? |
| 04 | [ranking_vendedores](queries/04_ranking_vendedores.sql) | `DENSE_RANK`, múltiplos `FILTER` | Quem vende mais *e* com melhor qualidade? |
| 05 | [inadimplencia_aging](queries/05_inadimplencia_aging.sql) | `CASE WHEN`, CTE, aritmética de datas | Quanto ainda dá para recuperar? |
| 06 | [ticket_medio_por_plano](queries/06_ticket_medio_por_plano.sql) | `EXTRACT`, `AGE`, LTV estimado | Qual plano gera mais valor por cliente? |
| 07 | [crescimento_mensal](queries/07_crescimento_mensal.sql) | `FULL OUTER JOIN`, `ROWS BETWEEN` | MRR crescendo ou contraindo? |
| 08 | [clientes_em_risco](queries/08_clientes_em_risco.sql) | Score composto, CTEs encadeadas | Quem priorizar na retenção? |
| 09 | [tempo_medio_cancelamento](queries/09_tempo_medio_cancelamento.sql) | `MODE()`, `EXTRACT`, estatísticas | Quando o cliente desiste? |
| 10 | [top_cidades_churn](queries/10_top_cidades_churn.sql) | `DENSE_RANK`, `FILTER`, múlt. agg. | Quais cidades exigem atenção operacional? |

---

## Principais Resultados

> Números verificados executando as queries contra `data/seed.sql`.  
> Interpretação completa em [`analysis/findings.md`](analysis/findings.md).

### Churn por Plano
| Plano | Mensalidade | Contratos | Churn |
|-------|-------------|-----------|-------|
| Fibra 100MB | R$ 89,90 | 98 | **36,7%** ⚠️ |
| Fibra 200MB | R$ 109,90 | 84 | 26,2% |
| Fibra 500MB | R$ 139,90 | 69 | 14,5% |
| Fibra 1GB | R$ 179,90 | 49 | **10,2%** ✅ |

> Clientes no plano básico cancelam **3,6× mais** que no premium. Upsell reduz churn e aumenta receita simultaneamente.

### MRR por Cidade
| Cidade | Contratos Ativos | MRR | % Receita |
|--------|-----------------|-----|-----------|
| Betim | 63 | R$ 7.833,70 | 27,4% |
| Contagem | 54 | R$ 6.894,60 | 24,1% |
| Ribeirão das Neves | 50 | R$ 6.245,00 | 21,9% |
| Esmeraldas | 37 | R$ 4.456,30 | 15,6% |
| Ibirité | 23 | R$ 3.127,70 | 11,0% |

### Aging de Inadimplência
| Faixa | Boletos | Valor em Aberto | Recuperabilidade |
|-------|---------|-----------------|-----------------|
| Até 30 dias | 23 | R$ 3.027,70 | Alta |
| 31–60 dias | 25 | R$ 3.007,50 | Média |
| 61–90 dias | 26 | R$ 3.007,40 | Baixa |
| **Acima de 90 dias** | **309** | **R$ 37.909,10** | Crítica |

### Resumo Executivo
| Métrica | Valor |
|---------|-------|
| MRR total ativo | R$ 28.557,30 |
| Clientes ativos | 227 / 300 (75,7%) |
| Churn rate médio | 24,3% |
| Contratos com sinal de risco | 174 (76,7% da base) |
| Melhor plano (LTV) | Fibra 500MB — R$ 2.553,77 |
| Cidade maior churn | Contagem (34,1%) |
| Inadimplência crítica (>90d) | R$ 37.909,10 |

---

## Como Rodar

**Pré-requisitos:** PostgreSQL 14+ e psql ou qualquer client SQL (DBeaver, TablePlus, DataGrip).

```bash
# Clone
git clone https://github.com/HugoLeonardoNz/SQL-Analytics-Pack.git
cd SQL-Analytics-Pack

# Crie o banco e carregue schema + dados
psql -U postgres -c "CREATE DATABASE fibernet;"
psql -U postgres -d fibernet -f data/schema.sql
psql -U postgres -d fibernet -f data/seed.sql

# Rode qualquer query
psql -U postgres -d fibernet -f queries/02_churn_por_plano.sql
```

**Sem PostgreSQL instalado?** Use o [DB Fiddle](https://www.db-fiddle.com) (PostgreSQL 14):
1. Cole `schema.sql` + `seed.sql` em **Schema SQL**
2. Cole a query em **Query SQL**
3. Clique em **Run** — sem instalar nada

---

## Técnicas Utilizadas

```sql
-- Window Functions
DENSE_RANK() OVER (ORDER BY receita_nova DESC)
SUM(mrr) OVER (ORDER BY mes ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

-- CTEs encadeadas
WITH overdue AS (...),
     classified AS (SELECT *, CASE WHEN dias > 90 THEN 'crítico' END AS faixa FROM overdue)
SELECT ... FROM classified

-- Agregações avançadas
MODE() WITHIN GROUP (ORDER BY motivo_cancelamento)
COUNT(*) FILTER (WHERE status = 'cancelled')
EXTRACT(MONTH FROM AGE(cancellation_date, start_date))

-- Joins analíticos
FULL OUTER JOIN  -- combinar MRR novo + cancelado por mês
LEFT JOIN        -- score de risco composto com múltiplas fontes
```

---

## Autor

**Hugo Leonardo**  
Analista de Dados Pleno — SQL · Python · Power BI

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Hugo%20Leonardo-0077B5?style=flat&logo=linkedin)](https://www.linkedin.com/in/hugo-leonardo-data-analyst/)
[![GitHub](https://img.shields.io/badge/GitHub-HugoLeonardoNz-181717?style=flat&logo=github)](https://github.com/HugoLeonardoNz)

---

<div align="center">
<sub>Dataset 100% sintético gerado para fins de portfólio. Nenhuma informação real de clientes foi utilizada.</sub>
</div>

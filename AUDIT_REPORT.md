# Audit Report — SQL Analytics Pack

**Data:** 2026-04-27  
**Auditor:** Hugo Nazário  
**Versão:** v1.0

---

## Resumo do Projeto

10 queries SQL analíticas sobre um ISP fictício (FiberNet) com 300 clientes, 7 tabelas relacionais e dados sintéticos realistas. Demonstra técnicas de nível pleno-sênior: window functions, CTEs recursivas, FILTER clauses, cohort analysis e scoring composto.

Projeto 1 de 3 da série FiberNet Analytics: **SQL Pack** → KPI Dashboard → Churn Predictor.

---

## Tecnologias

- **PostgreSQL 14+** — banco de dados alvo
- **SQL puro** — sem dependências externas
- Schema e seed scripts incluídos para reprodutibilidade total

---

## Estrutura

```
sql-analytics-pack/
├── README.md               — Documentação completa com resultados verificados
├── AUDIT_REPORT.md         — Este arquivo
├── data/
│   ├── schema.sql          — 7 tabelas: clients, contracts, plans, sellers,
│   │                          financial_receivables, tickets, sales
│   └── seed.sql            — 300 clientes + 4.241 boletos + 220 tickets
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
├── analysis/
│   └── findings.md         — Resultados verificados + interpretação de negócio
└── .gitignore
```

---

## Status da Estrutura

| Item | Status |
|---|---|
| README.md real (196 linhas) | ✅ |
| Schema completo (7 tabelas) | ✅ |
| Seed realista (300 clientes) | ✅ |
| 10 queries documentadas | ✅ |
| findings.md com resultados | ✅ |
| .gitignore | ✅ (adicionado 2026-04-27) |
| AUDIT_REPORT.md | ✅ (criado 2026-04-27) |

---

## Pontos Fortes

- Técnicas SQL demonstradas: `DENSE_RANK`, `MODE() WITHIN GROUP`, `FILTER`, `DATE_TRUNC`, `FULL OUTER JOIN`, CTEs encadeadas
- Score de risco composto (query 08): combina dias de atraso, ticket aberto e meses ativo em score 0–100
- Churn por plano (query 02): evidencia correlação inversa entre preço e evasão — Fibra 100MB em 36.7% vs Fibra 1GB em 10.2%
- Inadimplência aging (query 05): buckets 0–30, 31–60, 61–90, 90+ dias com valor em R$ por faixa
- Dados completamente reproduzíveis: schema + seed = ambiente idêntico ao original

---

## Melhorias Aplicadas (2026-04-27)

- Adicionado `.gitignore` Python/SQL padrão
- Criado `AUDIT_REPORT.md` para rastreabilidade

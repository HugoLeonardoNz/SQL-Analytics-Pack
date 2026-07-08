# BigQuery — FiberNet Analytics

Versão BigQuery das queries analíticas do projeto, com documentação de cada diferença de sintaxe em relação ao PostgreSQL.

---

## O que está aqui

| Arquivo | Descrição |
|---------|-----------|
| `08_clientes_em_risco_bq.sql` | Query de risco adaptada para BQ com comentários inline em cada diferença |
| `load_to_bigquery.py` | Carrega os CSVs para BQ usando a SDK oficial com schemas explícitos |
| `setup_bigquery.md` | Passo a passo: conta gratuita → exportar CSVs → carregar → rodar |

---

## Referência rápida: PostgreSQL → BigQuery

| Conceito | PostgreSQL | BigQuery |
|----------|-----------|---------|
| Referência de tabela | `FROM tabela` | `` FROM `projeto.dataset.tabela` `` |
| Data atual | `CURRENT_DATE` | `CURRENT_DATE()` |
| Diferença entre datas | `data1 - data2` (→ INT) | `DATE_DIFF(data1, data2, DAY)` |
| Truncar data | `DATE_TRUNC('month', d)` | `DATE_TRUNC(d, MONTH)` |
| Formatar data | `TO_CHAR(d, 'YYYY-MM')` | `FORMAT_DATE('%Y-%m', d)` |
| Agregação condicional | `COUNT(*) FILTER (WHERE x)` | `COUNTIF(x)` |
| Agregação condicional | `SUM(v) FILTER (WHERE x)` | `SUM(IF(x, v, 0))` |
| Divisão segura | `a / NULLIF(b, 0)` | `SAFE_DIVIDE(a, b)` |
| Casting | `x::NUMERIC` ou `CAST(x AS NUMERIC)` | `CAST(x AS FLOAT64)` |
| Tipo texto | `VARCHAR(n)` | `STRING` |
| Tipo inteiro auto | `SERIAL` | `INT64` (sem autoincrement nativo) |
| Diferença de timestamp | `EXTRACT(EPOCH FROM ts1-ts2)` | `TIMESTAMP_DIFF(ts1, ts2, SECOND)` |

---

## Impacto no portfólio

Demonstra portabilidade analítica: as mesmas análises de negócio rodam tanto em PostgreSQL local quanto em data warehouse cloud — habilidade diretamente aplicável a migrações de stack e ambientes híbridos.

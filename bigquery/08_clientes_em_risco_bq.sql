-- ============================================================
-- 08_clientes_em_risco_bq.sql
-- Clientes em risco de cancelamento — versão BigQuery
--
-- Migrado de PostgreSQL. Cada diferença de sintaxe está
-- documentada com um comentário "-- BQ:" inline.
-- ============================================================

WITH boleto_atraso AS (
    SELECT
        ct.id                                          AS contract_id,
        COUNT(fr.id)                                   AS boletos_em_atraso,
        ROUND(SUM(fr.amount), 2)                       AS valor_em_atraso,

        -- BQ: DATE_DIFF(end, start, DAY) substitui a subtração direta de datas
        --     PostgreSQL: MAX(CURRENT_DATE - fr.due_date)
        MAX(DATE_DIFF(CURRENT_DATE(), fr.due_date, DAY)) AS max_dias_atraso

    FROM `seu-projeto.fibernet_analytics.financial_receivables` fr
    -- BQ: referências a tabelas usam backticks no formato `projeto.dataset.tabela`
    --     PostgreSQL: FROM financial_receivables fr
    JOIN `seu-projeto.fibernet_analytics.contracts` ct
        ON ct.id = fr.contract_id
    WHERE fr.paid_at IS NULL

      -- BQ: CURRENT_DATE() com parênteses; PostgreSQL usa CURRENT_DATE sem parênteses
      AND fr.due_date < CURRENT_DATE()

      AND ct.status = 'active'
    GROUP BY ct.id
),

tickets_abertos AS (
    SELECT
        contract_id,
        COUNT(*)                                       AS tickets_abertos
    FROM `seu-projeto.fibernet_analytics.tickets`
    WHERE status = 'open'
    GROUP BY contract_id
),

risk_score AS (
    SELECT
        ct.id                                          AS contract_id,
        cl.city                                        AS cidade,
        p.name                                         AS plano,

        -- BQ: CAST(x AS FLOAT64) em vez de x::NUMERIC para conversão explícita
        --     Aqui o valor já é NUMERIC/FLOAT64 no schema, sem cast necessário
        ct.amount                                      AS mensalidade,

        COALESCE(ba.boletos_em_atraso, 0)              AS boletos_em_atraso,
        COALESCE(ba.valor_em_atraso,   0)              AS valor_em_atraso,
        COALESCE(ba.max_dias_atraso,   0)              AS max_dias_atraso,
        COALESCE(ta.tickets_abertos,   0)              AS tickets_abertos,

        (COALESCE(ba.boletos_em_atraso, 0)
         + COALESCE(ta.tickets_abertos, 0) * 2)        AS score_risco

    FROM `seu-projeto.fibernet_analytics.contracts` ct
    JOIN `seu-projeto.fibernet_analytics.clients`  cl ON cl.id  = ct.client_id
    JOIN `seu-projeto.fibernet_analytics.plans`    p  ON p.id   = ct.plan_id
    LEFT JOIN boleto_atraso   ba ON ba.contract_id = ct.id
    LEFT JOIN tickets_abertos ta ON ta.contract_id = ct.id
    WHERE ct.status = 'active'
)

SELECT
    contract_id,
    cidade,
    plano,
    mensalidade,
    boletos_em_atraso,
    valor_em_atraso,
    max_dias_atraso,
    tickets_abertos,
    score_risco,
    CASE
        WHEN score_risco >= 5 THEN 'CRÍTICO'
        WHEN score_risco >= 3 THEN 'ALTO'
        WHEN score_risco >= 1 THEN 'MÉDIO'
    END AS nivel_risco

FROM risk_score
WHERE score_risco > 0
ORDER BY score_risco DESC, max_dias_atraso DESC;

-- ============================================================
-- RESUMO DAS DIFERENÇAS PostgreSQL → BigQuery nesta query
-- ============================================================
--
--  PostgreSQL                         BigQuery
--  ─────────────────────────────────  ──────────────────────────────────────
--  FROM tabela                        FROM `projeto.dataset.tabela`
--  CURRENT_DATE (sem parênteses)      CURRENT_DATE() (com parênteses)
--  data1 - data2  (retorna INT)       DATE_DIFF(data1, data2, DAY)
--  x::NUMERIC / CAST(x AS NUMERIC)   CAST(x AS FLOAT64) ou CAST(x AS NUMERIC)
--  VARCHAR(n)  no schema              STRING  no schema
--  SERIAL (autoincrement)             INT64 + Identity ou sequence via script
--  FILTER (WHERE cond)                SUM(IF(cond, val, 0)) / COUNTIF(cond)
--  NULLIF(x, 0) na divisão            SAFE_DIVIDE(a, b)  (sem divisão por zero)
--  EXTRACT(EPOCH FROM interval)       TIMESTAMP_DIFF(ts1, ts2, SECOND)
--  TO_CHAR(date, 'YYYY-MM')           FORMAT_DATE('%Y-%m', date)
--  DATE_TRUNC('month', date)          DATE_TRUNC(date, MONTH)  (ordem invertida)
-- ============================================================

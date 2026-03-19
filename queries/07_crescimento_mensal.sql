-- ============================================================
-- 07_crescimento_mensal.sql
-- Crescimento mensal do MRR (novas vendas vs. cancelamentos)
--
-- Objetivo: monitorar a evolução da receita recorrente mês a
-- mês, decompondo em MRR novo, MRR cancelado e crescimento
-- líquido — base para análise de saúde financeira da operação.
-- ============================================================

WITH monthly_new AS (
    SELECT
        DATE_TRUNC('month', s.sale_date)           AS mes,
        ROUND(SUM(s.amount_after), 2)              AS mrr_novo
    FROM sales s
    WHERE s.sale_type = 'NEW'
    GROUP BY mes
),
monthly_churn AS (
    SELECT
        DATE_TRUNC('month', ct.cancellation_date)  AS mes,
        ROUND(SUM(ct.amount), 2)                   AS mrr_cancelado
    FROM contracts ct
    WHERE ct.status = 'cancelled'
      AND ct.cancellation_date IS NOT NULL
    GROUP BY mes
),
monthly_combined AS (
    SELECT
        COALESCE(n.mes, ch.mes)                    AS mes,
        COALESCE(n.mrr_novo, 0)                    AS mrr_novo,
        COALESCE(ch.mrr_cancelado, 0)              AS mrr_cancelado
    FROM monthly_new n
    FULL OUTER JOIN monthly_churn ch ON ch.mes = n.mes
)
SELECT
    TO_CHAR(mes, 'YYYY-MM')                        AS mes,
    mrr_novo,
    mrr_cancelado,
    mrr_novo - mrr_cancelado                       AS crescimento_liquido,
    ROUND(
        SUM(mrr_novo - mrr_cancelado)
        OVER (ORDER BY mes ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    , 2)                                           AS mrr_acumulado
FROM monthly_combined
ORDER BY mes;

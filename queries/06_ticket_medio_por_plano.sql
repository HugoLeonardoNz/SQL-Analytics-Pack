-- ============================================================
-- 06_ticket_medio_por_plano.sql
-- Ticket médio e receita total por plano
--
-- Objetivo: entender a distribuição de receita entre os planos,
-- medir o LTV médio estimado e identificar quais planos
-- contribuem mais para a receita recorrente total.
--
-- NOTA: A data de referência '2024-10-15' representa o último
-- dia do dataset (seed.sql). Para usar com dados reais,
-- substitua por CURRENT_DATE.
-- ============================================================

WITH plan_revenue AS (
    SELECT
        p.name                                     AS plano,
        p.amount                                   AS valor_plano,
        COUNT(ct.id)                               AS contratos_ativos,
        ROUND(SUM(ct.amount), 2)                   AS mrr_plano,
        -- LTV estimado = ticket médio × tempo médio ativo (meses)
        ROUND(AVG(
            EXTRACT(MONTH FROM AGE(
                COALESCE(ct.cancellation_date, DATE '2024-10-15'),
                ct.start_date
            )) +
            EXTRACT(YEAR FROM AGE(
                COALESCE(ct.cancellation_date, DATE '2024-10-15'),
                ct.start_date
            )) * 12
        ), 1)                                      AS tempo_medio_meses,
        ROUND(
            p.amount * AVG(
                EXTRACT(MONTH FROM AGE(
                    COALESCE(ct.cancellation_date, DATE '2024-10-15'),
                    ct.start_date
                )) +
                EXTRACT(YEAR FROM AGE(
                    COALESCE(ct.cancellation_date, DATE '2024-10-15'),
                    ct.start_date
                )) * 12
            ), 2
        )                                          AS ltv_estimado
    FROM plans p
    JOIN contracts ct ON ct.plan_id = p.id
    WHERE ct.status = 'active'
    GROUP BY p.id, p.name, p.amount
)
SELECT
    plano,
    valor_plano,
    contratos_ativos,
    mrr_plano,
    tempo_medio_meses,
    ltv_estimado,
    ROUND(
        mrr_plano * 100.0 / SUM(mrr_plano) OVER (), 2
    )                                              AS pct_mrr_total
FROM plan_revenue
ORDER BY valor_plano;

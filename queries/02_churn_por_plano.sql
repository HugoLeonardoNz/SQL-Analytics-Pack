-- ============================================================
-- 02_churn_por_plano.sql
-- Taxa de churn por plano de internet
--
-- Objetivo: entender se planos de menor valor têm evasão maior,
-- embasando decisões de precificação e estratégia de retenção.
-- ============================================================

WITH plan_totals AS (
    SELECT
        p.id                                       AS plan_id,
        p.name                                     AS plano,
        p.amount                                   AS valor_mensalidade,
        COUNT(ct.id)                               AS total_contratos,
        COUNT(ct.id) FILTER (WHERE ct.status = 'cancelled') AS cancelados,
        COUNT(ct.id) FILTER (WHERE ct.status = 'active')    AS ativos
    FROM plans p
    LEFT JOIN contracts ct ON ct.plan_id = p.id
    GROUP BY p.id, p.name, p.amount
)
SELECT
    plano,
    valor_mensalidade,
    total_contratos,
    ativos,
    cancelados,
    ROUND(cancelados * 100.0 / NULLIF(total_contratos, 0), 1) AS churn_pct
FROM plan_totals
ORDER BY valor_mensalidade;

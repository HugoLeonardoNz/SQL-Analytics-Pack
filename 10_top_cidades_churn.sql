-- ============================================================
-- 10_top_cidades_churn.sql
-- Top cidades por taxa de churn
--
-- Objetivo: ranquear as cidades com maior proporção de
-- cancelamentos, cruzando com receita perdida, para orientar
-- expansão de rede, qualidade do serviço e esforço de retenção
-- por região.
-- ============================================================

WITH city_summary AS (
    SELECT
        c.city                                         AS cidade,
        COUNT(ct.id)                                   AS total_contratos,
        COUNT(ct.id) FILTER (WHERE ct.status = 'active')    AS ativos,
        COUNT(ct.id) FILTER (WHERE ct.status = 'cancelled') AS cancelados,
        ROUND(SUM(ct.amount)
              FILTER (WHERE ct.status = 'active'), 2)  AS mrr_atual,
        ROUND(SUM(ct.amount)
              FILTER (WHERE ct.status = 'cancelled'), 2) AS receita_perdida,
        ROUND(
            COUNT(ct.id) FILTER (WHERE ct.status = 'cancelled') * 100.0
            / NULLIF(COUNT(ct.id), 0), 1
        )                                              AS churn_pct
    FROM contracts ct
    JOIN clients c ON c.id = ct.client_id
    GROUP BY c.city
)
SELECT
    cidade,
    total_contratos,
    ativos,
    cancelados,
    churn_pct,
    mrr_atual,
    receita_perdida,
    DENSE_RANK() OVER (ORDER BY churn_pct DESC)        AS ranking_churn
FROM city_summary
ORDER BY churn_pct DESC;

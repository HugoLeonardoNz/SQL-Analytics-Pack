-- ============================================================
-- 04_ranking_vendedores.sql
-- Ranking de performance dos vendedores
--
-- Objetivo: comparar vendedores em volume, receita gerada e
-- qualidade da carteira (churn dos contratos que venderam),
-- combinando resultado comercial com retenção da base.
-- ============================================================

WITH seller_stats AS (
    SELECT
        s.id                                                   AS seller_id,
        s.name                                                 AS vendedor,
        COUNT(sl.id) FILTER (WHERE sl.sale_type = 'NEW')       AS novas_vendas,
        COUNT(sl.id) FILTER (WHERE sl.sale_type = 'UPGRADE')   AS upgrades,
        COUNT(sl.id) FILTER (WHERE sl.sale_type = 'DOWNGRADE') AS downgrades,
        ROUND(SUM(sl.amount_after)
              FILTER (WHERE sl.sale_type = 'NEW'), 2)          AS receita_nova,
        COUNT(DISTINCT ct.id) FILTER (
            WHERE ct.status = 'cancelled'
              AND sl.sale_type = 'NEW'
        )                                                      AS vendas_canceladas
    FROM sellers s
    LEFT JOIN sales sl ON sl.seller_id = s.id
    LEFT JOIN contracts ct ON ct.id = sl.contract_id
    GROUP BY s.id, s.name
)
SELECT
    vendedor,
    novas_vendas,
    upgrades,
    downgrades,
    receita_nova,
    vendas_canceladas,
    ROUND(
        vendas_canceladas * 100.0 / NULLIF(novas_vendas, 0), 1
    )                                                          AS churn_pct_carteira,
    DENSE_RANK() OVER (ORDER BY receita_nova DESC)             AS ranking
FROM seller_stats
ORDER BY ranking;

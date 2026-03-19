-- ============================================================
-- 03_cohort_clientes.sql
-- Análise de cohort de retenção por mês de aquisição
--
-- Objetivo: medir qual percentual de clientes captados em cada
-- trimestre permanece ativo — essencial para avaliar qualidade
-- da base e identificar sazonalidade na evasão.
-- ============================================================

WITH cohorts AS (
    SELECT
        DATE_TRUNC('quarter', c.created_at)        AS cohort_quarter,
        COUNT(DISTINCT c.id)                        AS total_clientes,
        COUNT(DISTINCT c.id) FILTER (
            WHERE c.status = 'active'
        )                                           AS ainda_ativos
    FROM clients c
    GROUP BY cohort_quarter
),
ranked AS (
    SELECT
        TO_CHAR(cohort_quarter, 'YYYY "Q"Q')       AS coorte,
        total_clientes,
        ainda_ativos,
        total_clientes - ainda_ativos               AS cancelados,
        ROUND(
            ainda_ativos * 100.0 / NULLIF(total_clientes, 0), 1
        )                                           AS retencao_pct
    FROM cohorts
)
SELECT *
FROM ranked
ORDER BY coorte;

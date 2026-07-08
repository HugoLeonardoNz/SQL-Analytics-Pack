-- ============================================================
-- 03_cohort_clientes.sql
-- Análise de cohort de retenção por trimestre de aquisição
--
-- Objetivo: rastrear qual percentual de clientes captados em
-- cada trimestre permanece ativo (com pagamentos) nos meses
-- t+1, t+3, t+6, t+12 após a entrada — métrica essencial para
-- avaliar qualidade da base e custo de aquisição vs. retenção.
--
-- Lógica: um cliente é "retido" no mês M se possui ao menos
-- um boleto pago cujo competence cai naquele mês.
-- Isso evita contar clientes com contrato ativo mas inadimplentes.
-- ============================================================

WITH cohort_base AS (
    -- Determina o trimestre de entrada de cada cliente
    SELECT
        c.id                                            AS client_id,
        DATE_TRUNC('quarter', c.created_at)             AS cohort_quarter,
        COUNT(DISTINCT c.id) OVER (
            PARTITION BY DATE_TRUNC('quarter', c.created_at)
        )                                               AS total_cohort
    FROM clients c
),

monthly_payers AS (
    -- Identifica em quais meses cada cliente pagou ao menos 1 boleto
    SELECT DISTINCT
        ct.client_id,
        DATE_TRUNC('month', fr.competence)              AS activity_month
    FROM financial_receivables fr
    JOIN contracts ct ON ct.id = fr.contract_id
    WHERE fr.paid_at IS NOT NULL
),

cohort_activity AS (
    -- Cruza base de cohort com atividade mensal e calcula meses desde entrada
    SELECT
        cb.cohort_quarter,
        cb.total_cohort,
        mp.client_id,
        mp.activity_month,
        -- Meses completos desde o início do cohort até o mês de atividade
        (EXTRACT(YEAR FROM mp.activity_month) - EXTRACT(YEAR FROM cb.cohort_quarter)) * 12
        + (EXTRACT(MONTH FROM mp.activity_month) - EXTRACT(MONTH FROM cb.cohort_quarter))
                                                        AS months_since_start
    FROM cohort_base cb
    JOIN monthly_payers mp ON mp.client_id = cb.client_id
    WHERE mp.activity_month >= cb.cohort_quarter
),

cohort_retention AS (
    -- Agrega: para cada cohort × mês_n, conta clientes retidos
    SELECT
        cohort_quarter,
        total_cohort,
        months_since_start,
        COUNT(DISTINCT client_id)                       AS retained
    FROM cohort_activity
    GROUP BY cohort_quarter, total_cohort, months_since_start
)

SELECT
    TO_CHAR(cohort_quarter, 'YYYY "Q"Q')                AS coorte,
    months_since_start                                  AS mes_n,
    total_cohort                                        AS total_clientes,
    retained                                            AS clientes_retidos,
    ROUND(
        retained * 100.0 / NULLIF(total_cohort, 0), 1
    )                                                   AS retencao_pct
FROM cohort_retention
-- Filtrar marcos de tempo relevantes para visualização
WHERE months_since_start IN (0, 1, 3, 6, 9, 12, 18, 24)
ORDER BY cohort_quarter, months_since_start;

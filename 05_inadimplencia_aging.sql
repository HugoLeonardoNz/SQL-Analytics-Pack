-- ============================================================
-- 05_inadimplencia_aging.sql
-- Aging de inadimplência — boletos em atraso por faixa de dias
--
-- Objetivo: estratificar a carteira de inadimplência por tempo
-- de atraso (aging), permitindo que o financeiro priorize
-- cobranças e estime probabilidade de recuperação.
--
-- NOTA: A data de referência '2024-10-15' representa o último
-- dia do dataset (seed.sql). Para usar com dados reais,
-- substitua por CURRENT_DATE.
-- ============================================================

WITH overdue AS (
    SELECT
        fr.id,
        fr.contract_id,
        fr.amount,
        fr.due_date,
        (DATE '2024-10-15' - fr.due_date)          AS days_overdue,
        c.city
    FROM financial_receivables fr
    JOIN contracts ct ON ct.id = fr.contract_id
    JOIN clients c    ON c.id  = ct.client_id
    WHERE fr.paid_at IS NULL
      AND fr.due_date < DATE '2024-10-15'
),
classified AS (
    SELECT
        *,
        CASE
            WHEN days_overdue BETWEEN  1 AND  30 THEN '01 - Até 30 dias'
            WHEN days_overdue BETWEEN 31 AND  60 THEN '02 - 31 a 60 dias'
            WHEN days_overdue BETWEEN 61 AND  90 THEN '03 - 61 a 90 dias'
            WHEN days_overdue > 90               THEN '04 - Acima de 90 dias'
        END AS faixa
    FROM overdue
)
SELECT
    faixa,
    COUNT(*)                                       AS qtd_boletos,
    COUNT(DISTINCT contract_id)                    AS contratos_afetados,
    ROUND(SUM(amount), 2)                          AS valor_em_aberto,
    ROUND(AVG(days_overdue), 0)                    AS media_dias_atraso
FROM classified
WHERE faixa IS NOT NULL
GROUP BY faixa
ORDER BY faixa;

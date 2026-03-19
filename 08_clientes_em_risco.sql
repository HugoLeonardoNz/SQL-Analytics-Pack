-- ============================================================
-- 08_clientes_em_risco.sql
-- Clientes em risco de cancelamento
--
-- Objetivo: cruzar sinais de risco (boleto em atraso + ticket
-- de suporte aberto) para identificar clientes que merecem
-- ação preventiva da equipe de retenção antes do cancelamento.
--
-- NOTA: A data de referência '2024-10-15' representa o último
-- dia do dataset (seed.sql). Para usar com dados reais,
-- substitua por CURRENT_DATE.
-- O LIMIT 30 exibe os contratos de maior score — remova-o
-- para listar todos os contratos em risco.
-- ============================================================

WITH boleto_atraso AS (
    SELECT
        ct.id                                      AS contract_id,
        COUNT(fr.id)                               AS boletos_em_atraso,
        ROUND(SUM(fr.amount), 2)                   AS valor_em_atraso,
        MAX(DATE '2024-10-15' - fr.due_date)       AS max_dias_atraso
    FROM financial_receivables fr
    JOIN contracts ct ON ct.id = fr.contract_id
    WHERE fr.paid_at IS NULL
      AND fr.due_date < DATE '2024-10-15'
      AND ct.status = 'active'
    GROUP BY ct.id
),
tickets_abertos AS (
    SELECT
        contract_id,
        COUNT(*)                                   AS tickets_abertos
    FROM tickets
    WHERE status = 'open'
    GROUP BY contract_id
),
risk_score AS (
    SELECT
        ct.id                                      AS contract_id,
        c.city                                     AS cidade,
        p.name                                     AS plano,
        ct.amount                                  AS mensalidade,
        COALESCE(ba.boletos_em_atraso, 0)          AS boletos_em_atraso,
        COALESCE(ba.valor_em_atraso,   0)          AS valor_em_atraso,
        COALESCE(ba.max_dias_atraso,   0)          AS max_dias_atraso,
        COALESCE(ta.tickets_abertos,   0)          AS tickets_abertos,
        -- Score de risco: 1 pt por boleto em atraso + 2 pts por ticket aberto
        (COALESCE(ba.boletos_em_atraso, 0)
         + COALESCE(ta.tickets_abertos, 0) * 2)   AS score_risco
    FROM contracts ct
    JOIN clients c ON c.id = ct.client_id
    JOIN plans   p ON p.id = ct.plan_id
    LEFT JOIN boleto_atraso   ba ON ba.contract_id = ct.id
    LEFT JOIN tickets_abertos ta ON ta.contract_id = ct.id
    WHERE ct.status = 'active'
)
SELECT
    contrato_id,
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
FROM (
    SELECT
        contract_id AS contrato_id,
        cidade, plano, mensalidade,
        boletos_em_atraso, valor_em_atraso,
        max_dias_atraso, tickets_abertos, score_risco
    FROM risk_score
    WHERE score_risco > 0
) t
ORDER BY score_risco DESC, max_dias_atraso DESC
LIMIT 30;
